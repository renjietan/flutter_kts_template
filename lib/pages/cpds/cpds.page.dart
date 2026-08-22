import 'dart:async';

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
  bool _resolvingDecision = false;
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
        !_resolvingDecision) {
      _showDiscoveryMismatchDialog(session);
      return;
    }
    final terminal = session.activeState == CpdsActiveState.completed ||
        session.activeState == CpdsActiveState.partialSuccess ||
        session.activeState == CpdsActiveState.failed;
    if (terminal && session.sessionId != _shownResultSessionId) {
      _shownResultSessionId = session.sessionId;
      _showResultDialog(session);
    }
  }

  Future<void> _showDiscoveryMismatchDialog(CpdsSessionView session) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CpdsDiscoveryMismatchDialog(
        session: session,
        submitting: _resolvingDecision,
        onResolve: (value) => Navigator.of(dialogContext).pop(value),
      ),
    );
    if (proceed == null || !mounted) return;
    await _resolveMismatch(session.sessionId, proceed);
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
    setState(() {
      _uploading = true;
    });
    try {
      final file = await FileSelector.pickFile(['zip']);
      if (file == null) {
        SimplePopup.warn(placeholder);
        return;
      }
      final state = await CpdsApi.uploadPackage(file);
      _applyState(state);
    } catch (error) {
      _showError(
        error,
        title: browseFailedTitle,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
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
      _showError(
        error,
        title: importFailedTitle,
      );
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
    if (!_state.canDistribute || _state.active) return;
    final distributionFailedTitle = CpdsMessages.resultTitle(
      context,
      CpdsActiveState.failed,
    );
    try {
      SimplePopup.loading();
      _applyState(await CpdsApi.startDistribution());
    } catch (error) {
      _showError(
        error,
        title: distributionFailedTitle,
      );
    } finally {
      SimplePopup.hideLoading();
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
      KeyLoadersEntity(
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
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
    final dialogTitle =
        title ?? Translations.of(context).common.OperationError;
    if (error is CpdsException) {
      showDialog<void>(
        context: context,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0E1114),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final leftWidth = constraints.maxWidth < 720
              ? constraints.maxWidth * 0.56
              : 717.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: leftWidth,
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
  }
}
