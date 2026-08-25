import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/cpds.api.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/files/pick_files/FileSelector.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/cpds_device_panel.dart';
import 'widgets/cpds_dialogs.dart';
import 'widgets/cpds_messages.dart';
import 'widgets/cpds_package_panel.dart';
import 'widgets/cpds_save_dialog.dart';

class CpdsPage extends StatefulWidget {
  const CpdsPage({super.key});

  @override
  State<CpdsPage> createState() => _CpdsPageState();
}

class _CpdsPageState extends State<CpdsPage> {
  CpdsApplicationState _state = CpdsApplicationState();
  List<CpdsNetworkInterface> _interfaces = const [];
  String _selectedInterfaceName = '';
  bool _automaticInterface = false;
  bool _interfacesLoading = false;
  bool _uploading = false;
  bool _parsing = false;
  bool _distributing = false;
  bool _resolvingDecision = false;
  bool _discoveryDialogShowing = false;
  String? _shownDiscoverySessionId;
  String? _shownResultSessionId;
  StreamSubscription<CpdsApplicationState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _applyState(await CpdsApi.getState());
      await _refreshNetworkInterfaces();
      _subscription = CpdsApi.subscribe(_applyState);
    } catch (error) {
      _showError(error);
    }
  }

  void _applyState(CpdsApplicationState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowDialogs(state);
    });
  }

  void _maybeShowDialogs(CpdsApplicationState state) {
    final session = state.session;
    if (session == null) return;
    if (session.activeState == CpdsActiveState.awaitingDiscoveryConfirmation &&
        session.sessionId != _shownDiscoverySessionId &&
        !_resolvingDecision) {
      _shownDiscoverySessionId = session.sessionId;
      _showDiscoveryMismatchDialog(session);
      return;
    }
    final terminal =
        session.activeState == CpdsActiveState.completed ||
        session.activeState == CpdsActiveState.partialSuccess ||
        session.activeState == CpdsActiveState.failed;
    if (terminal && session.sessionId != _shownResultSessionId) {
      _shownResultSessionId = session.sessionId;
      _showResultDialog(session);
    }
  }

  Future<void> _showDiscoveryMismatchDialog(CpdsSessionView session) async {
    if (_discoveryDialogShowing) return;
    _discoveryDialogShowing = true;
    try {
      final proceed = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (dialogContext) => CpdsDiscoveryMismatchDialog(
          session: session,
          submitting: _resolvingDecision,
          onResolve: (value) => Navigator.of(dialogContext).pop(value),
        ),
      );
      if (proceed == null || !mounted) return;
      await _resolveMismatch(session.sessionId, proceed);
    } finally {
      _discoveryDialogShowing = false;
    }
  }

  Future<void> _resolveMismatch(String sessionId, bool proceed) async {
    if (_resolvingDecision) return;
    setState(() {
      _resolvingDecision = true;
    });
    try {
      _applyState(
        await CpdsApi.resolveDiscoveryMismatch(
          sessionId: sessionId,
          proceed: proceed,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _resolvingDecision = false;
        });
      }
    }
  }

  Future<void> _showResultDialog(CpdsSessionView session) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (dialogContext) => CpdsResultDialog(
        session: session,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _refreshNetworkInterfaces() async {
    if (_state.active || _interfacesLoading) return;
    setState(() {
      _interfacesLoading = true;
    });
    try {
      final interfaces = await CpdsApi.listNetworkInterfaces();
      final stored = Shared.getCpdsNetworkInterface() ?? '';
      var selectedName = '';
      var automatic = false;
      if (interfaces.length == 1) {
        selectedName = interfaces.first.name;
        automatic = true;
      } else if (stored.isNotEmpty &&
          interfaces.any((item) => item.name == stored)) {
        selectedName = stored;
      }

      if (!mounted) return;
      setState(() {
        _interfaces = interfaces;
        _selectedInterfaceName = selectedName;
        _automaticInterface = automatic;
      });
      await CpdsApi.selectNetworkInterface(selectedName);
      await Shared.saveCpdsNetworkInterface(selectedName);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _interfaces = [];
        _selectedInterfaceName = '';
        _automaticInterface = false;
      });
      await Shared.saveCpdsNetworkInterface('');
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _interfacesLoading = false;
        });
      }
    }
  }

  Future<void> _browse() async {
    if (_state.active || _uploading) return;
    final placeholder = Translations.of(context).cpds.filePlaceholder;
    final browseFailedTitle = Translations.of(context).common.OperationError;

    // 注钥管理有数据时，提示重新上传将清空注钥数据，确认后再继续选择文件
    var clearOnUpload = false;
    if (_hasKeyLoaderData()) {
      final proceed = await _confirmClearKeyLoader();
      if (proceed != true || !mounted) return;
      clearOnUpload = true;
    }

    setState(() {
      _uploading = true;
    });
    try {
      final file = await FileSelector.pickFile(['zip']);
      if (file == null) {
        SimplePopup.warn(placeholder);
        return;
      }
      // 只有用户确认并真正选中文件后，才清空注钥数据
      if (clearOnUpload) {
        _clearKeyLoaderData();
      }
      final state = await CpdsApi.uploadPackage(file);
      _applyState(state);
    } catch (error) {
      _showError(error, title: browseFailedTitle);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  /// 已上传文件时，再次浏览前弹出确认框：重新上传将清空注钥数据。
  Future<bool?> _confirmClearKeyLoader() {
    final t = Translations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        title: Text(
          t.tips.title,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          t.cpds.browseConfirm,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              t.tips.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.tips.ok),
          ),
        ],
      ),
    );
  }

  /// 清空“注钥管理”页面的数据（父表 + 明细表）。
  void _clearKeyLoaderData() {
    DatabaseManager.instance.removeAll<KeyLoaderDetailsEntity>();
    DatabaseManager.instance.removeAll<KeyLoadersEntity>();
  }

  /// 判断“注钥管理”是否有数据（父表或明细表任一非空）。
  bool _hasKeyLoaderData() {
    return DatabaseManager.instance.count<KeyLoadersEntity>() > 0 ||
        DatabaseManager.instance.count<KeyLoaderDetailsEntity>() > 0;
  }

  Future<void> _parse() async {
    if (_state.upload == null || _state.active || _parsing) return;
    final importFailedTitle = CpdsMessages.isZh(context)
        ? '通信包导入失败'
        : 'Package import failed';
    setState(() {
      _parsing = true;
    });
    try {
      final state = await CpdsApi.parsePackage();
      _applyState(state);
    } catch (error) {
      _showError(error, title: importFailedTitle);
    } finally {
      if (mounted) {
        setState(() {
          _parsing = false;
        });
      }
    }
  }

  Future<void> _selectNode(String nodeId) async {
    if (_state.active) return;
    try {
      _applyState(await CpdsApi.selectNode(nodeId));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _selectInterface(String? name) async {
    final value = name ?? '';
    if (_state.active || value == _selectedInterfaceName) return;
    try {
      final state = await CpdsApi.selectNetworkInterface(value);
      if (!mounted) return;
      setState(() {
        _selectedInterfaceName = value;
        _automaticInterface = false;
      });
      _applyState(state);
      await Shared.saveCpdsNetworkInterface(value);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _distribute() async {
    if (_distributing || _state.active || !_state.canDistribute) return;
    _distributing = true;
    final distributionFailedTitle = CpdsMessages.resultTitle(
      context,
      CpdsActiveState.failed,
    );
    try {
      _applyState(await CpdsApi.startDistribution());
    } catch (error) {
      _showError(error, title: distributionFailedTitle);
    } finally {
      _distributing = false;
    }
  }

  void _saveFutureWarrior(List<CpdsDevice> devices) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => CpdsFutureWarriorSaveDialog(
        devices: devices,
        selectedNodeId: _state.selectedNodeId,
        units: _state.package?.units ?? const [],
        onSave: (json) {
          Navigator.of(dialogContext).pop();
          unawaited(_persistFutureWarrior(json));
        },
      ),
    );
  }

  Future<void> _persistFutureWarrior(Map<String, dynamic> json) async {
    final now = DateTime.now();
    final name = json['name'] as String;
    final nodeId = json['nodeId'] as String;
    final parentIdPath = json['parentIdPath'] as String? ?? '';
    final items = (json['items'] as List? ?? const []);

    final parentId = DatabaseManager.instance.put<KeyLoadersEntity>(
      KeyLoadersEntity(name: name, createdAt: now, updatedAt: now),
    );

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final detail = KeyLoaderDetailsEntity(
        netNodePackageName: nodeId,
        dcPackageName: item['communicationParameterPackage']?.toString() ?? '',
        keyLoaderId: parentId,
        radioId: item['radioId'] as int?,
        consumer: item['consumer']?.toString(),
        location: item['location']?.toString(),
        SN: item['sn']?.toString(),
        parentIdPath: parentIdPath,
        createdAt: now,
        updatedAt: now,
      );
      DatabaseManager.instance.put<KeyLoaderDetailsEntity>(detail);
    }

    SimplePopup.success('保存成功');
  }

  void _showError(Object error, {String? title}) {
    final dialogTitle = title ?? Translations.of(context).common.OperationError;
    if (error is CpdsException) {
      showDialog<void>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: true,
        builder: (dialogContext) => CpdsErrorDialog(
          title: dialogTitle,
          error: error,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        title: Text(
          dialogTitle,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(Translations.of(context).common.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: const Color(0xFF0E1114),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 550.w,
                child: CpdsPackagePanel(
                  state: _state,
                  uploading: _uploading,
                  parsing: _parsing,
                  onBrowse: _browse,
                  onParse: _parse,
                  onSelectNode: _selectNode,
                ),
              ),
              const VerticalDivider(
                thickness: 1,
                width: 1,
                color: Color(0x40FFFFFF),
              ),
              Expanded(
                child: CpdsDevicePanel(
                  state: _state,
                  interfaces: _interfaces,
                  selectedInterfaceName: _selectedInterfaceName,
                  automaticInterface: _automaticInterface,
                  interfacesLoading: _interfacesLoading,
                  canDistribute: _state.canDistribute,
                  onRefreshInterfaces: _refreshNetworkInterfaces,
                  onSelectInterface: _selectInterface,
                  onDistribute: _distribute,
                  onSaveFutureWarrior: _saveFutureWarrior,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Flutter Windows 引擎的已知无障碍语义树 bug：选中节点触发整页重建时，
    // 语义树中会出现孤儿节点，导致报错：
    // "Failed to update ui::AXTree, error: N will not be in the tree and is not the new root"
    // 该错误不影响视觉渲染与鼠标/键盘操作，但会让无障碍树冻结。
    // 在 Windows 上排除本页语义即可消除此错误。
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return ExcludeSemantics(child: page);
    }
    return page;
  }
}
