import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.item.dart';
import 'package:google_fonts/google_fonts.dart';

/// 深色主题下拉框，适配桌面端与手机端
/// - 桌面端：点击后在字段下方弹出菜单
/// - 手机端：点击后从底部弹出选择面板
class SimpleDarkDropdown<T> extends StatefulWidget {
  final List<SimpleDarkDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final double width;
  final double height;
  final bool enabled;

  const SimpleDarkDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.width = 160,
    this.height = 32,
    this.enabled = true,
  });

  @override
  State<SimpleDarkDropdown<T>> createState() => _SimpleDarkDropdownState<T>();
}

class _SimpleDarkDropdownState<T> extends State<SimpleDarkDropdown<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    final isPhone = MediaQuery.of(context).size.width < 768;
    if (isPhone) {
      _showMobileSheet();
    } else {
      _showDesktopMenu();
    }
  }

  /// 桌面端：使用 Overlay 在字段下方弹出菜单
  void _showDesktopMenu() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DesktopMenu<T>(
        layerLink: _layerLink,
        fieldWidth: size.width,
        items: widget.items,
        selectedValue: widget.value,
        onSelected: (value) {
          _closeOverlay();
          widget.onChanged?.call(value);
        },
        onDismiss: _closeOverlay,
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  /// 手机端：从底部弹出选择面板
  void _showMobileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171C22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => _MobileSheet<T>(
        items: widget.items,
        selectedValue: widget.value,
        hintText: widget.hintText,
        onSelected: (value) {
          Navigator.of(context).pop();
          widget.onChanged?.call(value);
        },
      ),
    );
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items
        .where((e) => e.value == widget.value)
        .toList();
    final hasSelection = selectedItem.isNotEmpty;
    final displayText = hasSelection
        ? selectedItem.first.label
        : (widget.hintText ?? '');

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(2),
          hoverColor: widget.enabled ? const Color(0x26004098) : null,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2329),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: _isOpen
                    ? const Color(0xFF00A2E9)
                    : const Color(0xFF353A41),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(
                    widget.prefixIcon,
                    size: 14,
                    color: widget.enabled
                        ? const Color(0xFFB7BCC6)
                        : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: hasSelection
                          ? (widget.enabled
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF666666))
                          : const Color(0xFF8A94A6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 16,
                  color: widget.enabled
                      ? const Color(0xFF8A94A6)
                      : const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 桌面端弹出菜单
class _DesktopMenu<T> extends StatelessWidget {
  final LayerLink layerLink;
  final double fieldWidth;
  final List<SimpleDarkDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final VoidCallback onDismiss;

  const _DesktopMenu({
    required this.layerLink,
    required this.fieldWidth,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 点击空白区域关闭
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: fieldWidth > 120 ? fieldWidth : 120,
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: const Color(0xFF23272D),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFF353A41), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.value == selectedValue;
                  return _MenuItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onSelected(item.value),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 菜单项
class _MenuItem<T> extends StatelessWidget {
  final SimpleDarkDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0x26004098),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: isSelected ? const Color(0x40004098) : Colors.transparent,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFF0CB5FF)
                    : const Color(0xFFB7BCC6),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF0CB5FF)
                      : const Color(0xFFFFFFFF),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 14, color: Color(0xFF0CB5FF)),
          ],
        ),
      ),
    );
  }
}

/// 手机端底部选择面板
class _MobileSheet<T> extends StatelessWidget {
  final List<SimpleDarkDropdownItem<T>> items;
  final T? selectedValue;
  final String? hintText;
  final ValueChanged<T?> onSelected;

  const _MobileSheet({
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF42474E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  hintText ?? '请选择',
                  style: GoogleFonts.baiJamjuree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(2),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: const Color(0xFFB7BCC6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF353A41), height: 1),
          // 选项列表
          ConstrainedConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(
                color: Color(0xFF282D33),
                height: 1,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.value == selectedValue;
                return InkWell(
                  onTap: () => onSelected(item.value),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: isSelected
                        ? const Color(0x40004098)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFF0CB5FF)
                                : const Color(0xFFB7BCC6),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF0CB5FF)
                                  : const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF0CB5FF),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 辅助：约束最大高度
class ConstrainedConstraints extends StatelessWidget {
  final double maxHeight;
  final Widget child;

  const ConstrainedConstraints({
    super.key,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: child,
    );
  }
}
