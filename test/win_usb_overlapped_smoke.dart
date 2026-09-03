import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_ffi.dart';

/// 独立 FFI 冒烟测试：验证新增的 overlapped / event / wait 相关 FFI 绑定。
///
/// 运行方式：dart run test/win_usb_overlapped_smoke.dart
///
/// 该测试不依赖真实注钥枪设备，而是直接验证：
///   1. OVERLAPPED 结构体在 x64 下的布局大小为 32 字节；
///   2. CreateEventW / SetEvent / ResetEvent / WaitForMultipleObjects / CloseHandle
///      的函数签名与调用约定正确。
void main() {
  // 1. 验证 OVERLAPPED 结构体大小（x64 应为 32 字节）。
  final overlappedSize = sizeOf<OVERLAPPED>();
  if (overlappedSize != 32) {
    throw StateError(
      'OVERLAPPED size mismatch: expected 32, got $overlappedSize',
    );
  }
  print('[1] OVERLAPPED size = $overlappedSize (expected 32) OK');

  // 2. 创建 manual-reset event。
  final evt = fCreateEventW(nullptr, 1, 0, nullptr);
  if (evt == 0) {
    throw StateError('CreateEventW failed');
  }
  print('[2] CreateEventW OK handle=$evt');

  final handles = calloc<IntPtr>(1);
  handles[0] = evt;

  // 3. 初始状态非 signal，零超时等待应返回 WAIT_TIMEOUT。
  final wait1 = fWaitForMultipleObjects(1, handles, 0, 0);
  if (wait1 != WAIT_TIMEOUT) {
    calloc.free(handles);
    fCloseHandle(evt);
    throw StateError('expected WAIT_TIMEOUT, got $wait1');
  }
  print('[3] WaitForMultipleObjects(0ms) = WAIT_TIMEOUT OK');

  // 4. SetEvent 后等待应返回 WAIT_OBJECT_0。
  fSetEvent(evt);
  final wait2 = fWaitForMultipleObjects(1, handles, 0, 0);
  if (wait2 != WAIT_OBJECT_0) {
    calloc.free(handles);
    fCloseHandle(evt);
    throw StateError('expected WAIT_OBJECT_0, got $wait2');
  }
  print('[4] WaitForMultipleObjects after SetEvent = WAIT_OBJECT_0 OK');

  // 5. ResetEvent 后再次等待应返回 WAIT_TIMEOUT。
  fResetEvent(evt);
  final wait3 = fWaitForMultipleObjects(1, handles, 0, 0);
  if (wait3 != WAIT_TIMEOUT) {
    calloc.free(handles);
    fCloseHandle(evt);
    throw StateError('expected WAIT_TIMEOUT after ResetEvent, got $wait3');
  }
  print('[5] WaitForMultipleObjects after ResetEvent = WAIT_TIMEOUT OK');

  // 6. 关闭 handle。
  fCloseHandle(evt);
  calloc.free(handles);
  print('[6] CloseHandle OK');

  print('ALL OVERLAPPED SMOKE TESTS PASSED');
}
