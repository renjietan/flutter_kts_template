import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:composable_data_table/composable_data_table.dart';
import 'package:crypto/crypto.dart';
import 'package:dage/dage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/components/step/step.progress.dialog.dart';
import 'package:flutter_kts_template/components/step/step.progress.model.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_factory.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_manager.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/core/utils/time.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'set_password_dialog.dart';

class KeyLoaderDetailsTable extends StatefulWidget {
  const KeyLoaderDetailsTable({
    super.key,
    required this.keyLoaderEntity,
    this.themePreset = ThemePreset.dark,
  });

  final KeyLoadersEntity? keyLoaderEntity;
  final ThemePreset themePreset;

  @override
  State<KeyLoaderDetailsTable> createState() => _KeyLoaderDetailsTableState();
}

class _KeyLoaderDetailsTableState extends State<KeyLoaderDetailsTable> {
  late final DataTablePlusTheme _theme;
  int _currentPage = 1;
  int _pageSize = 10;
  List<KeyLoaderDetailsEntity> _allData = [];
  final Set<String> _selectedIds = {};
  Future<List<KeyLoaderDetailsEntity>>? _future;
  RadiosProvider? _radiosProvider;
  List<RadiosEntity> _radios = [];
  bool _exporting = false;
  bool _usbDisconnected = false;
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _theme = _buildTheme();
    _future = _load();
    _loadRadios();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RadiosProvider>();
      _radiosProvider = provider;
      provider.addListener(_onRadiosChanged);
    });
  }

  void _onRadiosChanged() {
    if (!mounted) return;
    _loadRadios();
    setState(() {
      _future = _load();
    });
  }

  Future<void> _loadRadios() async {
    try {
      final response = await RadiosManagerApi.getAll();
      if (!mounted) return;
      setState(() {
        _radios = response.data.list;
      });
    } catch (error) {
      GlobalLogger.logError('load radios failed: $error');
    }
  }

  @override
  void dispose() {
    _radiosProvider?.removeListener(_onRadiosChanged);
    _tableScrollController.dispose();
    super.dispose();
  }

  DataTablePlusTheme _buildTheme() {
    return const DataTablePlusTheme(
      backgroundColor: Colors.transparent,
      headerBackgroundColor: Colors.transparent,
      borderColor: Color(0xFF353A41),
      borderLightColor: Color(0xFF282D33),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFB7BCC6),
      textMutedColor: Color(0xFF8A94A6),
      accentColor: Color(0xFF00A2E9),
      accentLightColor: Color(0xFF1E3A5F),
      successColor: Color(0xFF2FC88F),
      successLightColor: Color(0xFF1B3D1B),
      warningColor: Color(0xFFF0A43A),
      warningLightColor: Color(0xFF4D3800),
      dangerColor: Color(0xFFF15B64),
      dangerLightColor: Color(0xFF4D1F1F),
      cellPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      headerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      cellTextStyle: TextStyle(fontSize: 13, color: Colors.white),
      headerTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant KeyLoaderDetailsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyLoaderEntity?.id != widget.keyLoaderEntity?.id) {
      _future = _load();
      _currentPage = 1;
      _allData = [];
      _selectedIds.clear();
    }
  }

  Future<List<KeyLoaderDetailsEntity>> _load() async {
    final entity = widget.keyLoaderEntity;
    if (entity == null) return [];
    final response = await KeyLoadersApi.getDetails(entity.id);
    final list = response.data['list'] as List? ?? const [];
    return list
        .map(
          (item) =>
              KeyLoaderDetailsEntity.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  List<KeyLoaderDetailsEntity> get _pagedData {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _allData.length) return const [];
    final end = (start + _pageSize).clamp(0, _allData.length);
    return _allData.sublist(start, end);
  }

  int get _totalPages => (_allData.length / _pageSize).ceil().clamp(1, 999999);

  bool get _allSelected =>
      _pagedData.isNotEmpty &&
      _pagedData.every((item) => _selectedIds.contains(item.id.toString()));

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        for (final item in _pagedData) {
          _selectedIds.remove(item.id.toString());
        }
      } else {
        for (final item in _pagedData) {
          _selectedIds.add(item.id.toString());
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  /// USB 上传：连接注钥枪 → PAD_LIGHT 握手 → PAD_UPLOAD 协议发送 .pad 文件。
  /// 检查/申请注钥枪 USB 权限（仅 Android 需要；Windows 无授权弹窗）。
  Future<bool> _ensureUsbPermission() async {
    if (Platform.isWindows) return true;
    if (!Platform.isAndroid) return false;
    final manager = getKeyLoaderUsbBulkManager();
    if (await manager.hasPermission()) {
      return true;
    }
    final granted = await manager.requestPermission().timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
    if (!granted) {
      SimplePopup.error('未授予 USB 权限');
      return false;
    }
    return true;
  }

  Future<bool> _usbUploadPads(
    List<String> padPaths, {
    StepProgressController? controller,
  }) async {
    if (!Platform.isAndroid && !Platform.isWindows) {
      // 其它平台暂不支持。
      return true;
    }
    final manager = getKeyLoaderUsbBulkManager();
    const failColor = Color(0xFFF15B64);
    final usb = t.cpds.usbProgress;
    _usbDisconnected = false;

    // 点亮步骤条中的「USB」节点（索引 4）。
    controller?.setStep(4);

    _UsbLineReader? reader;
    StreamSubscription<void>? disconnectSub;

    try {
      // 4-1 连接
      controller?.addLine(usb.detailConnectStart, number: '4-1');
      if (!await manager.connect()) {
        controller?.addLine(
          usb.detailConnectFail,
          color: failColor,
          number: '4-1',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      controller?.addLine(usb.detailConnectSuccess, number: '4-1');

      reader = _UsbLineReader(manager.listenData())..start();
      disconnectSub = manager.onDisconnected.listen((_) {
        _usbDisconnected = true;
        reader?.abort(const _UsbDisconnected());
      });

      // 4-2 握手
      controller?.addLine(usb.detailHandshakeStart, number: '4-2');
      await _writeUsb(manager, Uint8List.fromList(utf8.encode('PAD_LIGHT\n')));
      final lightResult = await _waitReplyResult(reader);
      if (_handleUsbDisconnected(
        lightResult,
        controller,
        usb,
        failColor,
        '4-2',
      )) {
        return false;
      }
      if (lightResult == _UsbReplyResult.timeout) {
        controller?.addLine(
          usb.detailHandshakeTimeout,
          color: failColor,
          number: '4-2',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      if (lightResult != _UsbReplyResult.ok) {
        controller?.addLine(
          _replyFailureText(usb, lightResult),
          color: failColor,
          number: '4-2',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      controller?.addLine(usb.detailHandshakeSuccess, number: '4-2');

      // 4-3 准备
      controller?.addLine(usb.detailReadyStart, number: '4-3');
      await _writeUsb(manager, Uint8List.fromList(utf8.encode('PAD_UPLOAD\n')));
      final readyResult = await _waitReplyResult(
        reader,
        successValues: const {'READY\n'},
      );
      if (_handleUsbDisconnected(
        readyResult,
        controller,
        usb,
        failColor,
        '4-3',
      )) {
        return false;
      }
      if (readyResult == _UsbReplyResult.timeout) {
        controller?.addLine(
          usb.detailReadyTimeout,
          color: failColor,
          number: '4-3',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      if (readyResult != _UsbReplyResult.ok) {
        controller?.addLine(
          _replyFailureText(usb, readyResult),
          color: failColor,
          number: '4-3',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      controller?.addLine(usb.detailReadySuccess, number: '4-3');

      // 4-4 传输
      controller?.addLine(usb.detailTransferStart, number: '4-4');
      if (padPaths.length != 1) {
        GlobalLogger.logError(
          'USB_UPLOAD_EXPECTS_ONE_PAD got=${padPaths.length}',
        );
        controller?.addLine(usb.detailError, color: failColor);
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }

      final padPath = padPaths.single;
      final padFile = File(padPath);
      final fileBytes = await padFile.readAsBytes();

      // 文件名：当前 .pad 已经落到本地，直接使用存储后的 .pad 文件名。
      final fileName = p.basename(padPath);
      final nameBytes = utf8.encode(fileName);

      // 3、发送小端序 4 字节的数字 1，不等待回复。
      await _writeUsb(manager, _u32le(1));

      // 4、发送文件名长度（小端序 4 字节），不等待回复。
      await _writeUsb(manager, _u32le(nameBytes.length));

      // 5、立即发送文件名码流，不等待回复。
      await _writeUsb(manager, Uint8List.fromList(nameBytes));

      // 6、发送文件内容长度（小端序 8 字节），不等待回复。
      await _writeUsb(manager, _u64le(fileBytes.length));

      // 7、将文件内容按 4KB 拆包，逐包发送；每包发送完成后延迟 30ms，
      // 最后一包发送完成后也延迟 30ms，再进入 MD5 发送。
      const chunkSize = 4 * 1024;
      for (var offset = 0; offset < fileBytes.length; offset += chunkSize) {
        var end = offset + chunkSize;
        if (end > fileBytes.length) end = fileBytes.length;
        await _writeUsb(manager, Uint8List.sublistView(fileBytes, offset, end));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      // 8、发送整个文件内容的 16 字节 MD5，然后等待 FILE_OK。
      final md5Bytes = md5.convert(fileBytes).bytes;
      await _writeUsb(manager, Uint8List.fromList(md5Bytes));
      final result = await _waitReplyResult(reader);

      if (_handleUsbDisconnected(result, controller, usb, failColor, '4-5')) {
        return false;
      }
      if (result == _UsbReplyResult.timeout) {
        GlobalLogger.logWarn('USB_FILE_VERIFY_TIMEOUT');
        controller?.addLine(
          usb.detailVerifyTimeout,
          color: failColor,
          number: '4-5',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }
      if (result != _UsbReplyResult.ok) {
        GlobalLogger.logWarn('USB_FILE_VERIFY_FAILED result=${result.name}');
        controller?.addLine(
          _replyFailureText(usb, result),
          color: failColor,
          number: '4-5',
        );
        controller?.appendStep(usb.terminated, terminated: true);
        return false;
      }

      // 9、收到 FILE_OK，完成导出。
      GlobalLogger.logInfo('USB_FILE_OK');
      controller?.addLine(usb.detailExportComplete, number: '4-5');
      controller?.appendStep(usb.completed);
      return true;
    } catch (e) {
      GlobalLogger.logError('USB_UPLOAD_ERROR $e');
      controller?.addLine(usb.detailError, color: failColor);
      controller?.appendStep(usb.terminated, terminated: true);
      return false;
    } finally {
      disconnectSub?.cancel();
      reader?.stop();
      try {
        await manager.disconnect();
      } catch (e) {
        GlobalLogger.logWarn('USB_DISCONNECT_ERROR $e');
      }
      _usbDisconnected = false;
    }
  }

  /// 处理「USB 已拔出」结果：写步骤条并返回 true 表示应终止本次导出。
  bool _handleUsbDisconnected(
    _UsbReplyResult result,
    StepProgressController? controller,
    Translations$cpds$usbProgress$zh usb,
    Color failColor,
    String number,
  ) {
    if (result != _UsbReplyResult.disconnected) return false;
    controller?.addLine(
      usb.detailDeviceRemoved,
      color: failColor,
      number: number,
    );
    controller?.appendStep(usb.terminated, terminated: true);
    return true;
  }

  /// 等待注钥枪回复，使用显式 [Timer] 实现超时。
  ///
  /// 收到回复或超时后，都会取消本次等待对应的定时器，避免旧回复污染后续流程。
  Future<_UsbReplyResult> _waitReplyResult(
    _UsbLineReader reader, {
    Set<String> successValues = const {'FILE_OK\n'},
  }) async {
    if (_usbDisconnected) return _UsbReplyResult.disconnected;
    String? line;
    try {
      line = await reader.nextLine(timeout: const Duration(seconds: 3));
    } on TimeoutException {
      return _UsbReplyResult.timeout;
    } on _UsbDisconnected {
      return _UsbReplyResult.disconnected;
    } on StateError {
      return _UsbReplyResult.timeout;
    }
    final normalized = line;
    if (successValues.contains(normalized)) return _UsbReplyResult.ok;
    if (normalized == 'ERR:MD5校验失败\n') {
      return _UsbReplyResult.md5Error;
    }
    if (normalized == 'ERR:保存失败\n') {
      return _UsbReplyResult.saveError;
    }
    return _UsbReplyResult.unexpected;
  }

  Future<void> _exportSelected() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
    });
    try {
      await _runExport();
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Future<void> _runExport() async {
    final selectedRows = _allData
        .where((item) => _selectedIds.contains(item.id.toString()))
        .toList();

    if (selectedRows.isEmpty) {
      SimplePopup.error(t.cpds.export.noSelection);
      return;
    }

    // Android 端先申请 USB 权限，通过后再弹「设置密码」。
    if (!await _ensureUsbPermission()) {
      return;
    }

    if (selectedRows.any((item) => item.radioId == null)) {
      SimplePopup.error(t.cpds.export.radioRequired);
      return;
    }
    if (!mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const SetPasswordDialog(),
    );
    if (!mounted) return;
    if (password == null) return;

    final selectedJson = selectedRows.map((item) => item.toJson()).toList();
    GlobalLogger.logInfo(
      'EXPORT_SELECTED ${const JsonEncoder.withIndent('  ').convert(selectedJson)}',
    );
    GlobalLogger.logInfo('EXPORT_PASSWORD $password');

    final controller = StepProgressController([
      t.cpds.exportProgress.stepStart,
      t.cpds.exportProgress.stepPack,
      t.cpds.exportProgress.stepMerge,
      t.cpds.exportProgress.stepEncrypt,
      if (Platform.isAndroid || Platform.isWindows) t.cpds.usbProgress.stepUsb,
    ]);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => StepProgressDialog(
        controller: controller,
        onClose: _closeProgressDialog,
      ),
    );

    final padPath = await _extractAndPrintPackage(
      selectedRows,
      password,
      controller,
    );
    if (!mounted) return;
    if (padPath == null) return;

    if (Platform.isAndroid || Platform.isWindows) {
      await _usbUploadPads([padPath], controller: controller);
    } else {
      // 其它平台无 USB 阶段，直接标记完成。
      controller.appendStep(t.cpds.usbProgress.completed);
    }
  }

  void _closeProgressDialog() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<String?> _extractAndPrintPackage(
    List<KeyLoaderDetailsEntity> selectedRows,
    String password,
    StepProgressController controller,
  ) async {
    const failColor = Color(0xFFF15B64);
    const successColor = Colors.white;
    String? padPath;

    // 步骤 0：开始
    controller.setStep(0);
    controller.addLine(t.cpds.exportProgress.detailStart, number: '0');

    try {
      final uploadPath = await DirectoryManager.instance.getUploadsPath();
      final zipPath = await _findLatestZip(uploadPath);
      if (zipPath == null) {
        SimplePopup.error(t.cpds.export.zipNotFound(path: uploadPath));
        GlobalLogger.logError('EXPORT_ZIP_NOT_FOUND in $uploadPath');
        return null;
      }
      GlobalLogger.logInfo('EXPORT_ZIP $zipPath');

      final outPath = p.withoutExtension(zipPath);
      await extractFileToDisk(
        zipPath,
        outPath,
        password: AppConfig.zipPassword,
      );
      GlobalLogger.logInfo('EXPORT_EXTRACTED $outPath');

      final savePath = await DirectoryManager.instance.getZipCache();
      final resourceEntries = _resourceEntries(outPath);
      final tarPaths = <String>[];

      // 步骤 1：打包（tar）
      controller.addLine(t.cpds.exportProgress.detailStartPack, number: '1');
      for (var i = 0; i < selectedRows.length; i++) {
        final row = selectedRows[i];
        final tarPath = await _exportOneRow(
          row,
          outPath,
          savePath,
          resourceEntries,
        );
        if (tarPath != null) {
          tarPaths.add(tarPath);
          controller.addLine(
            t.cpds.exportProgress.detailPackSuccess(index: i + 1),
            color: successColor,
            number: '${i + 1}',
          );
        } else {
          controller.addLine(
            t.cpds.exportProgress.detailPackFail(index: i + 1),
            color: failColor,
            number: '${i + 1}',
          );
        }
      }
      controller.setStep(1);

      if (tarPaths.isNotEmpty) {
        final zipEntries = tarPaths
            .map((tarPath) => ArchiveEntry(sourcePath: tarPath, innerDir: ''))
            .toList();
        final curTime = parseDateTime(
          DateTime.now(),
        ).replaceAll(RegExp(r'[-:\s]'), '');

        // 步骤 2：整合（ZIP）
        final mergeLineId = controller.addLine(
          t.cpds.exportProgress.detailMerge,
          number: '2',
        );
        String packagePath;
        try {
          packagePath = await FileTools.filesToZipFormPath(
            entries: zipEntries,
            outputPath: savePath,
            zipName: 'UAE_$curTime',
            type: ArchiveEncoderType.zip,
          );
        } catch (_) {
          controller.setLineColor(mergeLineId, failColor);
          rethrow;
        }
        GlobalLogger.logInfo('EXPORT_ZIP_PACKAGE $packagePath');
        controller.setStep(2);

        // 步骤 3：加密（age）
        final encryptLineId = controller.addLine(
          t.cpds.exportProgress.detailEncrypt,
          number: '3',
        );
        try {
          padPath = await _encryptZipToPad(packagePath, password, curTime);
        } catch (_) {
          controller.setLineColor(encryptLineId, failColor);
          rethrow;
        }
        if (padPath != null) {
          controller.setStep(3);
        } else {
          controller.setLineColor(encryptLineId, failColor);
        }

        for (final tarPath in tarPaths) {
          final tarFile = File(tarPath);
          try {
            if (await tarFile.exists()) {
              await tarFile.delete();
              GlobalLogger.logInfo('EXPORT_TAR_DELETED $tarPath');
            }
          } catch (e) {
            GlobalLogger.logWarn('EXPORT_TAR_DELETE_FAILED $tarPath $e');
          }
        }
      }
      return padPath;
    } catch (e, stackTrace) {
      SimplePopup.error(t.cpds.export.failed(error: e.toString()));
      GlobalLogger.logError('EXPORT_FAILED $e\n$stackTrace');
      return null;
    }
  }

  Future<String?> _encryptZipToPad(
    String zipPath,
    String password,
    String curTime,
  ) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      GlobalLogger.logError('EXPORT_ZIP_MISSING_FOR_PAD $zipPath');
      return null;
    }

    final zipBytes = await zipFile.readAsBytes();
    final encryptedBytes = await _encryptWithPassphrase(zipBytes, password);
    final padPath = p.join(p.dirname(zipPath), 'UAE_$curTime.pad');
    await File(padPath).writeAsBytes(encryptedBytes, flush: true);
    GlobalLogger.logInfo('EXPORT_PAD $padPath');
    return padPath;
  }

  Future<Uint8List> _encryptWithPassphrase(
    Uint8List data,
    String password, {
    int workFactor = 15,
  }) async {
    final chunks = await encryptWithPassphrase(
      Stream.value(data),
      passphraseProvider: _FixedPassphrase(password),
      workFactor: workFactor,
    ).toList();

    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<String?> _exportOneRow(
    KeyLoaderDetailsEntity row,
    String outPath,
    String savePath,
    List<ArchiveEntry> resourceEntries,
  ) async {
    final netNodeFilePath = p.join(
      outPath,
      '4_net_node',
      '${row.netNodePackageName}.json',
    );
    final dcFilePath = p.join(
      outPath,
      '3_device_config',
      '${row.dcPackageName}.json',
    );

    final entries = <ArchiveEntry>[...resourceEntries];

    final netNodeFile = File(netNodeFilePath);
    if (await netNodeFile.exists()) {
      final netNodeContent = await netNodeFile.readAsString();
      GlobalLogger.logInfo(
        'EXPORT_NET_NODE[${row.netNodePackageName}] $netNodeContent',
      );
      entries.add(
        ArchiveEntry(sourcePath: netNodeFilePath, innerDir: '4_net_node'),
      );
    } else {
      _notifyMissingFile(
        '${row.netNodePackageName} - ${row.dcPackageName} - '
        '4_net_node/${row.netNodePackageName}.json',
      );
    }

    final dcFile = File(dcFilePath);
    if (await dcFile.exists()) {
      final dcContent = await dcFile.readAsString();
      final dcJson = jsonDecode(dcContent);
      GlobalLogger.logInfo(
        'EXPORT_DEVICE_CONFIG[${row.dcPackageName}] '
        '${const JsonEncoder.withIndent('  ').convert(dcJson)}',
      );
      entries.add(
        ArchiveEntry(sourcePath: dcFilePath, innerDir: '3_device_config'),
      );

      final channels = dcJson['Channels'];
      if (channels is Map) {
        for (final value in channels.values) {
          if (value is! Map) continue;
          final subnet = value['Subnet'];
          if (subnet is! String || subnet.isEmpty) continue;

          final subnetFileName = '$subnet.json';
          final subnetFilePath = p.join(
            outPath,
            '2_radio_subnet',
            subnetFileName,
          );
          if (File(subnetFilePath).existsSync()) {
            entries.add(
              ArchiveEntry(
                sourcePath: subnetFilePath,
                innerDir: '2_radio_subnet',
              ),
            );
          } else {
            _notifyMissingFile(
              '${row.netNodePackageName} - ${row.dcPackageName} - '
              '2_radio_subnet/$subnetFileName',
            );
          }
        }
      }
    } else {
      _notifyMissingFile(
        '${row.netNodePackageName} - ${row.dcPackageName} - '
        '3_device_config/${row.dcPackageName}.json',
      );
    }

    if (entries.isEmpty) {
      GlobalLogger.logWarn('EXPORT_TAR_EMPTY for ${row.netNodePackageName}');
      return null;
    }

    final zipName = '${row.SN ?? ''}-${row.consumer ?? ''}';
    final tarPath = await FileTools.filesToZipFormPath(
      entries: entries,
      outputPath: savePath,
      zipName: zipName,
      type: ArchiveEncoderType.tar,
    );
    GlobalLogger.logInfo('EXPORT_TAR $tarPath');
    return tarPath;
  }

  List<ArchiveEntry> _resourceEntries(String outPath) {
    final resourceDir = Directory(p.join(outPath, '1_resource'));
    if (!resourceDir.existsSync()) return const [];

    final entries = <ArchiveEntry>[];
    for (final entity in resourceDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final relPath = p
          .relative(entity.path, from: outPath)
          .replaceAll('\\', '/');
      final slashIndex = relPath.lastIndexOf('/');
      final innerDir = slashIndex > 0 ? relPath.substring(0, slashIndex) : '';
      entries.add(ArchiveEntry(sourcePath: entity.path, innerDir: innerDir));
    }
    return entries;
  }

  void _notifyMissingFile(String missingPath) {
    SimplePopup.error(t.cpds.export.fileNotFound(path: missingPath));
    GlobalLogger.logWarn('EXPORT_FILE_MISSING $missingPath');
  }

  Future<String?> _findLatestZip(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return null;

    final zipFiles = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.zip')) {
        zipFiles.add(entity);
      }
    }
    if (zipFiles.isEmpty) return null;

    zipFiles.sort((a, b) {
      final timeCompare = b.statSync().modified.compareTo(
        a.statSync().modified,
      );
      if (timeCompare != 0) return timeCompare;
      return b.path.compareTo(a.path);
    });
    return zipFiles.first.path;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataTablePlusThemeProvider(
          theme: _theme,
          child: TableContextualBar(
            selectedCount: _selectedIds.length,
            normalToolbar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  BaseButton(
                    label: t.button.injectEncrypt.export,
                    width: 70,
                    isLoading: _exporting,
                    onPressed: _exporting ? null : () => _exportSelected(),
                  ),
                ],
              ),
            ),
            selectedCountTemplate: '{count} ${t.checkbox.selected}',
            selectAllWidget: OutlinedButton(
              onPressed: _toggleSelectAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: _theme.accentColor,
                side: BorderSide(
                  color: _theme.accentColor.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _allSelected
                    ? t.checkbox.DeselectAll
                    : t.checkbox.SelectAll(count: _pagedData.length),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: _clearSelection,
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: _theme.textSecondaryColor,
                ),
                label: Text(
                  t.button.radioManager.clear,
                  style: TextStyle(
                    fontSize: 13,
                    color: _theme.textSecondaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  side: BorderSide(color: _theme.borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              BaseButton(
                label: t.button.injectEncrypt.export,
                width: 70,
                isLoading: _exporting,
                onPressed: _exporting ? null : () => _exportSelected(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFF353A41)),
        Expanded(
          child: FutureBuilder<List<KeyLoaderDetailsEntity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                GlobalLogger.logError(
                  'load key loader details: ${snapshot.error}',
                );
                return _buildEmpty(context);
              }
              _allData = snapshot.data ?? [];
              return Scrollbar(
                controller: _tableScrollController,
                child: SingleChildScrollView(
                  controller: _tableScrollController,
                  child: DataTablePlusThemeProvider(
                    theme: _theme,
                    child: DataTablePlus<KeyLoaderDetailsEntity>(
                      items: _pagedData,
                      idGetter: (item) => item.id.toString(),
                      selectedIds: _selectedIds,
                      allSelected: _allSelected,
                      showCheckboxes: true,
                      onSelectionChanged: _toggleSelection,
                      onSelectAllChanged: () => _toggleSelectAll(),
                      columns: _buildColumns(context),
                      emptyWidget: _buildEmpty(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        DataTablePlusThemeProvider(
          theme: _theme,
          child: TablePagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _allData.length,
            pageSize: _pageSize,
            pageSizeOptions: const [10, 20, 50, 100],
            onPageSizeChanged: (size) => setState(() {
              _pageSize = size;
              _currentPage = 1;
            }),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemRangeTemplate: '',
          ),
        ),
      ],
    );
  }

  List<ColumnDefinition<KeyLoaderDetailsEntity>> _buildColumns(
    BuildContext context,
  ) {
    final t = Translations.of(context);
    final radios = _radios;

    return [
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.parameterPacket,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.dcPackageName,
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.radio,
        size: const ColumnSize.fixed(160),
        cellBuilder: (item) {
          final usedRadioIds = _allData
              .where((other) => other.id != item.id && other.radioId != null)
              .map((other) => other.radioId!)
              .toSet();
          final radioOptions = radios
              .where(
                (radio) =>
                    !usedRadioIds.contains(radio.id) ||
                    radio.id == item.radioId,
              )
              .map(
                (radio) => DropdownMenuItem<int?>(
                  value: radio.id,
                  child: Text(radio.alias),
                ),
              )
              .toList();
          final hasCurrentRadio = radios.any(
            (radio) => radio.id == item.radioId,
          );
          return SimpleDropdown<int?>(
            hint: t.cpds.saveDialog.selectPlaceholder,
            value: hasCurrentRadio ? item.radioId : null,
            items: radioOptions,
            onChanged: (value) {
              if (item.radioId == value) return;
              item.radioId = value;
              final radio = radios.firstWhere((r) => r.id == value);
              item.consumer = radio.consumer;
              item.location = radio.location;
              item.SN = radio.sn;
              KeyLoadersApi.updateOneDetail(item.id, data: item.toJson());
              setState(() {});
            },
          );
        },
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.consumer,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.consumer ?? '',
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.location,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.location ?? '',
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.SN,
        flex: 1,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.SN ?? '',
        ),
      ),
    ];
  }

  Widget _buildEmpty(BuildContext context) {
    final t = Translations.of(context);
    return Center(
      child: Text(
        t.common.noData,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}

class _FixedPassphrase extends PassphraseProvider {
  final String password;

  _FixedPassphrase(this.password);

  @override
  Future<String> passphrase() async => password;
}

enum _UsbReplyResult {
  ok,
  timeout,
  disconnected,
  md5Error,
  saveError,
  unexpected,
}

class _UsbDisconnected implements Exception {
  const _UsbDisconnected();
}

String _replyFailureText(
  Translations$cpds$usbProgress$zh usb,
  _UsbReplyResult result,
) {
  switch (result) {
    case _UsbReplyResult.md5Error:
      return usb.detailVerifyFail;
    case _UsbReplyResult.saveError:
      return usb.detailVerifySaveFail;
    default:
      return usb.detailError;
  }
}

/// 打印即将发送的 USB 码流（十六进制），以及可读的文本内容（如果可解码且非乱码）。
void _logUsbSend(Uint8List data) {
  final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  final text = _decodePrintableText(data);
  GlobalLogger.logInfo(
    'USB_SEND len=${data.length} hex=[$hex]'
    '${text != null ? ' text="$text"' : ''}',
  );
}

String? _decodePrintableText(Uint8List data) {
  try {
    final text = utf8.decode(data, allowMalformed: false);
    if (text.isEmpty) return null;
    for (final unit in text.codeUnits) {
      final isPrintableAscii = unit >= 0x20 && unit <= 0x7E;
      final isWhitespace = unit == 0x0A || unit == 0x0D || unit == 0x09;
      if (!isPrintableAscii && !isWhitespace) return null;
    }
    return text;
  } catch (_) {
    return null;
  }
}

Future<void> _writeUsb(KeyLoaderUsbBulkManager manager, Uint8List data) async {
  _logUsbSend(data);
  await manager.write(data);
}

Uint8List _u32le(int value) {
  final data = ByteData(4);
  data.setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u64le(int value) {
  final data = ByteData(8);
  data.setUint64(0, value, Endian.little);
  return data.buffer.asUint8List();
}

/// 按 `\n` 分帧的 USB 行读取器，用于按协议逐行等待设备回复。
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
    _buffer.addAll(data);
    while (true) {
      final idx = _buffer.indexOf(0x0A); // \n
      if (idx < 0) break;
      final lineBytes = _buffer.sublist(0, idx);
      _buffer.removeRange(0, idx + 1);
      var content = utf8.decode(lineBytes, allowMalformed: true);
      if (content.endsWith('\r')) {
        content = content.substring(0, content.length - 1);
      }
      if (content.trim().isEmpty) continue;
      final line = '$content\n';
      _deliver(line);
    }
  }

  void _deliver(String line) {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).deliver(line);
    } else {
      _pending.add(line);
    }
  }

  /// 以 [error] 立即失败所有正在等待的行，用于设备拔出时中断等待。
  void abort(Object error) {
    for (final waiter in _waiters) {
      waiter.fail(error);
    }
    _waiters.clear();
  }

  Future<String> nextLine({Duration timeout = const Duration(seconds: 10)}) {
    if (_pending.isNotEmpty) {
      return Future.value(_pending.removeAt(0));
    }
    final pending = _PendingLine();
    _waiters.add(pending);
    pending.start(
      timeout,
      onTimeout: () {
        _waiters.remove(pending);
      },
    );
    return pending.completer.future;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _buffer.clear();
    _pending.clear();
    for (final waiter in _waiters) {
      waiter.fail(StateError('reader stopped'));
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
    if (!completer.isCompleted) {
      completer.complete(line);
    }
  }

  void fail(Object error) {
    _timer?.cancel();
    _timer = null;
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }
}
