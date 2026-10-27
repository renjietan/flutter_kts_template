// ignore_for_file: cpd_lints/hardcoded_dimension
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_factory.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_manager.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_messages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

class KeyLoaderFileDeleteDialog extends StatefulWidget {
  const KeyLoaderFileDeleteDialog({super.key});

  @override
  State<KeyLoaderFileDeleteDialog> createState() =>
      _KeyLoaderFileDeleteDialogState();
}

enum _DeleteStep { connect, ready, list, select }

class _DeleteFileItem {
  _DeleteFileItem(this.name);

  final String name;
  String? status;
  bool deleted = false;
}

class _KeyLoaderFileDeleteDialogState extends State<KeyLoaderFileDeleteDialog> {
  String _tr(String zh, String en, String ar) {
    return CpdsMessages.tr(context, zh, en, ar);
  }

  _DeleteStep _step = _DeleteStep.connect;
  final List<_DeleteFileItem> _files = [];
  final Set<String> _selected = {};

  KeyLoaderUsbBulkManager? _manager;
  _UsbLineReader? _reader;
  StreamSubscription<void>? _disconnectSub;

  bool _deleting = false;
  bool _reconnectRequired = false;
  String _reconnectMessage = '';
  bool _closed = false;
  _DeleteFileItem? _currentFile;
  String? _refreshError;
  bool _refreshLoading = false;
  String _fileTypeFilter = 'all';
  String _versionText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  @override
  void dispose() {
    unawaited(_teardownUsb());
    super.dispose();
  }

  Future<void> _run() async {
    if (_closed) return;
    _resetUi();
    _reconnectRequired = false;
    _deleting = false;
    _currentFile = null;
    _refreshError = null;
    _refreshLoading = false;

    final manager = getKeyLoaderUsbBulkManager();
    _manager = manager;

    setState(() {
      _step = _DeleteStep.connect;
      _files.clear();
      _selected.clear();
    });

    final connected = await manager.connect();
    if (!mounted || _closed) return;
    if (!connected) {
      _showError(
        _tr(
          '注钥枪连接失败',
          'Key loader connection failed',
          'فشل الاتصال بجهاز تحميل المفاتيح',
        ),
      );
      return;
    }

    await manager.drainInput();

    final reader = _UsbLineReader(manager.listenData())..start();
    _reader = reader;
    _disconnectSub = manager.onDisconnected.listen((_) => _onDisconnected());

    if (!mounted) return;
    setState(() => _step = _DeleteStep.ready);
    await _writeUsb(manager, Uint8List.fromList(utf8.encode('LIGHT_GREEN\n')));
    try {
      final line = await reader.nextLine(timeout: const Duration(seconds: 3));
      if (!mounted || _closed) return;
      if (line != 'FILE_OK\n') {
        _showError(_tr('响应超时', 'Response timeout', 'انتهت مهلة الاستجابة'));
        return;
      }
    } on TimeoutException {
      if (!mounted || _closed) return;
      _showError(_tr('响应超时', 'Response timeout', 'انتهت مهلة الاستجابة'));
      return;
    } on StateError {
      return;
    }

    // 获取版本号：GET_VERSION → VERSION:xxxxx；3 秒超时，共 3 次尝试。
    var versionAcquired = false;
    for (var attempt = 0; attempt < 3 && !versionAcquired; attempt++) {
      await _writeUsb(
        manager,
        Uint8List.fromList(utf8.encode('GET_VERSION\n')),
      );
      try {
        final versionLine = await reader.nextLine(
          timeout: const Duration(seconds: 3),
        );
        if (!mounted || _closed) return;
        if (versionLine.startsWith('VERSION:')) {
          final version = versionLine.substring('VERSION:'.length).trim();
          setState(() => _versionText = version);
          versionAcquired = true;
        } else {
          // 收到非 VERSION: 开头码流：直接失败。
          break;
        }
      } on TimeoutException {
        // 超时：继续重试。
      } on StateError {
        return;
      }
    }

    if (!mounted) return;
    if (!versionAcquired) {
      _showError(
        _tr('获取版本失败', 'Failed to get version', 'فشل الحصول على الإصدار'),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _step = _DeleteStep.list);
    await _writeUsb(manager, Uint8List.fromList(utf8.encode('FILE_LIST\n')));

    late final String listLine;
    try {
      listLine = await reader.nextLine(timeout: const Duration(seconds: 3));
    } on TimeoutException {
      if (!mounted || _closed) return;
      _showError(
        _tr(
          '获取文件列表超时',
          'Getting file list timed out',
          'انتهت مهلة الحصول على قائمة الملفات',
        ),
      );
      return;
    } on StateError {
      return;
    }

    if (!mounted || _closed) return;
    final line = listLine;

    setState(() {
      _files.clear();
      _selected.clear();
      if (line == 'NONE\n') {
        _files.clear();
      } else if (line == 'ERR:DIR_READ_FAILED\n') {
        _showError(
          _tr(
            '获取文件列表失败',
            'Failed to get file list',
            'فشل الحصول على قائمة الملفات',
          ),
        );
        return;
      } else {
        final content = line.substring(0, line.length - 1);
        _files.addAll(
          _sortFilesByType(
            content
                .split(',')
                .map((item) => item.trim())
                .where(
                  (item) =>
                      item.isNotEmpty &&
                      p.extension(item).toLowerCase() != '.pad',
                )
                .map(_DeleteFileItem.new)
                .toList(),
          ),
        );
      }
      _step = _DeleteStep.select;
    });
  }

  Future<void> _refreshList() async {
    if (_deleting || _reconnectRequired) return;
    if (!mounted || _closed) return;
    setState(() {
      _refreshLoading = true;
      _refreshError = null;
    });

    final manager = _manager;
    final reader = _reader;
    if (manager == null || reader == null || _closed) {
      await _handleRefreshFatal();
      return;
    }
    if (!(await manager.isConnected())) {
      if (!mounted || _closed) return;
      await _handleRefreshFatal();
      return;
    }
    if (!mounted || _closed) return;

    _clearUiState();
    setState(() {
      _refreshLoading = true;
    });

    try {
      await _writeUsb(manager, Uint8List.fromList(utf8.encode('FILE_LIST\n')));
      final line = await reader.nextLine(timeout: const Duration(seconds: 3));
      if (!mounted || _closed) return;
      if (line == 'NONE\n') {
        setState(() {
          _files.clear();
          _refreshError = null;
        });
        return;
      }
      if (line == 'ERR:DIR_READ_FAILED\n') {
        setState(() {
          _refreshError = _tr(
            '获取文件列表失败',
            'Failed to get file list',
            'فشل الحصول على قائمة الملفات',
          );
        });
        return;
      }
      final content = line.substring(0, line.length - 1);
      setState(() {
        _files
          ..clear()
          ..addAll(
            _sortFilesByType(
              content
                  .split(',')
                  .map((item) => item.trim())
                  .where(
                    (item) =>
                        item.isNotEmpty &&
                        p.extension(item).toLowerCase() != '.pad',
                  )
                  .map(_DeleteFileItem.new)
                  .toList(),
            ),
          );
        _refreshError = null;
      });
    } on TimeoutException {
      if (!mounted || _closed) return;
      await _handleRefreshFatal();
    } on _UsbDisconnected {
      if (!mounted || _closed) return;
      await _handleRefreshFatal();
    } on StateError {
      await _handleRefreshFatal();
    } finally {
      if (mounted && !_closed) {
        setState(() {
          _refreshLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefreshFatal() async {
    await _teardownUsb();
    if (!mounted || _closed) return;
    _resetUi();
    setState(() {
      _reconnectRequired = true;
      _deleting = false;
      _currentFile = null;
      _refreshError = null;
      _refreshLoading = false;
    });
  }

  Future<void> _deleteSelectedFiles() async {
    if (_deleting) return;
    final targets = _files
        .where((file) => _selected.contains(file.name) && !file.deleted)
        .toList();
    if (targets.isEmpty) return;

    final manager = _manager;
    if (manager == null || !(await manager.isConnected())) {
      if (!mounted || _closed) return;
      setState(() {
        for (final file in targets) {
          file.status = _tr(
            '注钥枪断开连接',
            'Key loader disconnected',
            'تم فصل جهاز تحميل المفاتيح',
          );
        }
      });
      return;
    }

    if (!mounted || _closed) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var closed = false;
        return AlertDialog(
          backgroundColor: const Color(0xFF20262D),
          titlePadding: EdgeInsets.zero,
          title: Text(
            _tr('删除', 'Delete', 'حذف'),
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          content: Text(
            _tr(
              '删除后将不可恢复，确认删除吗？？',
              'Deleted files cannot be recovered. Confirm deletion?',
              'لا يمكن استعادة الملفات المحذوفة. هل تريد تأكيد الحذف؟',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                _tr('取消', 'Cancel', 'إلغاء'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(_tr('确认', 'Confirm', 'تأكيد')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted || _closed) return;

    _deleting = true;
    setState(() {});

    try {
      for (final file in targets) {
        if (_reconnectRequired || _closed) break;
        _currentFile = file;
        setState(() {
          file.status = _tr('删除中', 'Deleting', 'جارٍ الحذف');
        });

        final result = await _deleteOne(file);
        if (!mounted || _closed) return;
        GlobalLogger.logInfo(
          'KEY_LOADER_FILE_DELETE_RESULT file=${file.name} result=${result.name}',
        );

        if (result == _DeleteResult.timeout) {
          setState(() {
            file.status = _tr(
              '指令发送超时',
              'Command send timeout',
              'انتهت مهلة إرسال الأمر',
            );
          });
          await _handleActiveFailure();
          return;
        }
        if (result == _DeleteResult.disconnected) {
          // _onDisconnected 已设置 UI，不重复清理。
          return;
        }
        if (result == _DeleteResult.ok) {
          setState(() {
            file.deleted = true;
            file.status = _tr('已删除', 'Deleted', 'تم الحذف');
            _selected.remove(file.name);
          });
          continue;
        }
        if (result == _DeleteResult.notFound) {
          setState(() {
            file.status = _tr('文件不存在', 'File not found', 'الملف غير موجود');
          });
          continue;
        }
        if (result == _DeleteResult.deleteFailed) {
          setState(() {
            file.status = _tr('删除失败', 'Delete failed', 'فشل الحذف');
          });
          continue;
        }
        setState(() {
          file.status = _tr('删除失败', 'Delete failed', 'فشل الحذف');
        });
      }

      if (_reconnectRequired || _closed) return;
      await _handleAllCompleted();
    } finally {
      if (mounted && _deleting) {
        setState(() {
          _deleting = false;
          _currentFile = null;
        });
      }
    }
  }

  Future<_DeleteResult> _deleteOne(_DeleteFileItem file) async {
    final manager = _manager;
    final reader = _reader;
    if (manager == null || reader == null) return _DeleteResult.disconnected;

    try {
      await _writeUsb(
        manager,
        Uint8List.fromList(utf8.encode('FILE_DELETE\n')),
      );
      final readyLine = await reader.nextLine(
        timeout: const Duration(seconds: 3),
      );
      GlobalLogger.logInfo(
        'KEY_LOADER_FILE_DELETE_READY file=${file.name} line=${readyLine.replaceAll('\n', '\\n')}',
      );
      if (readyLine != 'READY\n') return _DeleteResult.deleteFailed;

      final nameBytes = utf8.encode(file.name);
      await _writeUsb(manager, _u32le(nameBytes.length));
      await _writeUsb(manager, Uint8List.fromList(nameBytes));

      final line = await reader.nextLine(timeout: const Duration(seconds: 3));
      GlobalLogger.logInfo(
        'KEY_LOADER_FILE_DELETE_FINAL file=${file.name} line=${line.replaceAll('\n', '\\n')}',
      );
      if (line == 'FILE_OK\n') return _DeleteResult.ok;
      if (line == 'ERR:FILE_NOT_FOUND\n') return _DeleteResult.notFound;
      if (line == 'ERR:DELETE_FAILED\n') return _DeleteResult.deleteFailed;
      return _DeleteResult.deleteFailed;
    } on TimeoutException {
      return _DeleteResult.timeout;
    } on _UsbDisconnected {
      return _DeleteResult.disconnected;
    } on StateError {
      return _DeleteResult.disconnected;
    } catch (e) {
      GlobalLogger.logError('KEY_LOADER_FILE_DELETE_ONE_ERROR $e');
      return _DeleteResult.timeout;
    }
  }

  Future<void> _handleActiveFailure() async {
    await _teardownUsb();
    if (!mounted || _closed) return;
    _resetUi();
    setState(() {
      _reconnectRequired = true;
      _deleting = false;
      _currentFile = null;
    });
  }

  Future<void> _handleAllCompleted() async {
    _clearUiState();
    setState(() {
      _reconnectRequired = false;
      _deleting = false;
      _currentFile = null;
    });
    await _refreshList();
  }

  void _onDisconnected() {
    if (!mounted || _closed) return;
    final disconnectedText = _tr(
      '注钥枪断开连接',
      'Key loader disconnected',
      'تم فصل جهاز تحميل المفاتيح',
    );
    if (_deleting && _currentFile != null) {
      _currentFile!.status = disconnectedText;
    }
    _reader?.abort(const _UsbDisconnected());
    setState(() {
      _reconnectRequired = true;
      _reconnectMessage = disconnectedText;
      _deleting = false;
      _currentFile = null;
    });
    unawaited(_resetUsbAfterPassiveDisconnect());
  }

  Future<void> _resetUsbAfterPassiveDisconnect() async {
    await _disconnectSub?.cancel();
    _disconnectSub = null;
    _reader?.stop();
    _reader = null;
    _manager = null;
  }

  Future<void> _reconnect() async {
    if (_deleting || _closed) return;
    await _teardownUsb();
    if (!mounted || _closed) return;
    _resetUi();
    await _run();
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    await _teardownUsb();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _teardownUsb() async {
    await _disconnectSub?.cancel();
    _disconnectSub = null;
    _reader?.stop();
    _reader = null;
    final manager = _manager;
    _manager = null;
    if (manager != null) {
      try {
        if (await manager.isConnected()) {
          await manager.disconnect();
        }
      } catch (e) {
        GlobalLogger.logWarn('KEY_LOADER_FILE_DELETE_DISCONNECT_ERROR $e');
      }
    }
  }

  void _resetUi() {
    _files.clear();
    _selected.clear();
    _currentFile = null;
    _fileTypeFilter = 'all';
  }

  void _clearUiState() {
    _selected.clear();
    _currentFile = null;
    for (final file in _files) {
      file.status = null;
      file.deleted = false;
    }
  }

  String _fileTypeOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.cpdata')) return 'cpdata';
    if (lower.endsWith('.pad')) return 'pad';
    if (lower.endsWith('.key')) return 'key';
    return 'unknown';
  }

  List<_DeleteFileItem> _sortFilesByType(List<_DeleteFileItem> files) {
    final groups = <String, List<_DeleteFileItem>>{
      'cpdata': [],
      'pad': [],
      'key': [],
      'unknown': [],
    };
    for (final file in files) {
      groups[_fileTypeOf(file.name)]!.add(file);
    }
    return [
      ...groups['cpdata']!,
      ...groups['pad']!,
      ...groups['key']!,
      ...groups['unknown']!,
    ];
  }

  List<_DeleteFileItem> get _visibleFiles {
    if (_fileTypeFilter == 'all') return _files;
    return _files
        .where((file) => _fileTypeOf(file.name) == _fileTypeFilter)
        .toList();
  }

  void _showError(String message) {
    if (!mounted || _closed) return;
    setState(() {
      _currentFile = null;
      _reconnectRequired = true;
      _reconnectMessage = message;
      _step = _DeleteStep.select;
      _files.clear();
      _selected.clear();
    });
    GlobalLogger.logError('KEY_LOADER_FILE_DELETE_ERROR $message');
  }

  bool get _allSelected {
    final selectable = _visibleFiles.where((file) => !file.deleted).toList();
    return selectable.isNotEmpty &&
        selectable.every((file) => _selected.contains(file.name));
  }

  bool get _someSelected =>
      _selected.any((name) => _visibleFiles.any((file) => file.name == name));

  void _toggleAll(bool value) {
    setState(() {
      for (final file in _files) {
        if (file.deleted) continue;
        if (_fileTypeFilter != 'all' &&
            _fileTypeOf(file.name) != _fileTypeFilter) {
          continue;
        }
        if (value) {
          _selected.add(file.name);
        } else {
          _selected.remove(file.name);
        }
      }
    });
  }

  void _toggleFile(_DeleteFileItem file, bool value) {
    if (file.deleted) return;
    setState(() {
      if (value) {
        _selected.add(file.name);
      } else {
        _selected.remove(file.name);
      }
    });
  }

  // final _scrollController = ScrollController(); // ★ 必须持有 controller

  @override
  Widget build(BuildContext context) {
    final showClose = _step == _DeleteStep.select && !_deleting;
    final showDelete =
        _step == _DeleteStep.select && !_deleting && !_reconnectRequired;
    final showReconnect = _reconnectRequired;
    final showRefresh =
        _step == _DeleteStep.select && !_deleting && !_reconnectRequired;

    final title = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _tr(
            '从注钥枪中删除文件',
            'Delete files from key loader',
            'حذف الملفات من جهاز تحميل المفاتيح',
          ),
          style: TextStyle(color: Colors.white, fontSize: 15.sp),
        ),
        if (_versionText.isNotEmpty)
          Text(
            '${_tr('注钥枪版本号：', 'Key loader version: ', 'رقم إصدار جهاز تحميل المفاتيح: ')}$_versionText',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
              fontWeight: FontWeight.normal,
            ),
          ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((defaultTargetPlatform == TargetPlatform.android &&
                MediaQuery.sizeOf(context).shortestSide >= 500) ||
            defaultTargetPlatform == TargetPlatform.windows)
          _DeleteStepStrip(
            labels: _stepLabels(),
            statuses: _stepStatuses(),
            activeIndex: _step.index,
          ),
        if (showRefresh)
          Row(
            children: [
              _buildFileTypeFilter(),
              const Spacer(),
              if (_refreshError != null) ...[
                Text(
                  _refreshError!,
                  style: TextStyle(color: Color(0xFFF15B64), fontSize: 12.sp),
                ),
                SizedBox(width: 8.w),
              ],
              OutlinedButton.icon(
                onPressed: _refreshLoading ? null : _refreshList,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  minimumSize: Size(0, 36.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                icon: _refreshLoading
                    ? SizedBox(
                        width: 13.w,
                        height: 13.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00A2E9),
                        ),
                      )
                    : Icon(Icons.refresh, size: 16.sp),
                label: Text(
                  _tr('刷新文件列表', 'Refresh file list', 'تحديث قائمة الملفات'),
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
            ],
          ),
        SizedBox(height: 4.h),
        Expanded(
          child: _reconnectRequired
              ? Center(
                  child: Text(
                    _reconnectMessage.isEmpty
                        ? _tr(
                            '注钥枪断开连接',
                            'Key loader disconnected',
                            'تم فصل جهاز تحميل المفاتيح',
                          )
                        : _reconnectMessage,
                    style: TextStyle(color: Color(0xFFF15B64), fontSize: 13.sp),
                  ),
                )
              : _step == _DeleteStep.select
              ? _buildFileTable()
              : _buildProgress(_stepLabel(_step)),
        ),
      ],
    );

    final actions = <Widget>[
      if (showClose)
        TextButton(onPressed: _close, child: Text(_tr('关闭', 'Close', 'إغلاق'))),
      if (showReconnect)
        BaseButton(
          label: _tr('重新连接', 'Reconnect', 'إعادة الاتصال'),
          height: 36.h,
          onPressed: _reconnect,
        ),
      if (showDelete)
        BaseButton(
          label: _tr('删除', 'Delete', 'حذف'),
          height: 36.h,
          onPressed: _selected.isEmpty ? null : _deleteSelectedFiles,
          colors: [
            Color(0xFFF56C6C),
            Color(0xFFF56C6C),
            Color(0xFFF56C6C),
            Color(0xFFF56C6C),
          ],
        ),
    ];

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: title,
        content: SizedBox(width: 720.w, height: 460.h, child: body),
        actions: actions,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF20262D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF20262D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: title,
      ),
      body: SafeArea(
        child: Padding(padding: EdgeInsets.all(12.w), child: body),
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ),
    );
  }

  Widget _buildFileTypeFilter() {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2026),
        border: Border.all(color: const Color(0xFF353A41)),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _fileTypeFilter,
          isDense: true,
          dropdownColor: const Color(0xFF282D33),
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _fileTypeFilter = value;
              _selected.clear();
            });
          },
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(
                _tr('全部类型', 'All types', 'كل الأنواع'),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
            DropdownMenuItem(
              value: 'cpdata',
              child: Text(
                _tr(
                  '通信参数包',
                  'Communication parameter package',
                  'حزمة معلمات الاتصال',
                ),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
            // DropdownMenuItem(
            //   value: 'pad',
            //   child: Text(
            //     _tr(
            //       '通信参数包（单兵）',
            //       'Communication parameter package (individual)',
            //       'حزمة معلمات الاتصال (فردي)',
            //     ),
            //     style: TextStyle(fontSize: 13.sp),
            //   ),
            // ),
            DropdownMenuItem(
              value: 'key',
              child: Text(
                _tr('密钥包', 'Key package', 'حزمة المفاتيح'),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
            DropdownMenuItem(
              value: 'unknown',
              child: Text(
                _tr('未知类型', 'Unknown type', 'نوع غير معروف'),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fileTypeLabel(String name) {
    return switch (_fileTypeOf(name)) {
      'cpdata' => _tr(
        '通信参数包',
        'Communication parameter package',
        'حزمة معلمات الاتصال',
      ),
      'pad' => _tr(
        '通信参数包（单兵）',
        'Communication parameter package (individual)',
        'حزمة معلمات الاتصال (فردي)',
      ),
      'key' => _tr('密钥包', 'Key package', 'حزمة المفاتيح'),
      _ => _tr('未知类型', 'Unknown type', 'نوع غير معروف'),
    };
  }

  Color _fileTypeColor(String name) {
    return switch (_fileTypeOf(name)) {
      'cpdata' => const Color(0xFF00C6FF),
      'pad' => const Color(0xFFFFB84D),
      'key' => const Color(0xFFB78CFF),
      _ => const Color(0xFF9AA5B1),
    };
  }

  Widget _buildFileTable() {
    if (_visibleFiles.isEmpty) {
      return Center(
        child: Text(
          _tr('暂无文件', 'No files', 'لا توجد ملفات'),
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    final headerColor = Colors.white54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 30.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: const BoxDecoration(color: Color(0xFF14191F)),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Checkbox(
                  value: _allSelected,
                  tristate: _someSelected && !_allSelected,
                  onChanged: (value) => _toggleAll(value ?? false),
                  activeColor: const Color(0xFF00A2E9),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _tr('文件名称', 'File name', 'اسم الملف'),
                  style: TextStyle(color: headerColor, fontSize: 12.sp),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _tr('文件类型', 'File type', 'نوع الملف'),
                  style: TextStyle(color: headerColor, fontSize: 12.sp),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _tr('状态', 'Status', 'الحالة'),
                  style: TextStyle(color: headerColor, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFF353A41)),
        Expanded(
          child: ListView(
            children: [
              for (final file in _visibleFiles)
                Container(
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Checkbox(
                          value: _selected.contains(file.name),
                          onChanged: file.deleted
                              ? null
                              : (value) => _toggleFile(file, value ?? false),
                          activeColor: const Color(0xFF00A2E9),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          file.name,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _fileTypeLabel(file.name),
                          style: TextStyle(
                            color: _fileTypeColor(file.name),
                            fontSize: 13.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          file.status ?? '',
                          style: TextStyle(
                            color: _statusColor(file.status),
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18.w,
            height: 18.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00A2E9),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(color: Colors.white54, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.white54;
    if (status == _tr('已删除', 'Deleted', 'تم الحذف')) {
      return const Color(0xFF1B8252);
    }
    if (status == _tr('删除中', 'Deleting', 'جارٍ الحذف')) {
      return const Color(0xFF00A2E9);
    }
    return const Color(0xFFF15B64);
  }

  String _stepLabel(_DeleteStep step) {
    return switch (step) {
      _DeleteStep.connect => _tr(
        '连接注钥枪',
        'Connect key loader',
        'الاتصال بجهاز تحميل المفاتيح',
      ),
      _DeleteStep.ready => _tr('就绪', 'Ready', 'جاهز'),
      _DeleteStep.list => _tr(
        '获取文件列表',
        'Get file list',
        'الحصول على قائمة الملفات',
      ),
      _DeleteStep.select => _tr('文件选择', 'File selection', 'اختيار الملف'),
    };
  }

  List<String> _stepLabels() {
    return [
      _tr('连接', 'Connect', 'اتصال'),
      _tr('就绪', 'Ready', 'جاهز'),
      _tr('列表', 'List', 'قائمة'),
      _tr('选择', 'Select', 'اختيار'),
    ];
  }

  List<_DeleteStepStatus> _stepStatuses() {
    final current = _step.index;
    return [
      if (current == _DeleteStep.connect.index)
        _DeleteStepStatus.active
      else if (current > _DeleteStep.connect.index)
        _DeleteStepStatus.passed
      else
        _DeleteStepStatus.pending,
      if (current == _DeleteStep.ready.index)
        _DeleteStepStatus.active
      else if (current > _DeleteStep.ready.index)
        _DeleteStepStatus.passed
      else
        _DeleteStepStatus.pending,
      if (current == _DeleteStep.list.index)
        _DeleteStepStatus.active
      else if (current > _DeleteStep.list.index)
        _DeleteStepStatus.passed
      else
        _DeleteStepStatus.pending,
      if (current == _DeleteStep.select.index)
        _DeleteStepStatus.active
      else
        _DeleteStepStatus.pending,
    ];
  }
}

enum _DeleteStepStatus { pending, active, passed, error, done }

class _DeleteStepStrip extends StatelessWidget {
  const _DeleteStepStrip({
    required this.labels,
    required this.statuses,
    required this.activeIndex,
  });

  final List<String> labels;
  final List<_DeleteStepStatus> statuses;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14191F),
        border: Border.all(color: const Color(0xFF353A41)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            _DeleteStepNode(
              index: index,
              label: labels[index],
              status: statuses[index],
            ),
            if (index != labels.length - 1)
              _DeleteStepLine(passed: index < activeIndex),
          ],
        ],
      ),
    );
  }
}

class _DeleteStepNode extends StatelessWidget {
  const _DeleteStepNode({
    required this.index,
    required this.label,
    required this.status,
  });

  final int index;
  final String label;
  final _DeleteStepStatus status;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color fillColor;
    final Color numberColor;
    final Color textColor;
    switch (status) {
      case _DeleteStepStatus.done:
        borderColor = const Color(0xFF1B8252);
        fillColor = const Color(0xFF1B8252);
        numberColor = Colors.white;
        textColor = Colors.white;
      case _DeleteStepStatus.active:
        borderColor = const Color(0xFF00A2E9);
        fillColor = const Color(0xFF004098);
        numberColor = Colors.white;
        textColor = Colors.white;
      case _DeleteStepStatus.passed:
        borderColor = const Color(0xFF00A2E9);
        fillColor = Colors.transparent;
        numberColor = const Color(0xFF0CB5FF);
        textColor = const Color(0xFF0CB5FF);
      case _DeleteStepStatus.error:
        borderColor = const Color(0xFFF15B64);
        fillColor = Colors.transparent;
        numberColor = const Color(0xFFF15B64);
        textColor = const Color(0xFFF15B64);
      case _DeleteStepStatus.pending:
        borderColor = const Color(0xFF42474E);
        fillColor = Colors.transparent;
        numberColor = const Color(0xFF8A94A6);
        textColor = const Color(0xFF8A94A6);
    }

    return Expanded(
      flex: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18.w,
            height: 18.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 10.sp, color: numberColor),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.sp, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteStepLine extends StatelessWidget {
  const _DeleteStepLine({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        height: 2,
        color: passed ? const Color(0xFF0CB5FF) : const Color(0xFF42474E),
      ),
    );
  }
}

enum _DeleteResult { ok, notFound, deleteFailed, timeout, disconnected }

class _UsbDisconnected implements Exception {
  const _UsbDisconnected();
}

class _UsbLineReader {
  _UsbLineReader(this._dataStream);

  final Stream<Uint8List> _dataStream;
  final List<int> _buffer = [];
  final List<String> _pending = [];
  final List<_PendingLine> _waiters = [];
  StreamSubscription<Uint8List>? _sub;

  void start() {
    _sub = _dataStream.listen(_onData);
  }

  void _onData(Uint8List data) {
    if (data.isEmpty) return;
    GlobalLogger.logInfo('USB_RECV ${_formatUsbPayload(data)}');
    _buffer.addAll(data);
    while (true) {
      final index = _buffer.indexOf(0x0A);
      if (index < 0) break;
      final lineBytes = _buffer.sublist(0, index);
      _buffer.removeRange(0, index + 1);
      var content = utf8.decode(lineBytes, allowMalformed: true);
      if (content.endsWith('\r')) {
        content = content.substring(0, content.length - 1);
      }
      if (content.trim().isEmpty) continue;
      GlobalLogger.logInfo(
        'USB_LINE ${content.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}',
      );
      _deliver('$content\n');
    }
  }

  void _deliver(String line) {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).deliver(line);
    } else {
      _pending.add(line);
    }
  }

  Future<String> nextLine({Duration timeout = const Duration(seconds: 3)}) {
    if (_pending.isNotEmpty) {
      return Future.value(_pending.removeAt(0));
    }
    final pending = _PendingLine();
    _waiters.add(pending);
    pending.start(timeout, onTimeout: () => _waiters.remove(pending));
    return pending.completer.future;
  }

  void abort(Object error) {
    for (final waiter in _waiters) {
      waiter.fail(error);
    }
    _waiters.clear();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _buffer.clear();
    _pending.clear();
    for (final waiter in _waiters) {
      waiter.fail(const _UsbDisconnected());
    }
    _waiters.clear();
  }
}

class _PendingLine {
  final Completer<String> completer = Completer<String>();
  Timer? _timer;

  void start(Duration timeout, {required VoidCallback onTimeout}) {
    _timer = Timer(timeout, () {
      _timer = null;
      onTimeout();
      fail(TimeoutException('reply timeout'));
    });
  }

  void deliver(String line) {
    _timer?.cancel();
    _timer = null;
    if (!completer.isCompleted) completer.complete(line);
  }

  void fail(Object error) {
    _timer?.cancel();
    _timer = null;
    if (!completer.isCompleted) completer.completeError(error);
  }
}

Uint8List _u32le(int value) {
  final data = ByteData(4);
  data.setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Future<void> _writeUsb(KeyLoaderUsbBulkManager manager, Uint8List data) async {
  GlobalLogger.logInfo('USB_SEND ${_formatUsbPayload(data)}');
  final written = await manager.write(data);
  GlobalLogger.logInfo('USB_WRITE_RESULT $written');
}

String _formatUsbPayload(Uint8List data) {
  final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  final parts = <String>['len=${data.length}', 'hex=[$hex]'];

  final text = _decodePrintableText(data);
  if (text != null) {
    parts.add('text="${text.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}"');
  }
  if (data.length == 4) {
    parts.add('u32le=${_toU32Le(data)}');
  }
  return parts.join(' ');
}

String? _decodePrintableText(Uint8List data) {
  try {
    final text = utf8.decode(data, allowMalformed: false);
    if (text.isEmpty) return null;
    for (final unit in text.codeUnits) {
      final printable = unit >= 0x20 && unit <= 0x7E;
      final whitespace = unit == 0x0A || unit == 0x0D || unit == 0x09;
      if (!printable && !whitespace) return null;
    }
    return text;
  } catch (_) {
    return null;
  }
}

int _toU32Le(Uint8List data) {
  return ByteData.sublistView(data).getUint32(0, Endian.little);
}
