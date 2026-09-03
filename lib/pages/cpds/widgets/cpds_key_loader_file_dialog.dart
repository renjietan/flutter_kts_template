import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dage/dage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/service/cpds_manager.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_factory.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_manager.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:path/path.dart' as p;

/// 注钥枪文件列表弹窗。
///
/// 步骤：连接注钥枪 → 获取文件列表 → 文件选择 → 密码校验 → 下载 → 完成。
class CpdsKeyLoaderFileDialog extends StatefulWidget {
  const CpdsKeyLoaderFileDialog({super.key});

  @override
  State<CpdsKeyLoaderFileDialog> createState() =>
      _CpdsKeyLoaderFileDialogState();
}

enum _CpdsStep {
  connect,
  ready,
  list,
  select,
  password,
  download,
  decrypt,
  parse,
  complete,
}

enum _StepStatus { pending, active, passed, error, done }

class _CpdsKeyLoaderFileDialogState extends State<CpdsKeyLoaderFileDialog> {
  _CpdsStep _step = _CpdsStep.connect;
  List<String> _files = const [];
  String? _selectedFile;
  String? _error;
  bool _listFailed = false;
  bool _readyFailed = false;

  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _passwordError;
  bool _verifying = false;
  bool _decryptOk = false;
  bool _decryptFailed = false;
  bool _downloading = false;
  String? _downloadError;
  bool _downloadFailed = false;
  bool _parseFailed = false;
  String? _parseError;
  int _progress = 0;
  int _progressMax = 0;

  KeyLoaderUsbBulkManager? _manager;
  _UsbLineReader? _reader;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  @override
  void dispose() {
    _reader?.stop();
    _passwordController.dispose();
    final manager = _manager;
    if (manager != null) {
      unawaited(manager.disconnect());
    }
    super.dispose();
  }

  Future<void> _run() async {
    final t = Translations.of(context);
    final manager = getKeyLoaderUsbBulkManager();
    _manager = manager;

    // 步骤 1：连接注钥枪。
    setState(() {
      _step = _CpdsStep.connect;
      _error = null;
    });
    final connected = await manager.connect();
    if (!mounted) return;
    if (!connected) {
      setState(() {
        _error = t.cpds.keyLoaderConnectFailed;
      });
      return;
    }

    // 创建行读取器（后续就绪/列表/密码/下载复用）。
    final reader = _UsbLineReader(manager.listenData())..start();
    _reader = reader;

    // 步骤 2：就绪（PAD_LIGHT → FILE_OK）。
    setState(() {
      _step = _CpdsStep.ready;
    });
    await _writeUsb(
      manager,
      Uint8List.fromList(utf8.encode('PAD_LIGHT\n')),
    );
    try {
      final readyLine = await reader.nextLine(
        timeout: const Duration(seconds: 3),
      );
      if (!mounted) return;
      if (readyLine != 'FILE_OK\n') {
        setState(() {
          _error = t.cpds.keyLoaderReadyTimeout;
          _readyFailed = true;
        });
        return;
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = t.cpds.keyLoaderReadyTimeout;
        _readyFailed = true;
      });
      return;
    } on StateError {
      // 弹窗已关闭。
      return;
    }

    // 步骤 3：获取文件列表。
    setState(() {
      _step = _CpdsStep.list;
    });
    await _writeUsb(
      manager,
      Uint8List.fromList(utf8.encode('PAD_LIST\n')),
    );

    String? line;
    try {
      line = await reader.nextLine(timeout: const Duration(seconds: 3));
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = t.cpds.keyLoaderListTimeout;
        _listFailed = true;
      });
      return;
    } on StateError {
      // 弹窗已关闭（reader 已 stop），无需处理。
      return;
    }

    if (!mounted) return;
    setState(() {
      if (line == 'ERR\n') {
        _error = t.cpds.keyLoaderListError;
        _listFailed = true;
        _files = const [];
      } else {
        if (line == 'NONE\n') {
          _files = const [];
        } else {
          final content = line!.substring(0, line.length - 1);
          _files = content
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
        _step = _CpdsStep.select;
      }
    });
  }

  Future<void> _finish(String? result) async {
    _reader?.stop();
    final manager = _manager;
    if (manager != null) {
      await manager.disconnect();
    }
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _goNext() {
    setState(() {
      _step = _CpdsStep.password;
      _passwordError = null;
    });
  }

  void _goPrev() {
    _reader?.abort(StateError('cancelled'));
    setState(() {
      _step = _CpdsStep.select;
      _passwordError = null;
      _verifying = false;
    });
  }

  Future<void> _submitPassword() async {
    if (_verifying) return;
    final t = Translations.of(context);
    final password = _passwordController.text;
    if (password.trim().isEmpty) {
      setState(() {
        _passwordError = t.cpds.setPassword.required;
        _decryptFailed = true;
      });
      return;
    }
    final fileName = _selectedFile;
    final manager = _manager;
    final reader = _reader;
    if (fileName == null || manager == null || reader == null) return;

    setState(() {
      _passwordError = null;
      _verifying = true;
      _decryptFailed = false;
    });

    // 1. 发送 PAD_DECRYPT，等待 READY。
    await _writeUsb(
      manager,
      Uint8List.fromList(utf8.encode('PAD_DECRYPT\n')),
    );

    try {
      final readyLine = await reader.nextLine(
        timeout: const Duration(seconds: 3),
      );
      if (!mounted || !_verifying) return;
      if (readyLine != 'READY\n') {
        setState(() {
          _verifying = false;
          _decryptFailed = true;
          _passwordError = t.cpds.keyLoaderDecryptFail;
        });
        return;
      }
    } on TimeoutException {
      if (!mounted || !_verifying) return;
      setState(() {
        _verifying = false;
        _decryptFailed = true;
        _passwordError = t.cpds.keyLoaderDecryptTimeout;
      });
      return;
    } on StateError {
      // 已取消或弹窗关闭。
      return;
    }

    // 2. 依次发送：文件名长度、文件名、密码长度、密码（不等待中间回复）。
    final fileNameBytes = utf8.encode(fileName);
    final passwordBytes = utf8.encode(password);
    await _writeUsb(manager, _u32le(fileNameBytes.length));
    await _writeUsb(manager, Uint8List.fromList(fileNameBytes));
    await _writeUsb(manager, _u32le(passwordBytes.length));
    await _writeUsb(manager, Uint8List.fromList(passwordBytes));

    // 3. 等待解密结果。
    try {
      final line = await reader.nextLine(
        timeout: const Duration(seconds: 10),
      );
      if (!mounted || !_verifying) return;
      _handleDecryptReply(line);
    } on TimeoutException {
      if (!mounted || !_verifying) return;
      setState(() {
        _verifying = false;
        _decryptFailed = true;
        _passwordError = t.cpds.keyLoaderDecryptTimeout;
      });
    } on StateError {
      // 已取消或弹窗关闭。
    }
  }

  void _handleDecryptReply(String line) {
    final t = Translations.of(context);
    if (line == 'DECRYPT_OK\n') {
      setState(() {
        _verifying = false;
        _decryptOk = true;
        _step = _CpdsStep.download;
      });
      return;
    }
    if (line == 'DECRYPT_CLEARED\n') {
      setState(() {
        _verifying = false;
        _decryptFailed = true;
        _passwordError = t.cpds.keyLoaderDecryptCleared;
      });
      return;
    }
    if (line == 'DECRYPT_ERR\n') {
      setState(() {
        _verifying = false;
        _decryptFailed = true;
        _passwordError = t.cpds.keyLoaderDecryptErr;
      });
      return;
    }
    if (line.startsWith('DECRYPT_FAIL:') && line.endsWith('\n')) {
      final n = line.substring('DECRYPT_FAIL:'.length, line.length - 1);
      setState(() {
        _verifying = false;
        _decryptFailed = true;
        _passwordError = t.cpds.keyLoaderDecryptFailRemaining(n: n);
      });
      return;
    }
    setState(() {
      _verifying = false;
      _decryptFailed = true;
      _passwordError = t.cpds.keyLoaderDecryptFail;
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    final t = Translations.of(context);
    final fileName = _selectedFile;
    final manager = _manager;
    final reader = _reader;
    if (fileName == null || manager == null || reader == null) return;

    setState(() {
      _downloading = true;
      _downloadError = null;
      _progress = 0;
      _progressMax = 0;
      _downloadFailed = false;
    });

    // 1. 发送 PAD_DOWN，等待 READY。
    await _writeUsb(
      manager,
      Uint8List.fromList(utf8.encode('PAD_DOWN\n')),
    );
    try {
      final readyLine = await reader.nextLine(
        timeout: const Duration(seconds: 3),
      );
      if (!mounted) return;
      if (readyLine != 'READY\n') {
        setState(() {
          _downloading = false;
          _downloadError = t.cpds.keyLoaderDecryptFail;
        });
        return;
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloadError = t.cpds.keyLoaderDecryptTimeout;
      });
      return;
    } on StateError {
      return;
    }

    // READY 已确认，后续为二进制码流下载，停止行读取器避免缓存二进制数据。
    _reader?.stop();
    _reader = null;

    // 2-3. 发送文件名长度 + 文件名。
    final fileNameBytes = utf8.encode(fileName);
    await _writeUsb(manager, _u32le(fileNameBytes.length));
    await _writeUsb(manager, Uint8List.fromList(fileNameBytes));

    // 4. 接收并组装文件（长度头 + 内容 + MD5）。
    final received = await _receiveFile(manager);
    if (!mounted) return;
    if (received == null) {
      setState(() {
        _downloading = false;
        _downloadError = t.cpds.keyLoaderFileCorrupted;
      });
      return;
    }

    // 5. 收到 MD5 后，发送 FILE_OK（无论校验结果，不等待回复），同时进行 MD5 校验。
    await _writeUsb(
      manager,
      Uint8List.fromList(utf8.encode('FILE_OK\n')),
    );
    final computedMd5 = md5.convert(received.content).bytes;
    if (!_listEquals(computedMd5, received.md5)) {
      setState(() {
        _downloading = false;
        _downloadFailed = true;
        _downloadError = t.cpds.keyLoaderVerifyFailed;
      });
      return;
    }

    // 6. 存储为 .pad（zipCache）。
    final baseName = p.basenameWithoutExtension(fileName);
    final padPath = p.join(
      await DirectoryManager.instance.getZipCache(),
      '$baseName.pad',
    );
    await File(padPath).writeAsBytes(received.content, flush: true);
    GlobalLogger.logInfo('KEY_LOADER_PAD $padPath');

    setState(() {
      _downloading = false;
      _step = _CpdsStep.decrypt;
    });

    // 7. 解密 .pad → zip（age），存储到 uploads 并同步状态。
    try {
      final zipBytes = await _decryptWithPassphrase(
        received.content,
        _passwordController.text,
      );
      final zipName = '$baseName.zip';
      await CpdsManager.instance.uploadPackage(zipName, zipBytes);
      GlobalLogger.logInfo('KEY_LOADER_ZIP $zipName');
      // 解密结果写入 uploads 后，清空【注钥管理】页面数据。
      _clearKeyLoaderData();
    } catch (e) {
      GlobalLogger.logError('KEY_LOADER_DECRYPT_FAILED $e');
      if (!mounted) return;
      setState(() {
        _downloadError = t.cpds.keyLoaderDecryptFailed;
      });
      return;
    }

    // 8. 解析（清空注钥数据之后执行）。
    if (!mounted) return;
    setState(() {
      _step = _CpdsStep.parse;
      _parseFailed = false;
      _parseError = null;
    });
    try {
      await CpdsManager.instance.parsePackage();
      if (!mounted) return;
      setState(() {
        _step = _CpdsStep.complete;
      });
    } catch (e) {
      GlobalLogger.logError('KEY_LOADER_PARSE_FAILED $e');
      if (!mounted) return;
      setState(() {
        _parseFailed = true;
        _parseError = e.toString();
      });
    }
  }

  void _clearKeyLoaderData() {
    DatabaseManager.instance.removeAll<KeyLoaderDetailsEntity>();
    DatabaseManager.instance.removeAll<KeyLoadersEntity>();
  }

  Future<({Uint8List content, Uint8List md5})?> _receiveFile(
    KeyLoaderUsbBulkManager manager,
  ) async {
    final done = Completer<({Uint8List content, Uint8List md5})?>();
    final buffer = <int>[];
    int? totalLen;
    StreamSubscription<Uint8List>? sub;

    sub = manager.listenData().listen((chunk) {
      if (!mounted) {
        if (!done.isCompleted) done.complete(null);
        return;
      }
      if (chunk.isEmpty) return;
      _logUsbRecv(chunk);
      buffer.addAll(chunk);

      if (totalLen == null && buffer.length >= 8) {
        final header = ByteData.sublistView(
          Uint8List.fromList(buffer.sublist(0, 8)),
        );
        totalLen = header.getUint64(0, Endian.little);
        setState(() {
          _progressMax = (totalLen! + 511) ~/ 512;
          _progress = 0;
        });
      }

      if (totalLen != null) {
        final contentReceived = buffer.length - 8;
        final capped = contentReceived > totalLen!
            ? totalLen!
            : contentReceived;
        final progress = (capped + 511) ~/ 512;
        if (progress != _progress) {
          setState(() {
            _progress = progress;
          });
        }
      }

      if (totalLen != null && buffer.length >= 8 + totalLen! + 16) {
        final content = Uint8List.fromList(buffer.sublist(8, 8 + totalLen!));
        final md5 = Uint8List.fromList(
          buffer.sublist(8 + totalLen!, 8 + totalLen! + 16),
        );
        if (!done.isCompleted) {
          done.complete((content: content, md5: md5));
        }
      }
    });

    final result = await done.future;
    await sub.cancel();
    return result;
  }

  Future<Uint8List> _decryptWithPassphrase(
    Uint8List data,
    String password,
  ) async {
    final chunks = await decryptWithPassphrase(
      Stream.value(data),
      passphraseProvider: _FixedPassphrase(password),
    ).toList();
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  List<String> _labels(Translations t) {
    return [
      t.cpds.keyLoaderStepConnect,
      t.cpds.keyLoaderStepReady,
      t.cpds.keyLoaderStepList,
      _selectedFile != null
          ? t.cpds.keyLoaderStepSelected
          : t.cpds.keyLoaderStepSelect,
      t.cpds.keyLoaderStepPassword,
      t.cpds.keyLoaderStepDownload,
      t.cpds.keyLoaderStepDecrypt,
      t.cpds.keyLoaderStepParse,
      t.cpds.keyLoaderStepComplete,
    ];
  }

  List<_StepStatus> _computeStepStatuses() {
    final s = _step.index;
    return [
      s == _CpdsStep.connect.index
          ? _StepStatus.active
          : _StepStatus.pending,
      _readyFailed
          ? _StepStatus.error
          : (s == _CpdsStep.ready.index
              ? _StepStatus.active
              : _StepStatus.pending),
      _listFailed
          ? _StepStatus.error
          : (s == _CpdsStep.list.index
              ? _StepStatus.active
              : _StepStatus.pending),
      s == _CpdsStep.select.index
          ? _StepStatus.active
          : _StepStatus.pending,
      _decryptFailed
          ? _StepStatus.error
          : (s == _CpdsStep.password.index
              ? _StepStatus.active
              : _StepStatus.pending),
      _downloadFailed
          ? _StepStatus.error
          : (s == _CpdsStep.download.index
              ? _StepStatus.active
              : _StepStatus.pending),
      s == _CpdsStep.decrypt.index
          ? _StepStatus.active
          : _StepStatus.pending,
      _parseFailed
          ? _StepStatus.error
          : (s == _CpdsStep.parse.index
              ? _StepStatus.active
              : _StepStatus.pending),
      s >= _CpdsStep.complete.index ? _StepStatus.done : _StepStatus.pending,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth * 0.9).clamp(0.0, 960.0);
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      title: Text(
        t.cpds.browseSourceKeyLoader,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KeyLoaderStepStrip(
              labels: _labels(t),
              statuses: _computeStepStatuses(),
              activeIndex: _step.index,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: _buildContentArea(t)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _finish(null),
          child: Text(
            t.tips.cancel,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        if (_step == _CpdsStep.select && _selectedFile != null)
          FilledButton(
            onPressed: _goNext,
            child: Text(t.cpds.keyLoaderNext),
          ),
        if (_step == _CpdsStep.password)
          TextButton(
            onPressed: _verifying ? null : _goPrev,
            child: Text(
              t.cpds.keyLoaderPrev,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        if (_step == _CpdsStep.download && _decryptOk)
          FilledButton(
            onPressed: _downloading ? null : _download,
            child: Text(t.cpds.keyLoaderStepDownload),
          ),
      ],
    );
  }

  Widget _buildContentArea(Translations t) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFF15B64), fontSize: 13),
        ),
      );
    }
    if (_step == _CpdsStep.connect ||
        _step == _CpdsStep.ready ||
        _step == _CpdsStep.list) {
      final label = switch (_step) {
        _CpdsStep.connect => t.cpds.keyLoaderStepConnect,
        _CpdsStep.ready => t.cpds.keyLoaderStepReady,
        _ => t.cpds.keyLoaderStepList,
      };
      return _buildProgress(label);
    }
    if (_step == _CpdsStep.password) {
      return _buildPassword(t);
    }
    if (_step == _CpdsStep.download) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedFile ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (_progressMax > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_progress / _progressMax).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFF282D33),
              color: const Color(0xFF00A2E9),
            ),
            const SizedBox(height: 6),
            Text(
              '$_progress / $_progressMax',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_downloadError != null) ...[
            const SizedBox(height: 12),
            Text(
              _downloadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFF15B64), fontSize: 13),
            ),
          ],
        ],
      );
    }
    if (_step == _CpdsStep.decrypt) {
      if (_downloadError != null) {
        return Center(
          child: Text(
            _downloadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFF15B64), fontSize: 13),
          ),
        );
      }
      return _buildProgress(t.cpds.keyLoaderStepDecrypt);
    }
    if (_step == _CpdsStep.parse) {
      if (_parseFailed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.cpds.keyLoaderParseFailed,
                style: const TextStyle(color: Color(0xFFF15B64), fontSize: 14),
              ),
              if (_parseError != null && _parseError!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _parseError!,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF15B64),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }
      return _buildProgress(t.cpds.keyLoaderStepParse);
    }
    if (_step == _CpdsStep.complete) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 48,
              color: Color(0xFF1B8252),
            ),
            const SizedBox(height: 10),
            Text(
              t.cpds.keyLoaderSuccess,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Text(
          t.cpds.keyLoaderListEmpty,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }
    return ListView(
      children: [
        for (final file in _files)
          _FileOption(
            name: file,
            selected: _selectedFile == file,
            onTap: () {
              setState(() {
                _selectedFile = file;
              });
            },
          ),
      ],
    );
  }

  Widget _buildProgress(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00A2E9),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPassword(Translations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_verifying,
                onSubmitted: (_) => _submitPassword(),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: t.cpds.setPassword.placeholder,
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: Colors.white54,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF282D33),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF353A41)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF353A41)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF00A2E9)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _verifying ? null : _submitPassword,
              child: Text(t.tips.ok),
            ),
          ],
        ),
        if (_verifying) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00A2E9),
              ),
            ),
          ),
        ],
        if (_passwordError != null) ...[
          const SizedBox(height: 8),
          Text(
            _passwordError!,
            style: const TextStyle(color: Color(0xFFF15B64), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _KeyLoaderStepStrip extends StatelessWidget {
  const _KeyLoaderStepStrip({
    required this.labels,
    required this.statuses,
    required this.activeIndex,
  });

  final List<String> labels;
  final List<_StepStatus> statuses;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14191F),
        border: Border.all(color: const Color(0xFF353A41)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            _KeyLoaderStep(
              index: index,
              label: labels[index],
              status: statuses[index],
            ),
            if (index != labels.length - 1)
              _KeyLoaderStepLine(
                passed: index < activeIndex,
              ),
          ],
        ],
      ),
    );
  }
}

class _KeyLoaderStep extends StatelessWidget {
  const _KeyLoaderStep({
    required this.index,
    required this.label,
    required this.status,
  });

  final int index;
  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color fillColor;
    final Color numberColor;
    final Color textColor;
    switch (status) {
      case _StepStatus.done:
        borderColor = const Color(0xFF1B8252);
        fillColor = const Color(0xFF1B8252);
        numberColor = Colors.white;
        textColor = Colors.white;
      case _StepStatus.active:
        borderColor = const Color(0xFF00A2E9);
        fillColor = const Color(0xFF004098);
        numberColor = Colors.white;
        textColor = Colors.white;
      case _StepStatus.passed:
        borderColor = const Color(0xFF00A2E9);
        fillColor = Colors.transparent;
        numberColor = const Color(0xFF0CB5FF);
        textColor = const Color(0xFF0CB5FF);
      case _StepStatus.error:
        borderColor = const Color(0xFFF15B64);
        fillColor = Colors.transparent;
        numberColor = const Color(0xFFF15B64);
        textColor = const Color(0xFFF15B64);
      case _StepStatus.pending:
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
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 10, color: numberColor),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyLoaderStepLine extends StatelessWidget {
  const _KeyLoaderStepLine({required this.passed});

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

class _FileOption extends StatelessWidget {
  const _FileOption({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0E1114) : Colors.transparent,
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
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

Future<void> _writeUsb(
  KeyLoaderUsbBulkManager manager,
  Uint8List data,
) async {
  GlobalLogger.logInfo(
    'USB_SEND text="${utf8.decode(data, allowMalformed: true)}"',
  );
  await manager.write(data);
}

Uint8List _u32le(int value) {
  final data = ByteData(4);
  data.setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

void _logUsbRecv(Uint8List data) {
  final hex = data
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ');
  GlobalLogger.logInfo('USB_RECV len=${data.length} hex=[$hex]');
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _FixedPassphrase extends PassphraseProvider {
  _FixedPassphrase(this.password);

  final String password;

  @override
  Future<String> passphrase() async => password;
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

  void abort(Object error) {
    for (final waiter in _waiters) {
      waiter.fail(error);
    }
    _waiters.clear();
  }

  Future<String> nextLine({Duration timeout = const Duration(seconds: 3)}) {
    if (_pending.isNotEmpty) {
      return Future.value(_pending.removeAt(0));
    }
    final pending = _PendingLine();
    _waiters.add(pending);
    pending.start(timeout, onTimeout: () {
      _waiters.remove(pending);
    });
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
