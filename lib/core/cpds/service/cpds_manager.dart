import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:path/path.dart' as path;

import '../cpds_exception.dart';
import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';
import '../parser/cpds_package_parser.dart';
import '../protocol/cpds_udp_transport.dart';
import '../session/cpds_session_machine.dart';
import '../session/cpds_session_runner.dart';
import 'cpds_network_interfaces.dart';

class CpdsManager {
  CpdsManager._();

  static final CpdsManager instance = CpdsManager._();

  final StreamController<CpdsApplicationState> _stateController =
      StreamController<CpdsApplicationState>.broadcast();

  String? _uploadPath;
  String _uploadName = '';
  int _uploadSize = 0;
  CpdsPackage? _package;
  String _selectedNodeId = '';
  String _interfaceName = '';
  CpdsSessionView? _session;
  CpdsSessionMachine? _machine;
  CpdsSessionRunner? _runner;
  CpdsUdpTransport? _transport;
  StreamController<bool>? _discoveryDecisionController;
  bool _active = false;

  Stream<CpdsApplicationState> get stateStream => _stateController.stream;

  CpdsApplicationState state() {
    return CpdsApplicationState(
      upload: _uploadPath == null
          ? null
          : CpdsUpload(fileName: _uploadName, fileSize: _uploadSize),
      package: _package,
      selectedNodeId: _selectedNodeId,
      canDistribute:
          _uploadPath != null &&
          _package != null &&
          _selectedNodeId.isNotEmpty &&
          _interfaceName.isNotEmpty &&
          !_active,
      active: _active,
      session: _session,
    );
  }

  Future<CpdsApplicationState> uploadPackage(
    String fileName,
    Uint8List bytes,
  ) async {
    _validateUploadFileName(fileName);
    if (bytes.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'emptyFile'},
        message: 'empty file',
      );
    }
    if (bytes.length > CpdsPackageParser.maxPackageBytes) {
      throw CpdsException(
        CpdsErrorCode.packageTooLarge,
        params: {'actual': bytes.length, 'limit': CpdsPackageParser.maxPackageBytes},
        message: 'package too large',
      );
    }

    final uploadDir = await DirectoryManager.instance.getUploadsPath();
    final random = Random.secure();
    final suffix = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final newPath = path.join(uploadDir, 'upload-$suffix.zip');
    final file = File(newPath);
    await file.writeAsBytes(bytes, flush: true);

    final oldPath = _uploadPath;
    _uploadPath = newPath;
    _uploadName = fileName;
    _uploadSize = bytes.length;
    _package = null;
    _selectedNodeId = '';
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    unawaited(
      Shared.saveCpdsLastUpload(path: newPath, name: fileName),
    );
    unawaited(Shared.saveCpdsSelectedNode(''));
    if (oldPath != null && oldPath != newPath) {
      _deleteQuietly(File(oldPath));
    }
    _notify();
    return state();
  }

  Future<CpdsApplicationState> parsePackage() async {
    final uploadPath = _uploadPath;
    if (uploadPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'upload'},
        message: 'no uploaded package',
      );
    }
    final package = await CpdsPackageParser.parseFile(
      uploadPath,
      _uploadName,
      password: AppConfig.zipPassword,
    );
    _package = package;
    _selectedNodeId = '';
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    _notify();
    return state();
  }

  Future<CpdsApplicationState> parseSourcePath(String sourcePath) async {
    final type = FileSystemEntity.typeSync(sourcePath, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      final package = await CpdsPackageParser.parseDirectory(
        Directory(sourcePath),
        path.basename(sourcePath),
      );
      _uploadPath = null;
      _uploadName = path.basename(sourcePath);
      _uploadSize = 0;
      _package = package;
      _selectedNodeId = '';
      _session = null;
      _machine = null;
      _runner = null;
      _active = false;
      _notify();
      return state();
    }
    if (type == FileSystemEntityType.file) {
      final file = File(sourcePath);
      if (!await file.exists()) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'file', 'path': sourcePath},
          message: 'file does not exist',
        );
      }
      final name = path.basename(sourcePath);
      _validateUploadFileName(name);
      final stat = await file.stat();
      if (stat.size > CpdsPackageParser.maxPackageBytes) {
        throw CpdsException(
          CpdsErrorCode.packageTooLarge,
          params: {'actual': stat.size, 'limit': CpdsPackageParser.maxPackageBytes},
          message: 'package too large',
        );
      }
      _uploadPath = sourcePath;
      _uploadName = name;
      _uploadSize = stat.size;
      _package = null;
      _selectedNodeId = '';
      _session = null;
      _machine = null;
      _runner = null;
      _active = false;
      return parsePackage();
    }
    throw CpdsException(
      CpdsErrorCode.invalidPackage,
      params: {'field': 'sourcePath', 'path': sourcePath},
      message: 'source path is not a file or directory',
    );
  }

  CpdsApplicationState selectNode(String nodeId) {
    final package = _package;
    if (package == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'no parsed package',
      );
    }
    if (!package.nodes.any((node) => node.id == nodeId)) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeId', 'actual': nodeId},
        message: 'unknown node',
      );
    }
    _selectedNodeId = nodeId;
    unawaited(Shared.saveCpdsSelectedNode(nodeId));
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    _notify();
    return state();
  }

  Future<List<CpdsNetworkInterface>> listNetworkInterfaces() async {
    return CpdsNetworkInterfaceService.listWiredInterfaces();
  }

  Future<CpdsApplicationState> selectNetworkInterface(String name) async {
    if (name.isNotEmpty) {
      final interfaces = await listNetworkInterfaces();
      if (!interfaces.any((item) => item.name == name)) {
        throw CpdsException(
          CpdsErrorCode.networkInterfaceError,
          params: {'interface': name},
          message: 'network interface is unavailable',
        );
      }
    }
    _interfaceName = name;
    _notify();
    return state();
  }

  String get selectedInterfaceName => _interfaceName;

  Future<void> restoreLastPackage() async {
    final uploadPath = Shared.getCpdsLastSourcePath();
    final uploadName = Shared.getCpdsLastUploadName();
    if (uploadPath == null || uploadPath.isEmpty) return;
    final file = File(uploadPath);
    if (!file.existsSync()) return;

    _uploadPath = uploadPath;
    _uploadName = uploadName ?? path.basename(uploadPath);
    _uploadSize = file.lengthSync();
    _notify();

    try {
      final package = await CpdsPackageParser.parseFile(
        uploadPath,
        _uploadName,
        password: AppConfig.zipPassword,
      );
      _package = package;
      final lastNode = Shared.getCpdsLastSelectedNode() ?? '';
      if (lastNode.isNotEmpty &&
          package.nodes.any((node) => node.id == lastNode)) {
        _selectedNodeId = lastNode;
      } else {
        _selectedNodeId = '';
      }
    } catch (_) {
      _package = null;
      _selectedNodeId = '';
    }
    _notify();
  }

  Future<void> startDistribution() async {
    if (_active) {
      throw CpdsException(
        CpdsErrorCode.busy,
        message: 'distribution already running',
      );
    }
    final uploadPath = _uploadPath;
    final package = _package;
    if (uploadPath == null || package == null || _selectedNodeId.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'distributionInput'},
        message: 'distribution input is incomplete',
      );
    }
    if (_interfaceName.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.networkInterfaceError,
        message: 'network interface is not selected',
      );
    }

    final interfaces = await listNetworkInterfaces();
    CpdsNetworkInterface? selectedInterface;
    for (final item in interfaces) {
      if (item.name == _interfaceName) {
        selectedInterface = item;
        break;
      }
    }
    if (selectedInterface == null) {
      throw CpdsException(
        CpdsErrorCode.networkInterfaceError,
        params: {'interface': _interfaceName},
      );
    }

    CpdsNode? node;
    for (final item in package.nodes) {
      if (item.id == _selectedNodeId) {
        node = item;
        break;
      }
    }
    if (node == null || node.devices.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeDevices'},
      );
    }

    final bytes = await File(uploadPath).readAsBytes();
    final sha = sha256.convert(bytes).bytes;
    final sessionId = _randomUuid();
    final machine = CpdsSessionMachine(
      nodeId: _selectedNodeId,
      expected: node.devices,
    );
    machine.begin(sessionId);
    final transport = CpdsUdpTransport();
    await transport.init(interfaceIp: selectedInterface.ipv4);
    final decisionController = StreamController<bool>.broadcast();
    final runner = CpdsSessionRunner(
      transport: transport,
      machine: machine,
      input: CpdsPackageInput(
        fileName: _uploadName,
        filePath: uploadPath,
        fileSize: _uploadSize,
        sha256: Uint8List.fromList(sha),
        expandedSize: package.expandedSize,
        requiredWorkspace: package.requiredWorkspace,
      ),
      discoveryDecision: decisionController.stream,
      onUpdate: (view) {
        _session = view;
        _notify();
      },
    );

    _machine = machine;
    _transport = transport;
    _runner = runner;
    _discoveryDecisionController = decisionController;
    _session = machine.view();
    _active = true;
    _notify();

    unawaited(
      _runDistribution(
        runner,
        machine,
        transport,
        decisionController,
      ),
    );
  }

  Future<void> _runDistribution(
    CpdsSessionRunner runner,
    CpdsSessionMachine machine,
    CpdsUdpTransport transport,
    StreamController<bool> decisionController,
  ) async {
    try {
      await runner.run();
    } catch (_) {
      machine.failActive(
        'TRANSFER',
        CpdsErrorCode.networkInterfaceError,
      );
    } finally {
      _session = machine.view();
      _active = false;
      _runner = null;
      _machine = null;
      await decisionController.close();
      if (_discoveryDecisionController == decisionController) {
        _discoveryDecisionController = null;
      }
      await transport.dispose();
      _transport = null;
      _notify();
    }
  }

  Future<void> resolveDiscoveryMismatch(String sessionId, bool proceed) async {
    final machine = _machine;
    final controller = _discoveryDecisionController;
    final session = _session;
    if (machine == null ||
        controller == null ||
        session?.sessionId != sessionId ||
        machine.state != CpdsActiveState.awaitingDiscoveryConfirmation) {
      throw CpdsException(CpdsErrorCode.busy);
    }
    controller.add(proceed);
  }

  void _validateUploadFileName(String name) {
    final base = path.basename(name);
    if (name.isEmpty ||
        base != name ||
        name.contains('/') ||
        name.contains(r'\') ||
        name.contains('..') ||
        path.extension(name).toLowerCase() != '.zip') {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'fileName', 'path': name},
        message: 'invalid file name',
      );
    }
  }

  void _notify() {
    if (!_stateController.isClosed) {
      _stateController.add(state());
    }
  }

  void _deleteQuietly(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Future<void> dispose() async {
    await _runner?.cancel();
    await _transport?.dispose();
    await _discoveryDecisionController?.close();
    await _stateController.close();
  }
}

Uint8List _randomUuid() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  return bytes;
}
