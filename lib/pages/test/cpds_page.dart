import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/FileUploads/fileUploads.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.item.dart';
import 'package:flutter_kts_template/components/TextField/simple.filter.search.textField.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.model.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.model.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.tools.dart';
import 'package:flutter_kts_template/pages/test/cpds.message.mixin.dart';
import 'package:flutter_kts_template/pages/test/cpds_right_panel.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/utils/devicePermission/requestPermissions.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/networkUtils/network.utils.dart';
import 'package:path/path.dart' as p;
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

class CpdsPage extends StatefulWidget {
  const CpdsPage({super.key});

  @override
  State<CpdsPage> createState() => _CpdsPageState();
}

class _CpdsPageState extends State<CpdsPage> with CpdsMessageMixin {
  final MasterTreeConfig mtc = MasterTreeConfig(
    searchValue: '',
    visible: false,
    select: MasterTreeSelectConfig(id: '', type: -1, title: ''),
    searchTextFieldController: TextEditingController(),
    data: TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(id: '1', title: ''),
      children: [],
      parent: null,
    ),
  );

  Map<String, dynamic> allData = {};
  @override
  String dataPath = '';
  String _selectedNodeTitle = 'A车';
  String? _sourceArchivePath;
  final DetailTreeConfig dtc = DetailTreeConfig(
    data: [],
    visible: false,
    treeVisible: false,
    dialog: DetailTreeDialogConfig(
      deviceType: TextEditingController(),
      deviceIP: TextEditingController(),
    ),
    selectRows: {},
    activeStep: 1,
    selectWifi: -1,
    socketIOManager: null,
  );
  List<SimpleDarkDropdownItem<int>> networkOptions = [];
  List<SimpleNumberStepModel> steps = [];
  List<String> foundDevice = [];
  @override
  List<CpdsDeviceGroup> deviceGroups = [];

  @override
  String get currentNodeId => mtc.select.id;

  @override
  String? get sourceArchivePath => _sourceArchivePath;

  @override
  void onDeviceGroupsChanged(List<CpdsDeviceGroup> groups) {
    setState(() {
      deviceGroups = groups;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLeftTree(null);
    });
  }

  @override
  void dispose() {
    mtc.searchTextFieldController.dispose();
    dtc.dialog.deviceType.dispose();
    dtc.dialog.deviceIP.dispose();
    super.dispose();
  }

  void _resetMasterTree() {
    setState(() {
      mtc.searchValue = '';
      mtc.visible = false;
      mtc.select = MasterTreeSelectConfig(id: '', type: -1, title: '');
      mtc.searchTextFieldController.text = '';
      foundDevice = [];
      _selectedNodeTitle = '';
      mtc.data = TreeType<SimpleTreeNode>(
        data: SimpleTreeNode(id: '1', title: ''),
        children: [],
        parent: null,
      );
      dtc.data = [];
      dtc.visible = false;
      dtc.treeVisible = false;
      dtc.selectRows.clear();
      dtc.activeStep = 1;
      dtc.selectWifi = -1;
      deviceGroups = [];
    });
  }

  Future<void> _initLeftTree(String? filePath) async {
    final t = Translations.of(context);
    _sourceArchivePath = filePath;
    setState(() {
      mtc.visible = false;
    });

    final hasPermission = await RequestPermission.requestStoragePermission();
    if (!mounted) {
      return;
    }
    if (!hasPermission) {
      SimplePopup.warn(t.permission.cancel);
      return;
    }

    await _initMasterTree(filePath);
  }

  Future<void> _initMasterTree(String? filePath) async {
    final (data, path) = await readAllDataFiles(filePath);
    if (!mounted) {
      return;
    }

    setState(() {
      allData = data;
      dataPath = path;
    });

    if (allData.isEmpty) {
      setState(() {
        mtc.visible = true;
      });
      return;
    }

    final contacts = allData['0_contacts'] ?? <String, dynamic>{};
    for (final key in contacts.keys) {
      final contact = contacts[key];
      final unitTree = contact is Map<String, dynamic>
          ? contact['UnitTree'] ?? <String, dynamic>{}
          : <String, dynamic>{};
      if (unitTree.isEmpty) {
        continue;
      }

      final transformed = transformUnitTree(unitTree, fullData: allData);
      final (tree, _) = buildTree(transformed, activeSelection: true);

      setState(() {
        mtc.data = tree;
        mtc.visible = true;
      });
    }
  }

  Future<void> _handleNodeChanged(TreeType<SimpleTreeNode> node) async {
    if (!node.isLeaf) {
      return;
    }

    _resetDetailTree();
    await _initNetworkInterfaceOptions();
    _initSteps();

    setState(() {
      mtc.select = MasterTreeSelectConfig(
        id: '${node.data.id}',
        type: node.data.type ?? -1,
        title: node.data.title.toString(),
      );
      _selectedNodeTitle = node.data.title.toString();
      foundDevice = ['0'];
    });

    _initDetailTree();
  }

  void _resetDetailTree() {
    setState(() {
      dtc.data = [];
      dtc.visible = false;
      dtc.treeVisible = false;
      dtc.selectRows.clear();
      dtc.activeStep = 1;
      dtc.selectWifi = -1;
      deviceGroups = [];
    });
  }

  void _initSteps() {
    final t = Translations.of(context);
    setState(() {
      steps = [
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.discovery,
          isActive: true,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.authentication,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.transfer,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.parse,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.finish,
          isActive: false,
        ),
      ];
    });
  }

  Future<void> _initNetworkInterfaceOptions() async {
    final interfaces = await NetworkUtil.getIPv4LANInterfaces();
    if (!mounted) {
      return;
    }
    setState(() {
      networkOptions = List.generate(
        interfaces.length,
        (index) => SimpleDarkDropdownItem<int>(
          value: index,
          label: '${interfaces[index].interfaceName}-${interfaces[index].ip}',
        ),
      );
    });
  }

  void _initDetailTree() {
    setState(() {
      dtc.visible = false;
      dtc.data = [];
    });

    final netNodes =
        allData['4_net_node']?[mtc.select.id] ?? <String, dynamic>{};
    final systemConfig = netNodes['SystemConfiguration'] ?? <String, dynamic>{};
    final members = systemConfig['LANMember'] ?? <String, dynamic>{};
    final primaries = systemConfig['LANPrimary'] ?? <String, dynamic>{};
    final radios = systemConfig['Radio'] ?? <String, dynamic>{};

    final ccus = <String>[
      ...((members['CCU'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
      ...((primaries['CCU'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
      ...((radios['CCU'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
    ];
    final servers = <String>[
      ...((members['Server'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
      ...((primaries['Server'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
      ...((radios['Server'] ?? const <dynamic>[]) as List<dynamic>).map(
        (item) => item.toString(),
      ),
    ];

    final detailTrees = <TreeType<SimpleTreeNode>>[];
    if (ccus.isNotEmpty && mtc.select.type != 1) {
      final treeData = _parseCcuAndServerNodes(ccus, rootTitle: 'CCU');
      detailTrees.add(buildTree(treeData).$1);
    }
    if (servers.isNotEmpty && mtc.select.type != 1) {
      final treeData = _parseCcuAndServerNodes(servers, rootTitle: 'Server');
      detailTrees.add(buildTree(treeData).$1);
    }
    if (radios.isNotEmpty) {
      final radioData = _parseRadioNodes(
        radios,
        rootTitle: 'Radio',
        type: mtc.select.type,
      );
      detailTrees.add(buildTree(radioData).$1);
    }

    final groups = _buildDeviceGroups(detailTrees);
    setState(() {
      dtc.data = detailTrees;
      deviceGroups = groups;
    });

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        dtc.visible = true;
      });
    });
  }

  Map<String, dynamic> _parseCcuAndServerNodes(
    List<String> nodes, {
    required String rootTitle,
  }) {
    final root = <String, dynamic>{
      'id': 0,
      'title': rootTitle,
      'NetNodes': <dynamic>[],
      'UserIds': <dynamic>[],
      'children': <dynamic>[],
      'isleaf': false,
      'isShowCheckbox': false,
      'type': 999,
    };

    root['children'] = nodes.map((deviceId) {
      final config = FileTools.readFileContentAsMap(
        p.join(dataPath, '3_device_config', '$deviceId.json'),
      );
      final ip =
          (config['audioBoardIpConfig']?['result']?['ip'] ??
              config['Ipv4Subnet']) ??
          '';
      return <String, dynamic>{
        'id': 0,
        'title': deviceId,
        'NetNodes': <dynamic>[],
        'UserIds': <dynamic>[],
        'children': <dynamic>[],
        'isleaf': true,
        'isShowCheckbox': false,
        'type': 999,
        'subTexts': ['ESN: ', '当前IP: $ip'],
        'isActive': _isDeviceFound,
        'activeTexts': foundDevice.isNotEmpty
            ? ['未连接', '已连接']
            : const <String>[],
      };
    }).toList();

    return root;
  }

  bool get _isDeviceFound => foundDevice.isNotEmpty && foundDevice[0] == '1';

  List<CpdsDeviceGroup> _buildDeviceGroups(
    List<TreeType<SimpleTreeNode>> trees,
  ) {
    final groups = <CpdsDeviceGroup>[];

    for (final tree in trees) {
      final items = <CpdsDeviceItem>[];

      void collectLeaves(TreeType<SimpleTreeNode> node) {
        if (node.isLeaf) {
          items.add(
            CpdsDeviceItem(
              typeLabel: node.data.title.toString(),
              ip: node.data.subTexts?.length == 2
                  ? node.data.subTexts![1].replaceFirst('当前IP: ', '')
                  : '',
              esnSuffix: node.data.subTexts?.length == 2
                  ? node.data.subTexts![0].replaceFirst('ESN: ', '')
                  : '',
            ),
          );
          return;
        }

        for (final child in node.children) {
          collectLeaves(child);
        }
      }

      collectLeaves(tree);
      if (items.isNotEmpty) {
        groups.add(
          CpdsDeviceGroup(title: tree.data.title.toString(), items: items),
        );
      }
    }

    return groups;
  }

  Map<String, dynamic> _parseRadioNodes(
    Map<String, dynamic> nodes, {
    required String rootTitle,
    required int type,
  }) {
    final root = <String, dynamic>{
      'id': 0,
      'title': rootTitle,
      'NetNodes': <dynamic>[],
      'UserIds': <dynamic>[],
      'children': <dynamic>[],
      'isleaf': false,
      'isShowCheckbox': false,
      'type': 999,
    };

    var id = DateTime.now().millisecondsSinceEpoch;
    nodes.forEach((key, value) {
      id++;
      final sonNode = <String, dynamic>{
        'id': 'key-$id',
        'title': key,
        'NetNodes': <dynamic>[],
        'UserIds': <dynamic>[],
        'children': <dynamic>[],
        'isleaf': false,
        'isShowCheckbox': false,
        'type': 999,
      };

      for (final deviceId in (value as List<dynamic>)) {
        id++;
        final config = FileTools.readFileContentAsMap(
          p.join(dataPath, '3_device_config', '$deviceId.json'),
        );
        final ip = config['IP'] ?? '';
        sonNode['children'].add(<String, dynamic>{
          'id': 'key-$id',
          'title': deviceId,
          'NetNodes': <dynamic>[],
          'UserIds': <dynamic>[],
          'children': <dynamic>[],
          'isleaf': true,
          'isShowCheckbox': type == 1,
          'type': 999,
          'subTexts': ['ESN: ', '当前IP: $ip'],
          'isActive': _isDeviceFound && type != 1,
          'activeTexts': foundDevice.isNotEmpty && type != 1
              ? ['未连接', '已连接']
              : const <String>[],
        });
      }
      root['children'].add(sonNode);
    });

    return root;
  }

  Future<void> _refreshDetail() async {
    setState(() {
      dtc.data = [];
      dtc.visible = false;
      dtc.selectRows.clear();
      dtc.activeStep = 1;
      dtc.selectWifi = -1;
      deviceGroups = [];
    });
    await _initNetworkInterfaceOptions();
    if (!mounted) {
      return;
    }
    foundDevice = ['0'];
    _initDetailTree();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Container(
      color: const Color(0xFF0E1114),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leftWidth = constraints.maxWidth < 720 ? 220.0 : 450.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: leftWidth, child: _buildMasterTree(context, t)),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: CpdsRightPanel(
                  key: ValueKey(mtc.select.id),
                  nodeName: _selectedNodeTitle,
                  visible: dtc.visible,
                  selectedNetworkIndex: dtc.selectWifi,
                  networkOptions: networkOptions,
                  activeStep: dtc.activeStep,
                  steps: steps,
                  deviceGroups: deviceGroups,
                  onlineCount: onlineCount,
                  onNetworkChanged: (value) {
                    setState(() {
                      dtc.selectWifi = value ?? -1;
                    });
                  },
                  onRefresh: _refreshDetail,
                  onIssue: () {
                    startDistribution();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMasterTree(BuildContext context, Translations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
          child: TextTitle(text: t.pager.radioManager.fileParse),
        ),
        FileUploads(
          onUpdate: (String path) {
            _resetMasterTree();
            _initLeftTree(path);
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171C22),
                border: Border.all(
                  width: 1,
                  color: const Color(0x8A00A2E9),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 0, 10),
                    child: Row(
                      children: [
                        Text(
                          t.pager.radioManager.netNode,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  DataTablePlusThemeProvider(
                    theme: getThemePreset(ThemePreset.dark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      child: SimpleFilterSearchField(
                        value: mtc.searchValue,
                        controller: mtc.searchTextFieldController,
                        onChanged: (value) {
                          mtc.searchValue = value;
                          updateTreeWithSearchingTitle(mtc.data, value);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Visibility(
                        visible: mtc.visible,
                        child: SimpleTreeView(
                          mtc.data,
                          onNodeDataChanged: _handleNodeChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
