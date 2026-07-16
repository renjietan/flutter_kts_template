import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

class SimpleFormSelectField<T> extends StatelessWidget {
  /// 当前选中的值（受控模式）
  final T? value;

  /// 初始值
  final T? initialValue;

  /// 选项数据源
  final List<T> items;

  /// 将数据项转换为显示文本的构建器（必填）
  final String Function(T item) labelBuilder;

  /// 值改变回调（受控模式必填）
  final void Function(T?)? onChanged;

  /// 表单验证器
  final String? Function(T?)? validator;

  /// 值保存回调（用于 Form 的 onSaved）
  final void Function(T?)? onSaved;

  /// 自动验证模式
  final AutovalidateMode? autovalidateMode;

  /// 输入框装饰（可自定义）
  final InputDecoration? decoration;

  /// 下拉菜单的提示文本（未选择时显示）
  final String? hintText;

  /// 是否启用
  final bool enabled;

  /// 下拉菜单的样式（如高度、背景色等）
  final DropdownButtonStyle? dropdownButtonStyle;

  const SimpleFormSelectField({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    required this.labelBuilder,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.decoration,
    this.hintText,
    this.enabled = true,
    this.dropdownButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final dropdownItems = items.map<DropdownMenuItem<T>>((item) {
      return DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item)));
    }).toList();

    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(hintText: hintText ?? t.TextField.select);

    return DropdownButtonFormField<T>(
      value: value ?? initialValue,
      items: dropdownItems,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      decoration: effectiveDecoration,
      style:
          dropdownButtonStyle?.textStyle ??
          const TextStyle(fontSize: 14, color: Colors.white),
      // 可扩展更多属性
      isExpanded: true,
      menuMaxHeight: 150,
    );
  }
}

// 按钮样式
class DropdownButtonStyle {
  final TextStyle? textStyle;
  DropdownButtonStyle({this.textStyle});
}
