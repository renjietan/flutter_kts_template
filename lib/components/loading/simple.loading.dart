import 'package:unified_popups/unified_popups.dart';

class SimplePopup {
  static void loading() {
    Pop.loading();
  }

  static void hideLoading() {
    Pop.hideLoading();
  }

  static void success(String message, {Duration? duration}) {
    toast(message, duration: duration, toastType: ToastType.success);
  }

  static void error(String message, {Duration? duration}) {
    toast(message, duration: duration, toastType: ToastType.error);
  }

  static void warn(String message, {Duration? duration}) {
    toast(message, duration: duration, toastType: ToastType.warn);
  }

  static void none(String message, {Duration? duration}) {
    toast(message, duration: duration);
  }

  static void toast(
    String message, {
    Duration? duration,
    ToastType? toastType,
  }) {
    Pop.toast(
      message,
      duration: duration ?? Duration(milliseconds: 1500),
      toastType: toastType ?? ToastType.none,
    );
  }
}
