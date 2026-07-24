import 'package:flutter/material.dart';

class TestPager extends StatelessWidget {
  const TestPager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧面板
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const LeftPanel(),
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
              child: const RightPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 左侧面板：文件解析与树状图
// ==========================================
class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '文件解析',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 文件上传栏
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F37),
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'txbz_json_UAE_20260723141040.zip',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('浏览'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('解析'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 网络节点标题与下拉框
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '网络节点',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: '组织架构',
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    items: ['组织架构'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),
          // 树状图列表 (简化模拟)
          Expanded(
            child: ListView(
              children: [
                _buildTreeNode('军', 0, Icons.folder, isExpanded: true),
                _buildTreeNode(
                  '第1旅_6A',
                  1,
                  Icons.folder,
                  isExpanded: true,
                  iconColor: Colors.blue,
                ),
                _buildTreeNode(
                  '1旅_1楼侦察营',
                  2,
                  Icons.folder,
                  isExpanded: true,
                  iconColor: Colors.blue,
                ),
                _buildTreeNode(
                  '1楼通信侦察连',
                  3,
                  Icons.folder,
                  isExpanded: true,
                  iconColor: Colors.blue,
                ),
                _buildTreeNode(
                  '1楼通信战斗排',
                  4,
                  Icons.folder,
                  isExpanded: true,
                  iconColor: Colors.blue,
                ),
                _buildTreeNode(
                  '排级指挥车type2',
                  5,
                  Icons.directions_car,
                  showArrow: false,
                ),
                _buildTreeNode(
                  '排级指挥车type3',
                  5,
                  Icons.directions_car,
                  showArrow: false,
                ),
                _buildTreeNode(
                  '排级soldier_徐伟 (手持VHF)',
                  5,
                  Icons.radio,
                  showArrow: false,
                ),
                _buildTreeNode(
                  '排级soldier_吴鹏程 (手持VHF)',
                  5,
                  Icons.radio,
                  showArrow: false,
                ),
                _buildTreeNode('通信战斗班组1', 5, Icons.group, isExpanded: true),
                _buildTreeNode(
                  '班组指挥车type1',
                  6,
                  Icons.directions_car,
                  isExpanded: true,
                  isSelected: true,
                ), // 选中项
                _buildTreeNode(
                  '未来战士1 (指挥官)',
                  7,
                  Icons.person,
                  isExpanded: true,
                ),
                _buildTreeNode(
                  'Commander_柳淳超 (手持VHF)',
                  8,
                  Icons.radio,
                  showArrow: false,
                ),
                _buildTreeNode(
                  '未来战士2 (信号兵)',
                  7,
                  Icons.person,
                  isExpanded: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(
    String title,
    int indent,
    IconData icon, {
    bool showArrow = true,
    bool isExpanded = false,
    bool isSelected = false,
    Color? iconColor,
  }) {
    return Container(
      color: isSelected ? const Color(0xFF004B87) : Colors.transparent,
      padding: EdgeInsets.only(
        left: 8.0 + (indent * 16.0),
        top: 8,
        bottom: 8,
        right: 8,
      ),
      child: Row(
        children: [
          if (showArrow)
            Icon(
              isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
              size: 18,
              color: Colors.white54,
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: iconColor ?? Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 右侧面板：详情与设备列表
// ==========================================
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部标题区
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '班组指挥车type1',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '已上线 3/3',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              // 网卡选择与按钮
              Row(
                children: [
                  const Text(
                    '业务网卡',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2F37),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '以太网 2 - 10.64.0.245',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 24),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('刷新'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('下发'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 进度步骤条
              _buildStepper(),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        // 设备列表
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildExpandableGroup('MMR200', '1', [
                _buildDeviceCard('MMR200', '203066', '192.168.2.2'),
              ]),
              _buildExpandableGroup('CCU', '2', [
                _buildDeviceCard('CCU-Main', '946404', '192.168.6.200'),
                _buildDeviceCard('CCU-Audio', '232938', '192.168.6.104'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem('1', '发现', isActive: true),
        _buildStepLine(),
        _buildStepItem('2', '认证'),
        _buildStepLine(),
        _buildStepItem('3', '传输'),
        _buildStepLine(),
        _buildStepItem('4', '解析'),
        _buildStepLine(),
        _buildStepItem('5', '完成'),
      ],
    );
  }

  Widget _buildStepItem(String number, String label, {bool isActive = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.redAccent : Colors.white38,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.redAccent : Colors.white38,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildExpandableGroup(
    String title,
    String count,
    List<Widget> children,
  ) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent), // 移除ExpansionTile默认边框
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              count,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        children: [
          Container(
            color: const Color(0xFF14161A), // 子项背景色稍暗
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String title, String esn, String ip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.desktop_windows, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // 状态标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFF00D2A6),
                        ), // 青色边框
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: Color(0xFF00D2A6),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '已发现',
                            style: TextStyle(
                              color: Color(0xFF00D2A6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'ESN  $esn',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '当前 IP  $ip',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 60), // 给IP右侧留点空间对齐
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
