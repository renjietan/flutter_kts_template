import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class SimpleFormTextField extends StatefulWidget {
  final FormFieldConfig field;
  final Color? fillColor;
  final double? labelFontSize;
  final double contentPadding;

  const SimpleFormTextField({
    super.key,
    required this.field,
    this.fillColor = const Color(0x9921262C),
    this.labelFontSize = 13,
    this.contentPadding = 12,
  });

  @override
  State<SimpleFormTextField> createState() => _SimpleFormTextFieldState();
}

class _SimpleFormTextFieldState extends State<SimpleFormTextField> {
  @override
  void initState() {
    super.initState();
    widget.field.textEditingController?.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.field.textEditingController?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final counter = widget.field.counterTextBuilder?.call(
      widget.field.textEditingController?.text ?? '',
    );
    final hasFixedHeight = widget.field.height != null;
    final textField = FormBuilderTextField(
      name: widget.field.name,
      controller: widget.field.textEditingController,
      obscureText: widget.field.obscureText,
      keyboardType: widget.field.keyboardType,
      enabled: widget.field.enabled,
      readOnly: widget.field.readonly,
      inputFormatters: widget.field.inputFormatters,
      style: TextStyle(fontSize: 13.sp),
      scrollPadding: EdgeInsets.only(bottom: 80.h),
      maxLines: hasFixedHeight ? null : widget.field.maxLines,
      minLines: hasFixedHeight ? null : widget.field.minLines,
      expands: hasFixedHeight,
      textAlignVertical: hasFixedHeight ? TextAlignVertical.top : null,
      validator: widget.field.validators != null
          ? FormBuilderValidators.compose(widget.field.validators!)
          : null,
      decoration: InputDecoration(
        labelText: widget.field.showLabelText
            ? (widget.field.hintText ?? widget.field.label)
            : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: widget.contentPadding.h ?? 12.h,
          horizontal: 14.w,
        ),
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: (widget.labelFontSize ?? 13).sp,
        ),
        hintStyle: TextStyle(
          color: Colors.white,
          fontSize: (widget.labelFontSize ?? 13).sp,
        ),
        suffixText: counter,
        suffixStyle: TextStyle(color: Colors.white54, fontSize: 12.sp),
        filled: true,
        fillColor: widget.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.r),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.r),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.r),
          borderSide: BorderSide(color: Color(0xFF64B5F6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.red, width: 2.w),
        ),
      ),
    );
    final height = widget.field.height;
    if (height == null) {
      return textField;
    }
    return SizedBox(height: height.h, child: textField);
  }
}

enum FormFieldType { text, select }

class FormFieldConfig {
  final String name;
  final String label;
  final String? hintText;
  final List<FormFieldValidator<String>>? validators;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextEditingController? textEditingController;
  final bool readonly;
  final bool enabled;
  final bool required;
  final String? labelHelpText;
  final bool showLabelText;

  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? counterTextBuilder;

  /// 多行输入（textarea）相关。
  final int? maxLines;
  final int? minLines;

  /// 固定高度（像素）；设置后输入框固定为改高度，多行内容内部滚动。
  final double? height;

  /// 在 twoColumn 布局中独占一整行。
  final bool fullWidth;

  // 新增字段类型
  final FormFieldType fieldType;

  // 下拉框相关（仅当 fieldType == select 时使用）
  final List<dynamic>? items; // 选项数据源
  final String Function(dynamic)? labelBuilder; // 将选项转为显示文本
  final dynamic initialValue; // 初始选中值
  final void Function(dynamic)? onChanged; // 值改变回调（可选）

  FormFieldConfig({
    required this.name,
    required this.label,
    this.hintText,
    this.validators,
    this.keyboardType,
    this.obscureText = false,
    this.textEditingController,
    this.readonly = false,
    this.enabled = true,
    this.required = false,
    this.labelHelpText,
    this.showLabelText = true,
    this.inputFormatters,
    this.counterTextBuilder,
    this.maxLines,
    this.minLines,
    this.height,
    this.fullWidth = false,
    this.fieldType = FormFieldType.text, // 默认为文本输入
    this.items,
    this.labelBuilder,
    this.initialValue,
    this.onChanged,
  });
}
