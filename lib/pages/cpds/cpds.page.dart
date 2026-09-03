import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/api/cpds.api.dart';
import 'package:flutter_kts_template/components/dialog/simple.tips.dialog.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_factory.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_key_loader_file_dialog.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_package_panel.dart';
import 'package:flutter_kts_template/utils/files/pick_files/FileSelector.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'widgets/cpds_device_panel.dart';
import 'widgets/cpds_dialogs.dart';
import 'widgets/cpds_messages.dart';
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

    // 先弹出确认框：重新上传将清空注钥数据。
    final proceed = await _confirmClearKeyLoader();
    if (proceed != true || !mounted) return;

    // 确认后再选择文件来源：本地文件 或 注钥枪设备文件。
    final source = await _chooseBrowseSource();
    if (source == null || !mounted) return;

    switch (source) {
      case _CpdsBrowseSource.local:
        await _browseLocal();
      case _CpdsBrowseSource.keyLoader:
        await _browseKeyLoader();
    }
  }

  Future<_CpdsBrowseSource?> _chooseBrowseSource() {
    return showDialog<_CpdsBrowseSource>(
      context: context,
      builder: (dialogContext) => const _CpdsBrowseSourceDialog(),
    );
  }

  Future<void> _browseLocal() async {
    if (_state.active || _uploading) return;
    final placeholder = Translations.of(context).cpds.filePlaceholder;
    final browseFailedTitle = Translations.of(context).common.OperationError;

    setState(() {
      _uploading = true;
    });
    try {
      final file = await FileSelector.pickFile(['zip']);
      if (file == null) {
        SimplePopup.warn(placeholder);
        return;
      }
      // 已在浏览前确认，选中文件后清空注钥数据。
      _clearKeyLoaderData();
      final state = await CpdsApi.uploadPackage(file);
      _applyState(state);
      // 上传成功后自动解析。
      await _parse();
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

  Future<void> _parse() async {
    if (_state.upload == null || _state.active) return;
    final t = Translations.of(context);
    try {
      final state = await CpdsApi.parsePackage();
      _applyState(state);
      SimplePopup.success(t.cpds.keyLoaderParseSuccess);
    } catch (error) {
      GlobalLogger.logError('PARSE_FAILED $error');
      final detail = error is CpdsException
          ? CpdsMessages.errorCode(context, error.code, params: error.params)
          : error.toString();
      SimplePopup.error('${t.cpds.keyLoaderParseFailed}：$detail');
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

  Future<void> _selectFutureWarrior(String unitId) async {
    if (_state.active) return;
    try {
      _applyState(await CpdsApi.selectFutureWarrior(unitId));
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
      if (mounted) {
        setState(() {
          _distributing = false;
        });
      }
    }
  }

  Future<void> _browseKeyLoader() async {
    if (_state.active || _uploading) return;
    final t = Translations.of(context);

    setState(() {
      _uploading = true;
    });
    try {
      final manager = getKeyLoaderUsbBulkManager();

      // Android 需先申请 USB 权限；其它平台直接放行。
      if (Platform.isAndroid) {
        if (!await manager.hasPermission()) {
          final granted = await manager
              .requestPermission()
              .timeout(const Duration(seconds: 30), onTimeout: () => false);
          if (!granted) {
            SimplePopup.error(t.cpds.keyLoaderPermissionDenied);
            return;
          }
        }
      }

      // 弹窗内完成：连接注钥枪 → 获取文件列表 → 文件选择。
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const CpdsKeyLoaderFileDialog(),
      );
      if (selected != null) {
        GlobalLogger.logInfo('KEY_LOADER_SELECTED $selected');
        // TODO: 后续从注钥枪读取所选文件并作为通信包上传。
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _saveFutureWarrior(
    List<CpdsFutureWarriorDevice> devices,
    String unitId,
  ) async {
    final t = Translations.of(context);

    final List<KeyLoadersEntity> keyLoaders;
    try {
      final response = await KeyLoadersApi.getAll();
      keyLoaders = List<KeyLoadersEntity>.from(response.data.list as List);
    } catch (error) {
      if (mounted) _showError(error);
      return;
    }
    if (!mounted) return;

    if (keyLoaders.isEmpty) {
      SimpleTipsDialog(
        context,
        title: t.tips.title,
        contentText: t.tips.paramsInject.noKeyLoader,
        okText: t.cpds.goNow,
        func: () {
          context.go('/injectEncryptStick');
        },
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => CpdsFutureWarriorSaveDialog(
        devices: devices,
        unitId: unitId,
        units: _state.package?.units ?? const [],
        keyLoaders: keyLoaders,
        onSave: (json) {
          Navigator.of(dialogContext).pop();
          unawaited(_persistFutureWarrior(json));
        },
      ),
    );
  }

  Future<void> _persistFutureWarrior(Map<String, dynamic> json) async {
    final now = DateTime.now();
    final keyLoaderId = json['keyLoaderId'] as int?;
    final parentIdPath = json['parentIdPath'] as String? ?? '';
    final items = (json['items'] as List? ?? const []);

    if (keyLoaderId == null) {
      return;
    }

    // 先清除该注钥枪已有的子表数据，再写入本次勾选的数据（替换式保存）。
    final detailBox = DatabaseManager.instance.box<KeyLoaderDetailsEntity>();
    detailBox
        .query(KeyLoaderDetailsEntity_.keyLoaderId.equals(keyLoaderId))
        .build()
        .remove();

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final detail = KeyLoaderDetailsEntity(
        netNodePackageName: item['netNodePackageName']?.toString() ?? '',
        dcPackageName: item['dcPackageName']?.toString() ?? '',
        keyLoaderId: keyLoaderId,
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
                  onBrowse: _browse,
                  onSelectNode: _selectNode,
                  onSelectFutureWarrior: _selectFutureWarrior,
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
                  distributing: _distributing || _state.active,
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

enum _CpdsBrowseSource { local, keyLoader }

class _CpdsBrowseSourceDialog extends StatefulWidget {
  const _CpdsBrowseSourceDialog();

  @override
  State<_CpdsBrowseSourceDialog> createState() =>
      _CpdsBrowseSourceDialogState();
}

class _CpdsBrowseSourceDialogState extends State<_CpdsBrowseSourceDialog> {
  _CpdsBrowseSource _selected = _CpdsBrowseSource.local;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        t.cpds.browseSourceTitle,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(t.cpds.browseSourceLocal, _CpdsBrowseSource.local),
          const SizedBox(height: 8),
          _buildOption(
            t.cpds.browseSourceKeyLoader,
            _CpdsBrowseSource.keyLoader,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            t.tips.cancel,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(t.tips.ok),
        ),
      ],
    );
  }

  Widget _buildOption(String label, _CpdsBrowseSource value) {
    final selected = _selected == value;
    return InkWell(
      onTap: () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0E1114) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? const Color(0xFF00A2E9)
                : const Color(0x26FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? const Color(0xFF00A2E9) : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
