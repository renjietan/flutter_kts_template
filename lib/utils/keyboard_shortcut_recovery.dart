import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Windows 键盘状态失步导致的快捷键恢复器（不修改 SDK）。
///
/// 背景：Flutter 3.38.10 的 Windows 引擎在窗口失焦时可能丢失 WM_KEYUP，
/// 框架 [HardwareKeyboard] 内部 `_pressedKeys` 残留“幽灵按下”状态；下一次
/// 按下同一个物理键时，`hardware_keyboard.dart` 的 `_assertEventIsRegular`
/// 会抛断言并丢弃这个 keydown，导致 Ctrl+V / Ctrl+X / Ctrl+C / Ctrl+A /
/// Ctrl+Z 等文本编辑快捷键失效。
///
/// 本类在 [PlatformDispatcher.onKeyData] 这一更早的入口做检测：若一个
/// keydown 的物理键已经处于“按下”状态（即幽灵状态），说明框架随后会把它
/// 丢弃，于是手动对当前聚焦的 EditableText 触发对应的文本编辑 Intent，从而
/// 让快捷键仍然生效（同时保留原有的断言报错日志）。
class KeyboardShortcutRecovery {
  KeyboardShortcutRecovery._();

  static bool _installed = false;
  static int _retries = 0;

  /// 在应用启动后调用一次（建议在根 Widget 的 initState 中调用）。
  static void install() {
    if (_installed) return;
    _installed = true;
    _install();
  }

  static void _install() {
    final ui.KeyDataCallback? current = PlatformDispatcher.instance.onKeyData;
    if (current == null) {
      // 罕见：framework 的键盘通道尚未初始化完成，下一帧再尝试一次。
      if (_retries < 10) {
        _retries += 1;
        WidgetsBinding.instance.addPostFrameCallback((_) => _install());
      }
      return;
    }

    PlatformDispatcher.instance.onKeyData = (ui.KeyData data) {
      _recoverIfNeeded(data);
      return current(data);
    };
  }

  static void _recoverIfNeeded(ui.KeyData data) {
    // 仅 Windows 桌面端存在该焦点切换丢 keyup 的问题。
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    if (data.type != ui.KeyEventType.down) return;

    final PhysicalKeyboardKey physical = PhysicalKeyboardKey(data.physical);
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;

    // 物理键已经处于按下集合 => 框架即将把它当作“重复按下”而丢弃。
    if (!keyboard.physicalKeysPressed.contains(physical)) return;

    final Intent? intent = _intentFor(
      LogicalKeyboardKey(data.logical),
      control: keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
    );
    if (intent == null) return;

    _invokeOnFocusedEditable(intent);
  }

  static Intent? _intentFor(
    LogicalKeyboardKey key, {
    required bool control,
    required bool shift,
  }) {
    if (!control) return null;
    switch (key) {
      case LogicalKeyboardKey.keyV:
        return const PasteTextIntent(SelectionChangedCause.keyboard);
      case LogicalKeyboardKey.keyX:
        return const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard);
      case LogicalKeyboardKey.keyC:
        return CopySelectionTextIntent.copy;
      case LogicalKeyboardKey.keyA:
        return const SelectAllTextIntent(SelectionChangedCause.keyboard);
      case LogicalKeyboardKey.keyZ:
        return shift
            ? const RedoTextIntent(SelectionChangedCause.keyboard)
            : const UndoTextIntent(SelectionChangedCause.keyboard);
      default:
        return null;
    }
  }

  static void _invokeOnFocusedEditable(Intent intent) {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    final BuildContext? context = focus?.context;
    if (context == null || !context.mounted) return;
    Actions.maybeInvoke(context, intent);
  }
}
