import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

Future<String?> getVersion() async {
  String injectedVersion = String.fromEnvironment('APP_VERSION');
  if (injectedVersion.isNotEmpty) {
    return injectedVersion;
  }
  PackageInfo info = await PackageInfo.fromPlatform();
  var version = info.version;
  final build = _normalizedBuildNumber(info.buildNumber);
  if (build.isNotEmpty) {
    version = '$version.$build';
  }
  return version.isEmpty ? "" : version;
}

String _normalizedBuildNumber(String raw) {
  if (!Platform.isAndroid) return raw;
  final code = int.tryParse(raw);
  if (code != null && code >= 1000) {
    return '${code % 1000}';
  }
  return raw;
}
