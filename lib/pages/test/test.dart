import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_enums.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_models.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_simulator.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/socket_io2_manager.dart';

class TestPager extends StatefulWidget {
  const TestPager({super.key});

  @override
  State<TestPager> createState() => _TestPagerState();
}

class _TestPagerState extends State<TestPager> {
  final SocketIO2Manager _manager = SocketIO2Manager();
  final CpdSimulator _simulator = CpdSimulator.instance;
  StreamSubscription<CpdActiveState>? _stateSub;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  CpdActiveState _currentState = CpdActiveState.idle;
  List<Map<String, dynamic>> _eventLogs = [];
  List<String> _simLogs = [];
  List<DeviceStatus> _devices = [];
  String _selectedFileName = '';
  Uint8List? _fileData;
  final _nodeIdController = TextEditingController(text: 'node_001');
  bool _isInitialized = false;
  bool _simulationMode = true;
  bool _simulatorRunning = false;
  int _simDeviceCount = 2;
  double _progressPercent = 0;

  @override
  void initState() {
    super.initState();
    _initManager();
    if (_simulationMode) {
      _startSimulator();
    }
  }

  Future<void> _initManager() async {
    await _manager.init('0.0.0.0:39002');
    if (!mounted) return;

    _stateSub = _manager.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
      _addLog('state', '状态变更: ${state.name}');
      _updateProgressFromState(state);
    });

    _eventSub = _manager.cpdEventStream.listen((event) {
      _handleCpdEvent(event);
    });

    setState(() => _isInitialized = true);
    _addLog('info', 'CPDS 管理器已就绪 (端口: 39002)');
  }

  Future<void> _startSimulator() async {
    setState(() => _simLogs.clear());
    await _simulator.start(
      deviceCount: _simDeviceCount,
      deviceTypes: [DeviceType.server, DeviceType.iec],
      onLog: (msg) {
        setState(() {
          _simLogs.insert(0, msg);
          if (_simLogs.length > 200) _simLogs.removeLast();
        });
      },
    );
    setState(() => _simulatorRunning = true);
    _addLog('info', '✅ CPDC 模拟器已启动');
  }

  Future<void> _stopSimulator() async {
    await _simulator.stop();
    setState(() => _simulatorRunning = false);
    _addLog('info', '⏹️ CPDC 模拟器已停止');
  }

  void _handleCpdEvent(Map<String, dynamic> event) {
    final type = event['type'] as String;
    switch (type) {
      case 'discover_start':
        _addLog('info', '📡 开始发现设备...');
        break;
      case 'discover_device':
        _addLog(
          'success',
          '  📱 发现: ${event['esnSuffix']} (${event['deviceTypes']})',
        );
        break;
      case 'discover_complete':
        _addLog('info', '  发现完成 (${event['discovered']} 台)');
        break;
      case 'auth_start':
        _addLog('info', '🔐 开始认证...');
        break;
      case 'auth_success':
        _addLog('success', '  ✅ 认证成功: ${event['esnSuffix']}');
        break;
      case 'auth_failed':
        _addLog('error', '  ❌ 认证失败: ${event['errorCode']}');
        break;
      case 'transfer_start':
        _addLog(
          'info',
          '📦 开始传输: ${event['fileName']} (${event['fileSize']} bytes)',
        );
        break;
      case 'transfer_progress':
        setState(() => _progressPercent = event['percent'].toDouble());
        break;
      case 'transfer_first_round_complete':
        _addLog('info', '  📊 首轮传输完成');
        break;
      case 'device_transfer_complete':
        _addLog('success', '  📁 传输完成: ${event['esnSuffix']}');
        break;
      case 'device_failed':
        _addLog('error', '  ❌ 设备失败: ${event['esnSuffix']}');
        break;
      case 'device_parse_complete':
        _addLog(
          event['result'] == 'Result.success' ? 'success' : 'error',
          '  🎯 解析完成: ${event['esnSuffix']} (${event['result']})',
        );
        break;
      case 'device_parse_timeout':
        _addLog('error', '  ⏰ 解析超时: ${event['esnSuffix']}');
        break;
      case 'resuming':
        _addLog('warning', '  🔄 补传: ${event['esn']}');
        break;
      case 'distribution_complete':
        _addLog(
          event['status'] == 'completed' ? 'success' : 'warning',
          '🏁 下发完成: ${event['status']} (${event['successCount']}/${event['totalCount']})',
        );
        break;
      case 'distribution_failed':
        _addLog('error', '  ❌ 下发失败: ${event['errorCode']}');
        break;
      case 'esn_conflict':
        _addLog('error', '  ⚠️ ESN 冲突: ${event['esn']}');
        break;
      default:
        _addLog('debug', '  $type');
    }
    _reloadDevicesFromSession();
  }

  void _reloadDevicesFromSession() {
    final session = _manager.cpdSession;
    if (session == null) return;
    setState(() {
      _devices = List.from(session.devices);
    });
  }

  void _updateProgressFromState(CpdActiveState state) {
    switch (state) {
      case CpdActiveState.idle:
        _progressPercent = 0;
      case CpdActiveState.discovering:
      case CpdActiveState.awaitingDiscoveryConfirmation:
        _progressPercent = 10;
      case CpdActiveState.authenticating:
        _progressPercent = 30;
      case CpdActiveState.transferring:
        _progressPercent = 50;
      case CpdActiveState.waitingParse:
        _progressPercent = 85;
      case CpdActiveState.completed:
      case CpdActiveState.partialSuccess:
      case CpdActiveState.failed:
      case CpdActiveState.drainingAfterFailure:
        _progressPercent = 100;
    }
  }

  void _addLog(String level, String message) {
    setState(() {
      _eventLogs.insert(0, {
        'time': DateTime.now().toString().split('.').first.substring(11),
        'level': level,
        'message': message,
      });
      if (_eventLogs.length > 300) _eventLogs.removeLast();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json', 'bin', 'dat', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes ?? Uint8List(0);

    setState(() {
      _selectedFileName = file.name;
      _fileData = bytes;
    });
    _addLog('info', '📎 已选择: $_selectedFileName (${bytes.length} bytes)');
  }

  Future<void> _startDistribution() async {
    if (_fileData == null) {
      _addLog('error', '请先选择文件');
      return;
    }
    if (_nodeIdController.text.isEmpty) {
      _addLog('error', '请输入节点 ID');
      return;
    }

    setState(() {
      _eventLogs.clear();
      _devices.clear();
      _progressPercent = 0;
    });

    _addLog('info', '🚀 开始下发...');
    await _manager.startDistribution(
      fileData: _fileData!,
      fileName: _selectedFileName,
      nodeId: _nodeIdController.text,
    );
  }

  void _stopDistribution() {
    _manager.stopDistribution();
    _addLog('warning', '⏹️ 已停止下发');
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _eventSub?.cancel();
    _simulator.stop();
    _manager.disconnect();
    _nodeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧面板
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildLeftPanel(),
            ),
          ),
          // 右侧面板
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.only(
                top: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildRightPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 控制区（可滚动，防止平板内容溢出）
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CPDS 配置下发',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isInitialized ? '🟢 就绪' : '🟡 初始化中...',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isInitialized ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 12),

                  // 模拟器配置
                  _buildSimulatorSection(),
                  const SizedBox(height: 16),

                  // 文件选择
                  const Text(
                    '📎 选择配置文件',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2F37),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.insert_drive_file,
                            size: 18,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFileName.isEmpty
                                ? '未选择文件'
                                : _selectedFileName,
                            style: TextStyle(
                              color: _selectedFileName.isEmpty
                                  ? Colors.white54
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_fileData != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${(_fileData!.length / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('浏览'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectedFileName.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFileName = '';
                                    _fileData = null;
                                  });
                                },
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('清除'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 节点 ID
                  const Text(
                    '🏷️ 节点 ID',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2F37),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _nodeIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        hintText: 'node_001',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 控制按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (_currentState == CpdActiveState.idle ||
                                      _currentState ==
                                          CpdActiveState.completed ||
                                      _currentState == CpdActiveState.failed ||
                                      _currentState ==
                                          CpdActiveState.partialSuccess) &&
                                  _fileData != null
                              ? _startDistribution
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('🚀 开始下发'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _currentState != CpdActiveState.idle &&
                                  _currentState != CpdActiveState.completed &&
                                  _currentState != CpdActiveState.failed &&
                                  _currentState != CpdActiveState.partialSuccess
                              ? _stopDistribution
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size(0, 44),
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('⏹️ 停止'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 状态卡片
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _stateColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _stateColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _stateColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '状态',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                _currentState.displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _stateColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_progressPercent.toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _stateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 日志区标题
          const Text(
            '📝 CPDS 事件日志',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Expanded(flex: 4, child: _buildLogList(_eventLogs)),
        ],
      ),
    );
  }

  Widget _buildSimulatorSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF00A3FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🧪 模拟模式',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Switch(
                value: _simulationMode,
                onChanged: (v) {
                  setState(() => _simulationMode = v);
                  if (v && !_simulatorRunning) {
                    _startSimulator();
                  } else if (!v && _simulatorRunning) {
                    _stopSimulator();
                  }
                },
                activeColor: const Color(0xFF00A3FF),
              ),
            ],
          ),
          if (_simulationMode) ...[
            Row(
              children: [
                const Text(
                  '设备数量',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _simDeviceCount,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2A2F37),
                  items: [1, 2, 3, 4].map((n) {
                    return DropdownMenuItem(value: n, child: Text('$n 台'));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _simDeviceCount = v);
                      if (_simulatorRunning) {
                        _stopSimulator().then((_) => _startSimulator());
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _simulatorRunning
                      ? OutlinedButton.icon(
                          onPressed: _stopSimulator,
                          icon: const Icon(
                            Icons.stop,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: const Text(
                            '停止模拟器',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(0, 32),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _startSimulator,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('启动模拟器'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          '暂无事件',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['time'].toString(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _getLogLevelColor(log['level']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    log['level'].toString().toUpperCase(),
                    style: TextStyle(
                      color: _getLogLevelColor(log['level']),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log['message'],
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimLogList() {
    if (_simLogs.isEmpty) {
      return const Center(
        child: Text(
          '模拟器未启动',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _simLogs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              _simLogs[index],
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 进度步骤
          const Text(
            '📊 下发进度',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStepper(),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressPercent / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFF2A2F37),
              valueColor: AlwaysStoppedAnimation(_stateColor),
            ),
          ),
          const SizedBox(height: 16),

          // 设备列表
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '📱 设备列表',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_devices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2F37),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_devices.length} 台',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _devices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) =>
                              _buildDeviceCard(_devices[index]),
                        ),
                ),
              ],
            ),
          ),

          // 模拟器日志
          if (_simulationMode) ...[
            const SizedBox(height: 12),
            const Text(
              '🧪 模拟器日志',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            SizedBox(height: 100, child: _buildSimLogList()),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, size: 40, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            _currentState == CpdActiveState.discovering ? '正在扫描设备...' : '等待设备',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      ('🔍', '发现', CpdActiveState.discovering),
      ('🔐', '认证', CpdActiveState.authenticating),
      ('📦', '传输', CpdActiveState.transferring),
      ('🔧', '解析', CpdActiveState.waitingParse),
      ('🏁', '完成', CpdActiveState.completed),
    ];

    int activeIndex = -1;
    for (int i = steps.length - 1; i >= 0; i--) {
      if (_currentState == steps[i].$3 ||
          (i == steps.length - 1 &&
              (_currentState == CpdActiveState.completed ||
                  _currentState == CpdActiveState.partialSuccess ||
                  _currentState == CpdActiveState.failed))) {
        activeIndex = i;
        break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepItem(
            steps[i].$1,
            steps[i].$2,
            isActive: i == activeIndex,
            isCompleted: i < activeIndex,
          ),
          if (i < steps.length - 1)
            Container(
              width: 24,
              height: 2,
              color: i < activeIndex ? const Color(0xFF00A3FF) : Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
        ],
      ],
    );
  }

  Widget _buildStepItem(
    String icon,
    String label, {
    bool isActive = false,
    bool isCompleted = false,
  }) {
    Color color;
    if (_currentState == CpdActiveState.failed) {
      color = Colors.red;
    } else if (isCompleted) {
      color = Colors.green;
    } else if (isActive) {
      color = const Color(0xFF00A3FF);
    } else {
      color = Colors.white38;
    }

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(icon, style: TextStyle(fontSize: 10)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildDeviceCard(DeviceStatus device) {
    final statusColor = _getDeviceStatusColor(device);
    final statusText = _getDeviceStatusText(device);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14161A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                device.deviceType == DeviceType.server
                    ? Icons.dns
                    : device.deviceType == DeviceType.iec
                    ? Icons.computer
                    : Icons.router,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${device.deviceType.displayName} · ${device.esnSuffix}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      device.esn,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (device.progressPercent > 0 && device.progressPercent < 100) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: device.progressPercent / 100,
                minHeight: 3,
                backgroundColor: const Color(0xFF2A2F37),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
          if (device.errorCode != ErrorCode.unspecified) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ ${device.errorCode.name}',
              style: const TextStyle(color: Colors.orange, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Color get _stateColor {
    switch (_currentState) {
      case CpdActiveState.idle:
        return Colors.grey;
      case CpdActiveState.discovering:
      case CpdActiveState.awaitingDiscoveryConfirmation:
        return Colors.blue;
      case CpdActiveState.authenticating:
        return Colors.purple;
      case CpdActiveState.transferring:
        return Colors.orange;
      case CpdActiveState.waitingParse:
        return Colors.amber;
      case CpdActiveState.completed:
        return Colors.green;
      case CpdActiveState.partialSuccess:
        return Colors.yellow;
      case CpdActiveState.failed:
      case CpdActiveState.drainingAfterFailure:
        return Colors.red;
    }
  }

  Color _getDeviceStatusColor(DeviceStatus device) {
    if (device.result == Result.failed) return Colors.red;
    if (device.state == CpdActiveState.completed) return Colors.green;
    if (device.state == CpdActiveState.failed) return Colors.red;
    if (device.state == CpdActiveState.transferring) return Colors.orange;
    if (device.state == CpdActiveState.waitingParse) return Colors.amber;
    return Colors.blue;
  }

  String _getDeviceStatusText(DeviceStatus device) {
    if (device.result == Result.success &&
        device.state == CpdActiveState.completed)
      return '✅ 完成';
    if (device.result == Result.failed) return '❌ 失败';
    if (device.state == CpdActiveState.transferring) return '📦 传输中';
    if (device.state == CpdActiveState.waitingParse) return '🔧 解析中';
    if (device.state == CpdActiveState.authenticating) return '🔐 认证中';
    if (device.state == CpdActiveState.idle) return '⏳ 就绪';
    return '⋯';
  }

  Color _getLogLevelColor(String level) {
    switch (level) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'debug':
        return Colors.grey;
      case 'state':
        return Colors.purple;
      default:
        return Colors.lightBlue;
    }
  }
}
