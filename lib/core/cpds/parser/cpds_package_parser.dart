import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../cpds_exception.dart';
import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';

class CpdsPackageParser {
  CpdsPackageParser._();

  static const int maxPackageBytes = 1 << 20;
  static const int maxExpandedBytes = 64 << 20;
  static const int maxEntryBytes = 8 << 20;
  static const int maxEntries = 4096;
  static const int maxExpansionRatio = 200;
  static const int maxPathBytes = 1024;
  static const int maxPathComponentBytes = 255;
  static const int maxDevicesPerNode = 100;

  static Future<CpdsPackage> parseFile(
    String filePath,
    String originalName, {
    String? password,
  }
  ) async {
    _validateFileName(originalName);
    final file = File(filePath);
    if (!await file.exists()) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'file'},
        message: 'file does not exist',
      );
    }

    final stat = await file.stat();
    if (stat.size <= 0) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'emptyFile'},
        message: 'empty file',
      );
    }
    if (stat.size > maxPackageBytes) {
      throw CpdsException(
        CpdsErrorCode.packageTooLarge,
        params: {'actual': stat.size, 'limit': maxPackageBytes},
        message: 'package too large',
      );
    }

    final bytes = await file.readAsBytes();
    final archive = _decodeZip(bytes, password: password);
    final contents = _inspectArchive(archive, stat.size);
    final package = _parseBusinessFiles(contents);

    return CpdsPackage(
      fileName: originalName,
      fileSize: stat.size,
      expandedSize: contents.expandedSize,
      requiredWorkspace: _estimateWorkspace(stat.size, contents.expandedSize),
      units: package.units,
      nodes: package.nodes,
    );
  }

  static Future<CpdsPackage> parseDirectory(
    Directory directory,
    String originalName,
  ) async {
    if (!await directory.exists()) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'directory', 'path': directory.path},
        message: 'directory does not exist',
      );
    }
    final contents = await _readDirectoryContents(directory);
    final package = _parseBusinessFiles(contents);
    final fileSize = contents.files.values.fold<int>(
      0,
      (sum, bytes) => sum + bytes.length,
    );
    return CpdsPackage(
      fileName: originalName,
      fileSize: fileSize,
      expandedSize: contents.expandedSize,
      requiredWorkspace: _estimateWorkspace(
        fileSize,
        contents.expandedSize,
      ),
      units: package.units,
      nodes: package.nodes,
    );
  }

  static void _validateFileName(String name) {
    if (name.isEmpty ||
        path.basename(name) != name ||
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

  static Future<_ZipContents> _readDirectoryContents(
    Directory directory,
  ) async {
    final contents = _ZipContents();
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Link) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'specialZipEntry', 'path': entity.path},
        );
      }
      if (entity is! File) continue;
      final relative = path
          .relative(entity.path, from: directory.path)
          .replaceAll(r'\', '/');
      final safeName = _safeZipPath(relative);
      final bytes = await entity.readAsBytes();
      if (bytes.length > maxEntryBytes) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {
            'field': 'entrySize',
            'path': safeName,
            'actual': bytes.length,
            'limit': maxEntryBytes,
          },
        );
      }
      if (contents.expandedSize + bytes.length > maxExpandedBytes) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {
            'field': 'expandedSize',
            'actual': contents.expandedSize + bytes.length,
            'limit': maxExpandedBytes,
          },
        );
      }
      contents.expandedSize += bytes.length;
      contents.files[safeName] = bytes;
      var parent = path.posix.dirname(safeName);
      while (parent != '.' && parent != '/') {
        contents.directories[parent] = true;
        parent = path.posix.dirname(parent);
      }
    }
    return contents;
  }

  static Archive _decodeZip(List<int> bytes, {String? password}) {
    try {
      return ZipDecoder().decodeBytes(bytes, verify: true, password: password);
    } catch (error) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'zip', 'cause': error.toString()},
        message: 'invalid zip',
      );
    }
  }

  static _ZipContents _inspectArchive(Archive archive, int packageSize) {
    if (archive.files.length > maxEntries) {
      throw CpdsException(
        CpdsErrorCode.invalidZipSize,
        params: {'field': 'entries', 'actual': archive.files.length, 'limit': maxEntries},
      );
    }

    final contents = _ZipContents();
    final seen = <String, String>{};
    for (final entry in archive.files) {
      final rawName = entry.name;
      final safeName = _safeZipPath(rawName);
      final folded = safeName.toLowerCase().replaceFirst(RegExp(r'/$'), '');
      if (seen.containsKey(folded)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'duplicateZipPath', 'path': safeName},
        );
      }
      seen[folded] = safeName;

      if (entry.isDirectory) {
        contents.directories[safeName.replaceFirst(RegExp(r'/$'), '')] = true;
        continue;
      }
      if (entry.isSymbolicLink) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'specialZipEntry', 'path': safeName},
        );
      }
      if (entry.size > maxEntryBytes) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {'field': 'entrySize', 'path': safeName, 'actual': entry.size, 'limit': maxEntryBytes},
        );
      }
      if (contents.expandedSize + entry.size > maxExpandedBytes) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {'field': 'expandedSize', 'actual': contents.expandedSize + entry.size, 'limit': maxExpandedBytes},
        );
      }
      contents.expandedSize += entry.size;
      if (packageSize == 0 || contents.expandedSize > packageSize * maxExpansionRatio) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {'field': 'expansionRatio', 'actual': contents.expandedSize, 'limit': packageSize * maxExpansionRatio},
        );
      }

      final bytes = entry.content;
      if (bytes.length != entry.size) {
        throw CpdsException(
          CpdsErrorCode.invalidZipSize,
          params: {'field': 'readZipEntry', 'path': safeName, 'actual': bytes.length, 'limit': entry.size},
        );
      }
      contents.files[safeName] = bytes;
      var parent = path.posix.dirname(safeName);
      while (parent != '.' && parent != '/') {
        contents.directories[parent] = true;
        parent = path.posix.dirname(parent);
      }
    }
    return contents;
  }

  static String _safeZipPath(String raw) {
    if (raw.isEmpty ||
        raw.contains('\u0000') ||
        raw.contains(r'\') ||
        utf8.encode(raw).length > maxPathBytes) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unsafeZipPath', 'path': raw},
      );
    }
    if (raw.startsWith('/') || raw.contains(':')) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unsafeZipPath', 'path': raw},
      );
    }
    final cleaned = path.posix.normalize(raw);
    if (cleaned == '.' ||
        cleaned == '..' ||
        cleaned.startsWith('../')) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unsafeZipPath', 'path': raw},
      );
    }
    for (final part in cleaned.split('/')) {
      if (part.isEmpty ||
          part == '.' ||
          part == '..' ||
          utf8.encode(part).length > maxPathComponentBytes ||
          part.endsWith('.') ||
          part.endsWith(' ') ||
          _windowsDeviceName(part)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'unsafeZipPath', 'path': raw},
        );
      }
    }
    return raw.endsWith('/') ? '$cleaned/' : cleaned;
  }

  static final RegExp _windowsDeviceRegex = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?$',
    caseSensitive: false,
  );

  static bool _windowsDeviceName(String part) =>
      _windowsDeviceRegex.hasMatch(part);

  static _BusinessPackage _parseBusinessFiles(_ZipContents contents) {
    if (contents.directories['1_key'] ?? false) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unsupportedResourceDirectory', 'path': '1_key'},
      );
    }
    for (final required in const [
      '0_contacts',
      '3_device_config',
      '4_net_node',
      '6_unit',
    ]) {
      if (!(contents.directories[required] ?? false)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'requiredDirectory', 'path': required},
        );
      }
    }

    final contacts = <Map<String, dynamic>>[];
    final unitFiles = <String, Map<String, dynamic>>{};
    final nodeFiles = <String, Map<String, dynamic>>{};
    final deviceFiles = <String, Map<String, dynamic>>{};
    final subnets = <String>{};
    final hasResource = contents.directories['1_resource'] ?? false;
    final hasSubnetDir = contents.directories['2_radio_subnet'] ?? false;

    for (final entry in contents.files.entries) {
      final name = entry.key;
      if (name == 'local_node.json') continue;
      final parts = path.posix.split(name);
      if (parts.length < 2) continue;
      final dir = parts[parts.length - 2];
      final base = path.posix.basename(name);
      final data = entry.value;
      switch (dir) {
        case '0_contacts':
          contacts.add(_decodeJson(name, data));
          break;
        case '6_unit':
          unitFiles[path.posix.basenameWithoutExtension(base)] = _decodeJson(
            name,
            data,
          );
          break;
        case '4_net_node':
          nodeFiles[path.posix.basenameWithoutExtension(base)] = _decodeJson(
            name,
            data,
          );
          break;
        case '3_device_config':
          deviceFiles[path.posix.basenameWithoutExtension(base)] = _decodeJson(
            name,
            data,
          );
          break;
        case '2_radio_subnet':
          subnets.add(path.posix.basenameWithoutExtension(base));
          break;
        case '1_resource':
        case '5_user':
          _decodeJson(name, data);
          break;
      }
    }

    if (contacts.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'contacts', 'path': '0_contacts'},
      );
    }

    final nodes = <String, CpdsNode>{};
    for (final entry in nodeFiles.entries) {
      final node = _buildNode(
        entry.key,
        entry.value,
        deviceFiles,
        subnets,
        hasResource,
        hasSubnetDir,
      );
      nodes[entry.key] = node;
    }

    contacts.sort((a, b) {
      final left = (a['File']?['Guid'] ?? '').toString();
      final right = (b['File']?['Guid'] ?? '').toString();
      return left.compareTo(right);
    });

    final units = <CpdsUnit>[];
    for (final contact in contacts) {
      final unitRef = _asMap(contact['UnitTree']);
      units.add(_buildUnit(unitRef, unitFiles, nodes));
    }
    return _BusinessPackage(units: units, nodes: nodes.values.toList());
  }

  static Map<String, dynamic> _decodeJson(String name, Uint8List data) {
    if (path.posix.extension(name).toLowerCase() != '.json') {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'jsonExtension', 'path': name},
      );
    }
    try {
      final value = jsonDecode(utf8.decode(data));
      if (value is! Map) {
        throw const FormatException('json root is not object');
      }
      return Map<String, dynamic>.from(value);
    } on FormatException {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'json', 'path': name},
      );
    }
  }

  static CpdsUnit _buildUnit(
    Map<String, dynamic> ref,
    Map<String, dynamic> unitFiles,
    Map<String, CpdsNode> nodes,
  ) {
    final unitId = ref['UnitId']?.toString() ?? '';
    if (unitId.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'UnitId', 'path': '0_contacts'},
      );
    }
    final file = _asMap(unitFiles[unitId]);
    final unitName = file['UnitName']?.toString() ?? '';
    if (file.isEmpty || unitName.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'unitReference', 'path': unitId},
      );
    }

    final nodeIds = _stringList(ref['NetNodes']);
    for (final nodeId in nodeIds) {
      if (!nodes.containsKey(nodeId)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'nodeReference', 'path': nodeId},
        );
      }
    }
    final subUnits = _listOfMaps(ref['SubUnits'])
        .map((item) => _buildUnit(item, unitFiles, nodes))
        .toList();
    return CpdsUnit(
      id: unitId,
      name: unitName,
      nodeIds: nodeIds,
      subUnits: subUnits,
    );
  }

  static CpdsNode _buildNode(
    String id,
    Map<String, dynamic> raw,
    Map<String, dynamic> deviceFiles,
    Set<String> subnets,
    bool hasResource,
    bool hasSubnetDir,
  ) {
    final basicInfo = _asMap(raw['BasicInfo']);
    final file = _asMap(raw['File']);
    final systemConfig = _asMap(raw['SystemConfiguration']);
    if (id.isEmpty ||
        utf8.encode(id).length > 255 ||
        (basicInfo['NodeName']?.toString().isEmpty ?? true)) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'node', 'path': id},
      );
    }

    final devices = <CpdsDevice>[];
    final seen = <String, CpdsDeviceType>{};
    var hasRadio = false;

    void appendIds(
      List<String> ids,
      CpdsDeviceType type,
      String prefix,
      String modelName, {
      List<CpdsDeviceType> additionalTypes = const [],
    }) {
      for (final deviceId in ids) {
        if (deviceId.isEmpty ||
            utf8.encode(deviceId).length > 255 ||
            !deviceId.startsWith(prefix)) {
          throw CpdsException(
            CpdsErrorCode.invalidPackage,
            params: {'field': 'devicePrefix', 'path': deviceId},
          );
        }
        if (seen.containsKey(deviceId)) {
          throw CpdsException(
            CpdsErrorCode.invalidPackage,
            params: {'field': 'duplicateDevice', 'path': deviceId},
          );
        }
        if (devices.length + 1 + additionalTypes.length > maxDevicesPerNode) {
          throw CpdsException(
            CpdsErrorCode.invalidPackage,
            params: {'field': 'deviceCount', 'path': id},
          );
        }
        final config = _asMap(deviceFiles[deviceId]);
        if (config.isEmpty) {
          throw CpdsException(
            CpdsErrorCode.invalidPackage,
            params: {'field': 'deviceReference', 'path': deviceId},
          );
        }
        if (_isRadio(type)) {
          hasRadio = true;
          _validateRadio(deviceId, type, config, subnets);
        }
        seen[deviceId] = type;
        final model = (config['File']?['Model']?.toString().isNotEmpty ?? false)
            ? config['File']!['Model'].toString()
            : modelName;
        final device = CpdsDevice(
          id: deviceId,
          type: type,
          model: model,
          alias: config['Alias']?.toString() ?? '',
          ip: config['IP']?.toString() ?? '',
        );
        devices.add(device);
        for (final additional in additionalTypes) {
          devices.add(
            CpdsDevice(
              id: device.id,
              type: additional,
              model: device.model,
              alias: device.alias,
              ip: device.ip,
            ),
          );
        }
      }
    }

    final serverIds = _stringList(systemConfig['LANPrimary']?['Server']);
    CpdsDeviceType? serverKind;
    for (final deviceId in serverIds) {
      final CpdsDeviceType kind;
      final String prefix;
      final String modelName;
      if (deviceId.startsWith('dc_server_')) {
        kind = CpdsDeviceType.server;
        prefix = 'dc_server_';
        modelName = 'Server';
      } else if (deviceId.startsWith('dc_IEC_')) {
        kind = CpdsDeviceType.iec;
        prefix = 'dc_IEC_';
        modelName = 'IEC';
      } else {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'serverDevicePrefix', 'path': deviceId},
        );
      }
      if (serverKind != null && serverKind != kind) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'serverIecMutualExclusion', 'path': id},
        );
      }
      serverKind = kind;
      appendIds([deviceId], kind, prefix, modelName);
    }

    appendIds(
      _stringList(systemConfig['LANMember']?['CCU']),
      CpdsDeviceType.ccu,
      'dc_ccu_',
      'CCU',
      additionalTypes: [CpdsDeviceType.ccuAudio],
    );

    // 暂不把 VehInter 加入期望设备清单。VehInter(device_type=9) 是较新的
    // 设备类型，目前旧版 CPDC 固件（例如 MMR200 电台）不认识 type=9，
    // 收到携带 VehInter 的 AUTH_NTY 时会按 INVALID_MESSAGE 拒绝，导致整轮
    // 认证被拖垮。这里与旧版 Go CPDS 保持一致：解析时忽略 VehInter，待
    // 端侧固件都升级支持 VehInter 后再重新启用。

    final radioMappings = <MapEntry<String, (String, String, CpdsDeviceType)>>[
      MapEntry('MMR200', ('dc_MMR200_', 'MMR200', CpdsDeviceType.multiBandRadio)),
      MapEntry('PMR200', ('dc_PMR200_', 'PMR200', CpdsDeviceType.multiBandHandheld)),
      MapEntry('MR9360', ('dc_MR9360_', 'MR9360', CpdsDeviceType.hf)),
      MapEntry('PRR206', ('dc_PRR206_', 'PRR206', CpdsDeviceType.smallHandheld)),
    ];
    final knownRadio = radioMappings.map((e) => e.key).toSet();
    for (final mapping in radioMappings) {
      final config = mapping.value;
      appendIds(
        _stringList(systemConfig['Radio']?[mapping.key]),
        config.$3,
        config.$1,
        config.$2,
      );
    }
    final radioConfig = _asMap(systemConfig['Radio']);
    for (final key in radioConfig.keys) {
      if (!knownRadio.contains(key) &&
          (_stringList(radioConfig[key]).isNotEmpty)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'unknownRadioType', 'path': id, 'actual': key},
        );
      }
    }
    if (hasRadio && (!hasResource || !hasSubnetDir)) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'radioDirectories', 'path': id},
      );
    }

    return CpdsNode(
      id: id,
      guid: file['Guid']?.toString() ?? '',
      name: basicInfo['NodeName']?.toString() ?? '',
      networkSegment: basicInfo['NetworkSegment']?.toString() ?? '',
      nodeType: _asInt(basicInfo['NodeType']),
      model: file['Model']?.toString() ?? '',
      devices: devices,
    );
  }

  static void _validateRadio(
    String id,
    CpdsDeviceType type,
    Map<String, dynamic> config,
    Set<String> subnets,
  ) {
    if ((type == CpdsDeviceType.multiBandRadio ||
            type == CpdsDeviceType.multiBandHandheld) &&
        (config['Alias'] == null ||
            config['Alias'].toString().isEmpty ||
            config['Alias'].toString().length > 128 ||
            config['Alias'].toString().contains('\u0000') ||
            config['Alias'].toString().contains('\r') ||
            config['Alias'].toString().contains('\n'))) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'Alias', 'path': id},
      );
    }
    final channels = _asMap(config['Channels']);
    if (channels.isEmpty) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'Channels', 'path': id},
      );
    }
    for (final entry in channels.entries) {
      final channel = _asMap(entry.value);
      final subnet = channel['Subnet']?.toString() ?? '';
      if (subnet.isEmpty ||
          subnet.contains('/') ||
          subnet.contains(r'\') ||
          !subnets.contains(subnet)) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'Channels.${entry.key}.Subnet', 'path': id},
        );
      }
    }
  }

  static bool _isRadio(CpdsDeviceType type) =>
      type == CpdsDeviceType.hf ||
      type == CpdsDeviceType.multiBandRadio ||
      type == CpdsDeviceType.multiBandHandheld ||
      type == CpdsDeviceType.smallHandheld;

  static int _estimateWorkspace(int fileSize, int expandedSize) {
    final base = fileSize + expandedSize * 2;
    return base + (base + 4) ~/ 5;
  }
}

class _ZipContents {
  final Map<String, Uint8List> files = {};
  final Map<String, bool> directories = {};
  int expandedSize = 0;
}

class _BusinessPackage {
  _BusinessPackage({required this.units, required this.nodes});

  final List<CpdsUnit> units;
  final List<CpdsNode> nodes;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
