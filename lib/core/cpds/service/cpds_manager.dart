import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dage/dage.dart';
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
import 'cpds_disk_space.dart';
import 'cpds_network_interfaces.dart';

class CpdsManager {
  CpdsManager._();

  static final CpdsManager instance = CpdsManager._();

  final StreamController<CpdsApplicationState> _stateController =
      StreamController<CpdsApplicationState>.broadcast();

  String? _uploadPath;
  String? _pcSourcePath;
  String? _pcPassword;
  String _uploadName = '';
  String _transferFileName = '';
  int _uploadSize = 0;
  CpdsPackage? _package;
  Uint8List? _packageSha256;
  String _selectedNodeId = '';
  String _selectedFutureWarriorUnitId = '';
  String _interfaceName = '';
  List<CpdsNetworkInterface> _interfaces = const [];
  bool _interfacesLoading = false;
  bool _automaticInterface = false;
  CpdsSessionView? _session;
  CpdsSessionMachine? _machine;
  CpdsSessionRunner? _runner;
  CpdsUdpTransport? _transport;
  StreamController<bool>? _discoveryDecisionController;
  bool _active = false;
  bool _showCancel = false;

  Stream<CpdsApplicationState> get stateStream => _stateController.stream;

  String? get uploadPath => _uploadPath;
  bool get hasPackage => _package != null;
  bool get showCancel => _showCancel;

  /// 标记当前是否处于「启动自动加载密码框」阶段（该密码框可取消）。
  /// 供密码框据此决定是否显示【取消】按钮。
  void setShowCancel(bool value) {
    if (_showCancel == value) return;
    _showCancel = value;
    _notify();
  }

  CpdsApplicationState state() {
    return CpdsApplicationState(
      upload: _uploadPath == null
          ? null
          : CpdsUpload(fileName: _uploadName, fileSize: _uploadSize),
      package: _package,
      selectedNodeId: _selectedNodeId,
      selectedFutureWarriorUnitId: _selectedFutureWarriorUnitId,
      canDistribute:
          _uploadPath != null &&
          _package != null &&
          (_selectedNodeId.isNotEmpty ||
              _selectedFutureWarriorUnitId.isNotEmpty) &&
          _interfaceName.isNotEmpty &&
          !_active,
      active: _active,
      session: _session,
      showCancel: _showCancel,
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
        params: {
          'actual': bytes.length,
          'limit': CpdsPackageParser.maxPackageBytes,
        },
        message: 'package too large',
      );
    }
    _ensureIdle();

    final uploadDir = await DirectoryManager.instance.getUploadsPath();
    final available = await freeBytes(uploadDir);
    if (available != null && available < bytes.length) {
      throw CpdsException(
        CpdsErrorCode.insufficientStorage,
        params: {'required': bytes.length, 'available': available},
        message: 'insufficient storage',
      );
    }

    final newPath = path.join(uploadDir, fileName);
    final file = File(newPath);
    await file.writeAsBytes(bytes, flush: true);

    final oldPath = _uploadPath;
    _uploadPath = newPath;
    _uploadName = fileName;
    _transferFileName = fileName;
    _uploadSize = bytes.length;
    _package = null;
    _packageSha256 = null;
    _selectedNodeId = '';
    _selectedFutureWarriorUnitId = '';
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    unawaited(Shared.saveCpdsLastUpload(path: newPath, name: fileName));
    unawaited(Shared.saveCpdsSelectedNode(''));
    if (oldPath != null && oldPath != newPath) {
      _deleteQuietly(File(oldPath));
    }
    _notify();
    return state();
  }

  Future<CpdsApplicationState> parsePackage() async {
    _ensureIdle();
    final uploadPath = _uploadPath;
    if (uploadPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'upload'},
        message: 'no uploaded package',
      );
    }

    final (package, sha) = await CpdsPackageParser.parseFileWithHash(
      uploadPath,
      _uploadName,
      password: AppConfig.zipPassword,
    );

    final available = await freeBytes(path.dirname(uploadPath));
    final required = package.requiredWorkspace;
    if (available != null && available < required) {
      throw CpdsException(
        CpdsErrorCode.insufficientStorage,
        params: {'required': required, 'available': available},
        message: 'insufficient storage',
      );
    }

    _package = package;
    _packageSha256 = sha;
    _selectedNodeId = '';
    _selectedFutureWarriorUnitId = '';
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    _notify();
    return state();
  }

  void updateUploadName(String name) {
    _uploadName = name;
    _notify();
  }

  /// 缓存当前通信包的 `.cpdata` 源文件路径与 age 密码，
  /// 用于后续把节点名称等修改持久化回 `.cpdata`。
  void cachePcSource({required String pcPath, required String password}) {
    _pcSourcePath = pcPath;
    _pcPassword = password;
  }

  /// 修改节点名称：更新内存 + 写回 `.zip` + 重新加密写回 `.cpdata`。
  Future<void> updateNodeName(String nodeId, String newName) async {
    _ensureIdle();
    final package = _package;
    final zipPath = _uploadPath;
    if (package == null || zipPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'no parsed package',
      );
    }
    final pcPath = _pcSourcePath;
    if (pcPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource'},
        message: 'cpdata source file is missing',
      );
    }
    final password = _pcPassword;
    if (password == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcPassword'},
        message: 'cpdata password is missing',
      );
    }

    CpdsNode? node;
    for (final n in package.nodes) {
      if (n.id == nodeId) {
        node = n;
        break;
      }
    }
    if (node == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeId', 'actual': nodeId},
        message: 'unknown node',
      );
    }
    if (node.name == newName) return;

    final pcFile = File(pcPath);
    if (!pcFile.existsSync()) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource', 'path': pcPath},
        message: 'cpdata source file is missing',
      );
    }

    final originalZipBytes = await File(zipPath).readAsBytes();
    final originalPcBytes = await pcFile.readAsBytes();

    final newZipBytes = CpdsPackageParser.updateNodeNameInZip(
      zipPath,
      nodeId,
      newName,
    );
    final newPcBytes = await _ageEncrypt(newZipBytes, password);

    try {
      await _writeBytesReplace(zipPath, newZipBytes);
      await _writeBytesReplace(pcPath, newPcBytes);
    } catch (_) {
      try {
        await _writeBytesReplace(zipPath, originalZipBytes);
      } catch (_) {}
      try {
        await _writeBytesReplace(pcPath, originalPcBytes);
      } catch (_) {}
      rethrow;
    }

    await _reparsePackage();
    _notify();
  }

  /// 修改节点车辆信息备注：只写回 `VeciInfo.Remark`，重新打包 zip、
  /// 重新加密覆盖 `.cpdata`，并刷新内存中的 package。
  Future<void> updateVeciInfoRemark(String nodeId, String remark) async {
    _ensureIdle();
    final package = _package;
    final zipPath = _uploadPath;
    if (package == null || zipPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'no parsed package',
      );
    }
    if (!package.nodes.any((n) => n.id == nodeId)) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeId', 'actual': nodeId},
        message: 'unknown node',
      );
    }
    final pcPath = _pcSourcePath;
    if (pcPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource'},
        message: 'cpdata source file is missing',
      );
    }
    final password = _pcPassword;
    if (password == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcPassword'},
        message: 'cpdata password is missing',
      );
    }

    final pcFile = File(pcPath);
    if (!pcFile.existsSync()) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource', 'path': pcPath},
        message: 'cpdata source file is missing',
      );
    }

    final originalZipBytes = await File(zipPath).readAsBytes();
    final originalPcBytes = await pcFile.readAsBytes();

    final newZipBytes = CpdsPackageParser.updateVeciInfoRemarkInZip(
      zipPath,
      nodeId,
      remark,
    );
    final newPcBytes = await _ageEncrypt(newZipBytes, password);

    try {
      await _writeBytesReplace(zipPath, newZipBytes);
      await _writeBytesReplace(pcPath, newPcBytes);
    } catch (_) {
      try {
        await _writeBytesReplace(zipPath, originalZipBytes);
      } catch (_) {}
      try {
        await _writeBytesReplace(pcPath, originalPcBytes);
      } catch (_) {}
      rethrow;
    }

    await _reparsePackage();
    _notify();
  }

  /// 重新解析当前 `.zip`，刷新 package / sha256 / 文件大小，
  /// 但不清空已选中的节点或「未来战士」分组。
  Future<void> _reparsePackage() async {
    final uploadPath = _uploadPath;
    if (uploadPath == null) return;
    final (package, sha) = await CpdsPackageParser.parseFileWithHash(
      uploadPath,
      path.basename(uploadPath),
      password: AppConfig.zipPassword,
    );
    _package = package;
    _packageSha256 = sha;
    _uploadSize = package.fileSize;
  }

  /// 修改 `.cpdata` 的 age 密码：校验原密码、用新密码重新加密写回 `.cpdata`，
  /// 并更新内存中的密码缓存。`.zip` 保持不变。
  Future<void> changePcPassword(String oldPassword, String newPassword) async {
    _ensureIdle();
    final zipPath = _uploadPath;
    if (_package == null || zipPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'no parsed package',
      );
    }
    final pcPath = _pcSourcePath;
    if (pcPath == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource'},
        message: 'cpdata source file is missing',
      );
    }
    final pcFile = File(pcPath);
    if (!pcFile.existsSync()) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'pcSource', 'path': pcPath},
        message: 'cpdata source file is missing',
      );
    }

    // 校验原密码：优先比对缓存，缓存为空时用原密码解密 `.cpdata` 验证。
    final cached = _pcPassword;
    if (cached != null) {
      if (cached != oldPassword) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'oldPassword'},
          message: 'old password mismatch',
        );
      }
    } else {
      try {
        await _ageDecrypt(await pcFile.readAsBytes(), oldPassword);
      } catch (_) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'oldPassword'},
          message: 'old password mismatch',
        );
      }
    }

    final zipBytes = await File(zipPath).readAsBytes();
    final newPcBytes = await _ageEncrypt(zipBytes, newPassword);
    final originalPcBytes = await pcFile.readAsBytes();

    try {
      await _writeBytesReplace(pcPath, newPcBytes);
    } catch (_) {
      try {
        await _writeBytesReplace(pcPath, originalPcBytes);
      } catch (_) {}
      rethrow;
    }

    _pcPassword = newPassword;
    _notify();
  }

  Future<Uint8List> _ageEncrypt(Uint8List zipBytes, String password) async {
    final chunks = await encryptWithPassphrase(
      Stream.value(zipBytes),
      passphraseProvider: _ManagerPassphrase(password),
      workFactor: 15,
    ).toList();
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<Uint8List> _ageDecrypt(Uint8List pcBytes, String password) async {
    final chunks = await decryptWithPassphrase(
      Stream.value(pcBytes),
      passphraseProvider: _ManagerPassphrase(password),
    ).toList();
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<void> _writeBytesReplace(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    final tmp = File('$filePath.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    try {
      if (file.existsSync()) {
        await file.delete();
      }
      await tmp.rename(filePath);
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<CpdsApplicationState> parseSourcePath(String sourcePath) async {
    _ensureIdle();
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
      _packageSha256 = null;
      _selectedNodeId = '';
      _selectedFutureWarriorUnitId = '';
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
          params: {
            'actual': stat.size,
            'limit': CpdsPackageParser.maxPackageBytes,
          },
          message: 'package too large',
        );
      }
      _uploadPath = sourcePath;
      _uploadName = name;
      _transferFileName = name;
      _uploadSize = stat.size;
      _package = null;
      _packageSha256 = null;
      _selectedNodeId = '';
      _selectedFutureWarriorUnitId = '';
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
    _ensureIdle();
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
    _selectedFutureWarriorUnitId = '';
    unawaited(Shared.saveCpdsSelectedNode(nodeId));
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    _notify();
    return state();
  }

  CpdsApplicationState selectFutureWarrior(String unitId) {
    _ensureIdle();
    final package = _package;
    if (package == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'no parsed package',
      );
    }
    if (_findUnit(package.units, unitId) == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unitId', 'actual': unitId},
        message: 'unknown unit',
      );
    }
    _selectedFutureWarriorUnitId = unitId;
    _selectedNodeId = '';
    _session = null;
    _machine = null;
    _runner = null;
    _active = false;
    _notify();
    return state();
  }

  CpdsUnit? _findUnit(List<CpdsUnit> units, String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
      final found = _findUnit(unit.subUnits, unitId);
      if (found != null) return found;
    }
    return null;
  }

  Future<List<CpdsNetworkInterface>> listNetworkInterfaces() async {
    return CpdsNetworkInterfaceService.listInterfaces();
  }

  /// 刷新网卡列表并缓存，自动选中或恢复上次选中，然后持久化。
  Future<void> refreshNetworkInterfaces() async {
    if (_interfacesLoading) {
      return;
    }
    _interfacesLoading = true;
    _notify();
    try {
      final interfaces = await CpdsNetworkInterfaceService.listInterfaces();
      var selected = '';
      var automatic = false;
      final stored = Shared.getCpdsNetworkInterface() ?? '';
      if (stored.isNotEmpty &&
          interfaces.any((i) => i.name == stored && i.linkUp)) {
        selected = stored;
      } else {
        CpdsNetworkInterface? candidate;
        for (final item in interfaces) {
          if (item.wired && item.linkUp) {
            candidate = item;
            break;
          }
        }
        if (candidate == null) {
          for (final item in interfaces) {
            if (!item.wired && item.linkUp) {
              candidate = item;
              break;
            }
          }
        }
        if (candidate != null) {
          selected = candidate.name;
          automatic = true;
        }
      }
      _interfaces = interfaces;
      _interfaceName = selected;
      _automaticInterface = automatic;
      await Shared.saveCpdsNetworkInterface(selected);
    } finally {
      _interfacesLoading = false;
      _notify();
    }
  }

  Future<CpdsApplicationState> selectNetworkInterface(String name) async {
    _ensureIdle();
    if (name.isNotEmpty) {
      final interfaces = _interfaces.isNotEmpty
          ? _interfaces
          : await listNetworkInterfaces();
      if (!interfaces.any((item) => item.name == name)) {
        throw CpdsException(
          CpdsErrorCode.networkInterfaceError,
          params: {'interface': name},
          message: 'network interface is unavailable',
        );
      }
    }
    _interfaceName = name;
    _automaticInterface = false;
    await Shared.saveCpdsNetworkInterface(name);
    _notify();
    return state();
  }

  String get selectedInterfaceName => _interfaceName;
  List<CpdsNetworkInterface> get interfaces => _interfaces;
  bool get interfacesLoading => _interfacesLoading;
  bool get automaticInterface => _automaticInterface;

  Future<void> restoreLastPackage() async {
    final uploadPath = Shared.getCpdsLastSourcePath();
    final uploadName = Shared.getCpdsLastUploadName();
    if (uploadPath == null || uploadPath.isEmpty) return;
    final file = File(uploadPath);
    if (!file.existsSync()) return;

    _uploadPath = uploadPath;
    _uploadName = uploadName ?? path.basename(uploadPath);
    _transferFileName = uploadName ?? path.basename(uploadPath);
    _uploadSize = file.lengthSync();
    _notify();

    try {
      final (package, sha) = await CpdsPackageParser.parseFileWithHash(
        uploadPath,
        _uploadName,
        password: AppConfig.zipPassword,
      );
      _package = package;
      _packageSha256 = sha;
      final lastNode = Shared.getCpdsLastSelectedNode() ?? '';
      if (lastNode.isNotEmpty &&
          package.nodes.any((node) => node.id == lastNode)) {
        _selectedNodeId = lastNode;
        _selectedFutureWarriorUnitId = '';
      } else {
        _selectedNodeId = '';
        _selectedFutureWarriorUnitId = '';
      }
    } catch (_) {
      _package = null;
      _packageSha256 = null;
      _selectedNodeId = '';
      _selectedFutureWarriorUnitId = '';
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
    final package = _package;
    if (package == null || _selectedNodeId.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'distributionInput'},
        message: 'distribution input is incomplete',
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
    final targetNode = node;
    await _startDistributionWithTargets(
      targetNode.devices
          .map(
            (device) =>
                CpdsDistributionDevice(device: device, nodeId: targetNode.id),
          )
          .toList(),
    );
  }

  Future<void> startFutureWarriorDistribution({
    required String nodeId,
    required String deviceId,
  }) async {
    if (_active) {
      throw CpdsException(
        CpdsErrorCode.busy,
        message: 'distribution already running',
      );
    }
    final package = _package;
    if (package == null || _selectedFutureWarriorUnitId.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'distributionInput'},
        message: 'distribution input is incomplete',
      );
    }
    await _startDistributionWithTargets(
      _futureWarriorTarget(package, nodeId, deviceId),
    );
  }

  Future<void> _startDistributionWithTargets(
    List<CpdsDistributionDevice> targets,
  ) async {
    final uploadPath = _uploadPath;
    final package = _package;
    final sha = _packageSha256;
    if (uploadPath == null || package == null || sha == null) {
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
    final sessionId = _randomUuid();
    final machine = CpdsSessionMachine(targets: targets);
    machine.begin(sessionId);
    final transport = CpdsUdpTransport();
    await transport.init(interfaceIp: selectedInterface.ipv4);
    final decisionController = StreamController<bool>.broadcast();
    final runner = CpdsSessionRunner(
      transport: transport,
      machine: machine,
      input: CpdsPackageInput(
        fileName: _transferFileName,
        filePath: uploadPath,
        fileSize: _uploadSize,
        sha256: sha,
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

    unawaited(_runDistribution(runner, machine, transport, decisionController));
  }

  List<CpdsDistributionDevice> _futureWarriorTarget(
    CpdsPackage package,
    String nodeId,
    String deviceId,
  ) {
    final unit = _findUnit(package.units, _selectedFutureWarriorUnitId);
    if (unit == null || !unit.nodeIds.contains(nodeId)) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeId', 'actual': nodeId},
        message: 'unknown future warrior node in unit',
      );
    }
    CpdsNode? node;
    for (final item in package.nodes) {
      if (item.id == nodeId) {
        node = item;
        break;
      }
    }
    if (node == null || node.nodeType != 1 || node.hasTeds) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'nodeId', 'actual': nodeId},
        message: 'node is not a future warrior node',
      );
    }
    for (final device in node.devices) {
      if (device.id == deviceId) {
        return [CpdsDistributionDevice(device: device, nodeId: node.id)];
      }
    }
    throw CpdsException(
      CpdsErrorCode.invalidPackage,
      params: {'field': 'deviceId', 'actual': deviceId},
      message: 'unknown future warrior device',
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
      machine.failActive('TRANSFER', CpdsErrorCode.networkInterfaceError);
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
    // 等待状态机处理决定并结束本次会话，避免返回旧的 awaiting 状态，
    // 也避免前端 _state.active 仍为 true 导致页面按钮被禁用。
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (_machine != null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
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

  void _ensureIdle() {
    if (_active) {
      throw CpdsException(
        CpdsErrorCode.busy,
        message: 'distribution already running',
      );
    }
  }

  Future<void> dispose() async {
    await _runner?.cancel();
    await _transport?.dispose();
    await _discoveryDecisionController?.close();
    await _stateController.close();
  }
}

class _ManagerPassphrase extends PassphraseProvider {
  _ManagerPassphrase(this.password);

  final String password;

  @override
  Future<String> passphrase() async => password;
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
