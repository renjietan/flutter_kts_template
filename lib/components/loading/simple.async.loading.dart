import 'package:unified_popups/unified_popups.dart';

class SimpleAsyncPopup {
  static Future<void> loading(Duration? timeout) async {
    if (timeout != null) await Future.delayed(timeout);
    Pop.loading();
  }

  static Future<void> hideLoading(Duration? timeout) async {
    if (timeout != null) await Future.delayed(timeout);
    Pop.hideLoading();
  }

  static Future<void> success(
    String message, {
    Duration? duration,
    Duration? timeout,
  }) async {
    await toast(
      message,
      duration: duration,
      toastType: ToastType.success,
      timeout: timeout,
    );
  }

  static Future<void> error(
    String message, {
    Duration? duration,
    Duration? timeout,
  }) async {
    await toast(
      message,
      duration: duration,
      toastType: ToastType.error,
      timeout: timeout,
    );
  }

  static Future<void> warn(
    String message, {
    Duration? duration,
    Duration? timeout,
  }) async {
    await toast(
      message,
      duration: duration,
      toastType: ToastType.warn,
      timeout: timeout,
    );
  }

  static Future<void> none(
    String message, {
    Duration? duration,
    Duration? timeout,
  }) async {
    await toast(message, duration: duration, timeout: timeout);
  }

  static Future<void> toast(
    String message, {
    Duration? duration,
    ToastType? toastType,
    Duration? timeout,
  }) async {
    if (timeout != null) {
      await Future.delayed(timeout);
    }
    Pop.toast(
      message,
      duration: duration ?? Duration(milliseconds: 1500),
      toastType: toastType ?? ToastType.none,
    );
  }
}
