import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:dage/dage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/api/cpds.api.dart';
import 'package:flutter_kts_template/components/dialog/simple.tips.dialog.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/cpds/service/cpds_manager.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_factory.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_key_loader_file_dialog.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_package_panel.dart';
import 'package:flutter_kts_template/utils/files/pick_files/FileSelector.dart';
import 'package:flutter_kts_template/utils/provider/menu.provider.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

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
  bool _suppressNetworkInterfaceDialogs = false;
  bool _uploading = false;
  bool _browseRunning = false;
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
      _checkStartupPcFiles();
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
      _suppressNetworkInterfaceDialogs = true;
      try {
        await _refreshNetworkInterfaces();
      } finally {
        _suppressNetworkInterfaceDialogs = false;
      }
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
        builder: (dialogContext) {
          var closed = false;
          return CpdsDiscoveryMismatchDialog(
            session: session,
            submitting: _resolvingDecision,
            onResolve: (value) {
              if (closed) return;
              closed = true;
              Navigator.of(dialogContext).pop(value);
            },
          );
        },
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
      builder: (dialogContext) {
        var closed = false;
        return CpdsResultDialog(
          session: session,
          onClose: () {
            if (closed) return;
            closed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _refreshNetworkInterfaces() async {
    if (_state.active || _interfacesLoading) return;
    setState(() {
      _interfacesLoading = true;
    });
    List<CpdsNetworkInterface> interfaces;
    try {
      interfaces = await CpdsApi.listNetworkInterfaces();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _interfaces = [];
        _selectedInterfaceName = '';
        _automaticInterface = false;
        _interfacesLoading = false;
      });
      await Shared.saveCpdsNetworkInterface('');
      if (!_suppressNetworkInterfaceDialogs) {
        _showError(error);
      }
      return;
    }

    if (!mounted) return;
    if (interfaces.isEmpty) {
      setState(() {
        _interfaces = const [];
        _selectedInterfaceName = '';
        _automaticInterface = false;
        _interfacesLoading = false;
      });
      await Shared.saveCpdsNetworkInterface('');
      return;
    }

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

    try {
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
      if (!_suppressNetworkInterfaceDialogs) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _interfacesLoading = false;
        });
      }
    }
  }

  Future<void> _browse() async {
    if (_browseRunning || _state.active || _uploading) return;
    _browseRunning = true;
    try {
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
    } finally {
      _browseRunning = false;
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
      final file = await FileSelector.pickFile(['pc']);
      if (file == null) {
        SimplePopup.warn(placeholder);
        return;
      }
      final pcFile = File(file.path!);
      await _importPcFile(pcFile, clearKeyLoader: true);
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

  Future<void> _importPcFile(
    File sourceFile, {
    required bool clearKeyLoader,
    bool frostedGlass = false,
  }) async {
    final uploadsPath = await DirectoryManager.instance.getUploadsPath();
    final destPath = p.join(uploadsPath, p.basename(sourceFile.path));
    final stored = File(destPath);
    if (sourceFile.path != destPath) {
      await sourceFile.copy(destPath);
    }

    Uint8List? zipBytes;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CpdsPcPasswordDialog(
        frostedGlass: frostedGlass,
        fileName: p.basename(stored.path),
        onVerify: (password) async {
          try {
            zipBytes = await _decryptPc(stored, password);
            return true;
          } catch (e) {
            GlobalLogger.logError('PC_DECRYPT_FAILED $e');
            return false;
          }
        },
      ),
    );

    if (ok != true || zipBytes == null) {
      try {
        if (await stored.exists()) await stored.delete();
      } catch (_) {}
      SimplePopup.error(
        CpdsMessages.tr(context, '文件已销毁，请重新选择文件', 'File destroyed, please select again', 'الملف مدمر، يرجى إعادة الاختيار'),
      );
      return;
    }

    if (clearKeyLoader) {
      _clearKeyLoaderData();
    }
    final zipName = _txbzJsonUaeName(p.basename(stored.path));
    await CpdsManager.instance.uploadPackage(zipName, zipBytes!);
    await CpdsManager.instance.parsePackage();
    CpdsManager.instance.updateUploadName(p.basename(stored.path));
    _applyState(CpdsManager.instance.state());
    final keepPaths = <String>[
      stored.path,
      if (CpdsManager.instance.uploadPath != null)
        CpdsManager.instance.uploadPath!,
    ];
    await _deleteOtherUploadFiles(keepPaths);
  }

  Future<void> _deleteOtherUploadFiles(Iterable<String> keepPaths) async {
    final uploadsPath = await DirectoryManager.instance.getUploadsPath();
    final dir = Directory(uploadsPath);
    if (!await dir.exists()) return;

    final keep = keepPaths
        .map((item) => p.normalize(item).toLowerCase())
        .toSet();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      if (keep.contains(p.normalize(entity.path).toLowerCase())) continue;
      try {
        if (await entity.exists()) {
          await entity.delete();
          GlobalLogger.logInfo('CPDS_CLEAN_OTHER_UPLOAD ${entity.path}');
        }
      } catch (e) {
        GlobalLogger.logWarn(
          'CPDS_CLEAN_OTHER_UPLOAD_FAILED ${entity.path} $e',
        );
      }
    }
  }

  String _txbzJsonUaeName(String sourceName) {
    final match = RegExp(r'(\d{14})').firstMatch(sourceName);
    final timestamp = match?.group(1) ?? _compactTimestamp(DateTime.now());
    return 'txbz_json_UAE_$timestamp.zip';
  }

  String _compactTimestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  Future<Uint8List> _decryptPc(File file, String password) async {
    final bytes = await file.readAsBytes();
    final chunks = await decryptWithPassphrase(
      Stream.value(bytes),
      passphraseProvider: _PcPassphrase(password),
    ).toList();
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<void> _checkStartupPcFiles() async {
    try {
      final uploadsPath = await DirectoryManager.instance.getUploadsPath();
      final dir = Directory(uploadsPath);
      if (!await dir.exists()) return;
      final pcFiles = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File && p.extension(entity.path).toLowerCase() == '.pc') {
          pcFiles.add(entity);
        }
      }

      if (pcFiles.isEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF20262D),
            title: Text(
              Translations.of(dialogContext).tips.title,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
            content: Text(
              CpdsMessages.tr(context, '本地暂无可加载文件，是否立即选择？', 'No local file to load. Select now?', 'لا يوجد ملف محلي قابل للتحميل. هل تريد الاختيار الآن؟'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(Translations.of(dialogContext).tips.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(Translations.of(dialogContext).common.confirm),
              ),
            ],
          ),
        );
        if (proceed == true && mounted) {
          await _runBrowseFromSource();
        }
        return;
      }

      pcFiles.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });
      await _importPcFile(
        pcFiles.first,
        clearKeyLoader: false,
        frostedGlass: true,
      );
    } catch (e) {
      GlobalLogger.logError('STARTUP_PC_CHECK_FAILED $e');
    }
  }

  Future<void> _runBrowseFromSource() async {
    final source = await _chooseBrowseSource();
    if (!mounted || source == null) return;
    switch (source) {
      case _CpdsBrowseSource.local:
        await _browseLocal();
      case _CpdsBrowseSource.keyLoader:
        await _browseKeyLoader();
    }
  }

  /// 已上传文件时，再次浏览前弹出确认框：重新上传将清空注钥数据。
  Future<bool?> _confirmClearKeyLoader() {
    final t = Translations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var closed = false;
        void close(bool value) {
          if (closed) return;
          closed = true;
          Navigator.of(dialogContext).pop(value);
        }

        return AlertDialog(
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
              onPressed: () => close(false),
              child: Text(
                t.tips.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(onPressed: () => close(true), child: Text(t.tips.ok)),
          ],
        );
      },
    );
  }

  /// 仅清空注钥枪绑定的设备明细（子表），保留注钥枪列表（父表）。
  void _clearKeyLoaderData() {
    DatabaseManager.instance.removeAll<KeyLoaderDetailsEntity>();
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
          final granted = await manager.requestPermission().timeout(
            const Duration(seconds: 30),
            onTimeout: () => false,
          );
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
        if (!mounted) return;
        try {
          _applyState(await CpdsApi.getState());
        } catch (error) {
          _showError(error);
        }
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

    // 电台列表为空时，提示并跳转到【电台管理】。
    final List<RadiosEntity> radios;
    try {
      final radiosResponse = await RadiosManagerApi.getAll();
      radios = List<RadiosEntity>.from(radiosResponse.data.list as List);
    } catch (error) {
      if (mounted) _showError(error);
      return;
    }
    if (!mounted) return;

    if (radios.isEmpty) {
      SimpleTipsDialog(
        context,
        title: t.tips.title,
        contentText: t.tips.paramsInject.noRadio,
        okText: t.cpds.goNow,
        func: () {
          Provider.of<MenuProvider>(context, listen: false).selectedIndex = 1;
          context.go('/radioManager');
        },
      );
      return;
    }

    // 注钥列表为空时，提示并跳转到【注钥枪管理】。
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
          Provider.of<MenuProvider>(context, listen: false).selectedIndex = 2;
          context.go('/injectEncryptStick');
        },
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => CpdsFutureWarriorSaveDialog(
        devices: devices,
        unitId: unitId,
        units: _state.package?.units ?? const [],
        keyLoaders: keyLoaders,
        onSave: (json) {
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
    final overwrites = (json['overwrites'] as List? ?? const []);

    if (keyLoaderId == null) {
      return;
    }

    for (final rawItem in overwrites) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final netNodePackageName = item['netNodePackageName']?.toString() ?? '';
      final dcPackageName = item['dcPackageName']?.toString() ?? '';
      final detailBox = DatabaseManager.instance.box<KeyLoaderDetailsEntity>();
      final existing = detailBox
          .query(
            KeyLoaderDetailsEntity_.keyLoaderId
                .equals(keyLoaderId)
                .and(
                  KeyLoaderDetailsEntity_.netNodePackageName.equals(
                    netNodePackageName,
                  ),
                )
                .and(
                  KeyLoaderDetailsEntity_.dcPackageName.equals(dcPackageName),
                )
                .and(KeyLoaderDetailsEntity_.parentIdPath.equals(parentIdPath)),
          )
          .build()
          .findFirst();
      if (existing == null) continue;
      existing.dcPackageAlias = item['deviceAlias']?.toString();
      existing.radioId = item['radioId'] as int?;
      existing.consumer = item['consumer']?.toString();
      existing.location = item['location']?.toString();
      existing.SN = item['sn']?.toString();
      existing.parentIdPath = parentIdPath;
      existing.updatedAt = now;
      detailBox.put(existing);
    }

    // 重复数据按上面的逻辑覆盖，非重复数据继续新增。

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final detail = KeyLoaderDetailsEntity(
        netNodePackageName: item['netNodePackageName']?.toString() ?? '',
        dcPackageName: item['dcPackageName']?.toString() ?? '',
        dcPackageAlias: item['deviceAlias']?.toString(),
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

    SimplePopup.success(t.common.saveSuccess);
  }

  void _showError(Object error, {String? title}) {
    final dialogTitle = title ?? Translations.of(context).common.OperationError;
    if (error is CpdsException) {
      showDialog<void>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: true,
        builder: (dialogContext) {
          var closed = false;
          return CpdsErrorDialog(
            title: dialogTitle,
            error: error,
            onClose: () {
              if (closed) return;
              closed = true;
              Navigator.of(dialogContext).pop();
            },
          );
        },
      );
      return;
    }
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (dialogContext) {
        var closed = false;
        return AlertDialog(
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
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.of(dialogContext).pop();
              },
              child: Text(Translations.of(context).common.confirm),
            ),
          ],
        );
      },
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

class _PcPassphrase extends PassphraseProvider {
  _PcPassphrase(this.password);

  final String password;

  @override
  Future<String> passphrase() async => password;
}

class _CpdsPcPasswordDialog extends StatefulWidget {
  const _CpdsPcPasswordDialog({
    required this.onVerify,
    required this.fileName,
    this.frostedGlass = false,
  });

  final Future<bool> Function(String password) onVerify;
  final String fileName;
  final bool frostedGlass;

  @override
  State<_CpdsPcPasswordDialog> createState() => _CpdsPcPasswordDialogState();
}

class _CpdsPcPasswordDialogState extends State<_CpdsPcPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  int _attempt = 0;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return CpdsMessages.tr(context, '密码不可为空', 'Password cannot be empty', 'كلمة المرور لا يمكن أن تكون فارغة');
    if (text.characters.length > 100) {
      return CpdsMessages.tr(context, '密码长度不能超过100个字符', 'Password cannot exceed 100 characters', 'لا يمكن أن تتجاوز كلمة المرور 100 حرف');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final ok = await widget.onVerify(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    _attempt++;
    _controller.clear();
    if (_attempt >= 3) {
      Navigator.of(context).pop(false);
      return;
    }
    final remaining = 3 - _attempt;
    setState(() {
      _loading = false;
      _errorText = CpdsMessages.digits(
        context,
        CpdsMessages.tr(
          context,
          '密码错误，还剩 $remaining 次机会',
          'Wrong password, $remaining attempts left',
          'كلمة المرور خاطئة، تبقى $remaining محاولات',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        CpdsMessages.tr(context, '输入注钥包密码', 'Enter keyloader password', 'أدخل كلمة مرور حزمة المفاتيح'),
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller,
                obscureText: _obscure,
                autofocus: true,
                validator: _validate,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: CpdsMessages.tr(context, '密码', 'Password', 'كلمة المرور'),
                  hintText: CpdsMessages.tr(
                      context,
                      '请输入 ${widget.fileName} 文件密钥',
                      'Enter key for ${widget.fileName}',
                      'أدخل مفتاح الملف ${widget.fileName}'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF282D33),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Color(0xFFF15B64),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(Translations.of(context).common.confirm),
        ),
      ],
    );

    if (!widget.frostedGlass) return dialog;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: dialog,
    );
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
  bool _closed = false;

  void _close(_CpdsBrowseSource? value) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(value);
  }

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
          onPressed: () => _close(null),
          child: Text(
            t.tips.cancel,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton(
          onPressed: () => _close(_selected),
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
            color: selected ? const Color(0xFF00A2E9) : const Color(0x26FFFFFF),
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
