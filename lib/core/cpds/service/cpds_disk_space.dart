import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_kts_template/logger/logger.dart';

typedef _GetDiskFreeSpaceExW_Native =
    Int32 Function(
      Pointer<Utf16> lpDirectoryName,
      Pointer<Uint64> lpFreeBytesAvailableToCaller,
      Pointer<Uint64> lpTotalNumberOfBytes,
      Pointer<Uint64> lpTotalNumberOfFreeBytes,
    );

typedef _GetDiskFreeSpaceExW_Dart =
    int Function(
      Pointer<Utf16> lpDirectoryName,
      Pointer<Uint64> lpFreeBytesAvailableToCaller,
      Pointer<Uint64> lpTotalNumberOfBytes,
      Pointer<Uint64> lpTotalNumberOfFreeBytes,
    );

typedef _GetLastError_Native = Uint32 Function();
typedef _GetLastError_Dart = int Function();

/// 返回 path 所在卷的可用字节数，用于 CPDS 磁盘空间预检。
///
/// 查询失败时返回 null，调用方应跳过该预检，不能因为“无法查询磁盘空间”
/// 阻断正常的上传/解析流程。
Future<int?> freeBytes(String path) async {
  if (Platform.isWindows) {
    return _windowsFreeBytes(path);
  }
  return _unixFreeBytes(path);
}

int? _windowsFreeBytes(String path) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final getDiskFreeSpaceExW = kernel32
      .lookupFunction<_GetDiskFreeSpaceExW_Native, _GetDiskFreeSpaceExW_Dart>(
        'GetDiskFreeSpaceExW',
      );
  final getLastError = kernel32
      .lookupFunction<_GetLastError_Native, _GetLastError_Dart>('GetLastError');
  final absolute = File(path).absolute.path;
  final pathPtr = absolute.toNativeUtf16();
  final freePtr = calloc<Uint64>();
  final totalPtr = calloc<Uint64>();
  final totalFreePtr = calloc<Uint64>();
  try {
    final ok = getDiskFreeSpaceExW(pathPtr, freePtr, totalPtr, totalFreePtr);
    if (ok == 0) {
      GlobalLogger.logWarn(
        'CPDS_DISK_SPACE_QUERY_FAILED path=$absolute err=${getLastError()}',
      );
      return null;
    }
    return freePtr.value;
  } finally {
    calloc.free(pathPtr);
    calloc.free(freePtr);
    calloc.free(totalPtr);
    calloc.free(totalFreePtr);
  }
}

Future<int?> _unixFreeBytes(String path) async {
  final result = await Process.run('df', ['-Pk', path]);
  if (result.exitCode != 0) {
    GlobalLogger.logWarn('CPDS_DISK_SPACE_DF_FAILED path=$path');
    return null;
  }
  final text = switch (result.stdout) {
    final String value => value,
    final List<int> value => String.fromCharCodes(value),
    _ => '',
  };
  final lines = text.trim().split('\n');
  if (lines.length < 2) {
    GlobalLogger.logWarn('CPDS_DISK_SPACE_DF_INVALID path=$path');
    return null;
  }
  final fields = lines[1].split(RegExp(r'\s+'));
  if (fields.length < 4) {
    GlobalLogger.logWarn('CPDS_DISK_SPACE_DF_INVALID path=$path');
    return null;
  }
  final availableKb = int.tryParse(fields[3]);
  if (availableKb == null) {
    GlobalLogger.logWarn('CPDS_DISK_SPACE_DF_INVALID path=$path');
    return null;
  }
  return availableKb * 1024;
}
