import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.selectField.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../TextField/simple.form.textfield.dart';
import '../button/base.button.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

/// 表单字段配置模型

/// 显示通用表单对话框
Future<void> SimpleFormDialog({
  required String title,
  required List<FormFieldConfig> fields,
  required void Function(Map<String, dynamic> formData) onConfirm,
  String? confirmText,
  double? confirmBtnMinWidth = 150,
  Color? backgroundColor = Colors.black,
  Color? titleColor = Colors.white,
  Color? labelColor = Colors.white,
  Color? fieldFillColor = const Color(0x9921262C),
  Color? fieldBorderColor = Colors.white,
  double borderRadius = 10,
  double titleFontSize = 14,
  double labelFontSize = 14,
  double fieldLabelFontSize = 13,
  double fieldContentPadding = 10,
  double? dialogWidth,
  bool twoColumn = false,
  bool clickMaskDismiss = false,
  Color maskColor = Colors.black54,
}) async {
  final formKey = GlobalKey<FormBuilderState>();
  SmartDialog.show(
    useAnimation: true,
    keepSingle: true,
    animationType: SmartAnimationType.scale,
    clickMaskDismiss: clickMaskDismiss,
    maskColor: maskColor,
    builder: (context) => AlertDialog(
      scrollable: true,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
      titlePadding: EdgeInsets.symmetric(vertical: 7.h),
      contentPadding: EdgeInsets.fromLTRB(5.w, 15.h, 0, 0),
      titleTextStyle: TextStyle(fontSize: 16.sp, color: titleColor),
      title: Container(
        padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 5.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white38, width: 1.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 15.w),
            TextTitle(text: title, fontSize: titleFontSize, color: titleColor),
            const Spacer(),
            IconButton(
              onPressed: () => SmartDialog.dismiss(),
              icon: Icon(
                Icons.close_rounded,
                size: 16.sp,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      content: SizedBox(
        width: dialogWidth ?? 320.w,
        child: FormBuilder(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: twoColumn
                ? _buildTwoColumnFields(
                    context,
                    fields,
                    labelColor!,
                    fieldFillColor!,
                    fieldBorderColor!,
                    fieldLabelFontSize,
                    fieldContentPadding,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildFormFields(
                      context,
                      fields,
                      labelColor!,
                      fieldFillColor!,
                      fieldBorderColor!,
                      fieldLabelFontSize,
                      fieldContentPadding,
                    ),
                  ),
          ),
        ),
      ),
      actions: [
        BaseButton(
          minWidth: confirmBtnMinWidth?.w,
          height: 34.h,
          textStyle: TextStyle(fontSize: 13.sp, color: Colors.white),
          label: confirmText ?? context.t.common.confirm,
          onPressed: () {
            // 验证通过，获取表单数据
            if (formKey.currentState?.saveAndValidate() ?? false) {
              final formData = formKey.currentState?.value;
              // 可将 formData 作为参数传给 onConfirm，但这里保持简单
              SmartDialog.dismiss();
              onConfirm(formData!);
            }
          },
        ),
      ],
    ),
  );
}

/// 构建表单字段列表（支持任意数量）
List<Widget> _buildFormFields(
  BuildContext context,
  List<FormFieldConfig> fields,
  Color labelColor,
  Color fillColor,
  Color borderColor,
  double labelFontSize,
  double contentPadding,
) {
  final List<Widget> widgets = [];
  for (int i = 0; i < fields.length; i++) {
    final field = fields[i];
    widgets.add(
      Container(
        alignment: AlignmentDirectional.centerStart,
        margin: EdgeInsetsGeometry.only(top: i == 0 ? 0 : 20.h, bottom: 20.h),
        child: _buildFieldLabel(context, field, labelColor, labelFontSize),
      ),
    );
    // 添加输入框
    if (field.fieldType == FormFieldType.text) {
      widgets.add(
        SimpleFormTextField(
          field: field,
          fillColor: fillColor,
          labelFontSize: labelFontSize,
          contentPadding: contentPadding,
        ),
      );
    } else {
      widgets.add(
        SimpleFormSelectField<dynamic>(
          name: field.name,
          items: field.items ?? [],
          labelBuilder: field.labelBuilder ?? (v) => v,
          initialValue: field.initialValue,
          onChanged: field.onChanged,
          decoration: InputDecoration(
            labelText: field.hintText ?? field.label,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 12.w,
            ),
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: labelFontSize.sp,
            ),
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: labelFontSize.sp,
            ),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF64B5F6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red, width: 2.w),
            ),
          ),
          validator: field.validators != null
              ? (value) {
                  // 将验证器转换为 FormFieldValidator 可用的形式
                  for (var validator in field.validators!) {
                    final error = validator(value?.toString() ?? '');
                    if (error != null) return error;
                  }
                  return null;
                }
              : null,
        ),
      );
    }
  }
  // 最后加一个底部间距
  widgets.add(SizedBox(height: 60.h));
  return widgets;
}

Widget _buildTwoColumnFields(
  BuildContext context,
  List<FormFieldConfig> fields,
  Color labelColor,
  Color fillColor,
  Color borderColor,
  double labelFontSize,
  double contentPadding,
) {
  final rows = <Widget>[];
  var i = 0;
  while (i < fields.length) {
    final current = fields[i];
    if (current.fullWidth) {
      rows.add(
        _buildFieldItem(
          context,
          current,
          labelColor,
          fillColor,
          borderColor,
          labelFontSize,
          contentPadding,
        ),
      );
      i += 1;
    } else {
      final hasSecond = i + 1 < fields.length && !fields[i + 1].fullWidth;
      final first = _buildFieldItem(
        context,
        current,
        labelColor,
        fillColor,
        borderColor,
        labelFontSize,
        contentPadding,
      );
      final second = hasSecond
          ? _buildFieldItem(
              context,
              fields[i + 1],
              labelColor,
              fillColor,
              borderColor,
              labelFontSize,
              contentPadding,
            )
          : const SizedBox();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            SizedBox(width: 16.w),
            Expanded(child: second),
          ],
        ),
      );
      i += hasSecond ? 2 : 1;
    }
    rows.add(SizedBox(height: 14.h));
  }
  rows.add(SizedBox(height: 48.h));
  return Column(mainAxisSize: MainAxisSize.min, children: rows);
}

Widget _buildFieldItem(
  BuildContext context,
  FormFieldConfig field,
  Color labelColor,
  Color fillColor,
  Color borderColor,
  double labelFontSize,
  double contentPadding,
) {
  final label = _buildFieldLabel(context, field, labelColor, labelFontSize);

  final input = field.fieldType == FormFieldType.text
      ? SimpleFormTextField(
          field: field,
          fillColor: fillColor,
          labelFontSize: labelFontSize,
          contentPadding: contentPadding,
        )
      : SimpleFormSelectField<dynamic>(
          name: field.name,
          items: field.items ?? [],
          labelBuilder: field.labelBuilder ?? (v) => v,
          initialValue: field.initialValue,
          onChanged: field.onChanged,
          decoration: InputDecoration(
            labelText: field.hintText ?? field.label,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: contentPadding.h,
              horizontal: 12.w,
            ),
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: labelFontSize.sp,
            ),
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: labelFontSize.sp,
            ),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Color(0xFF64B5F6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red, width: 2.w),
            ),
          ),
          validator: field.validators != null
              ? (value) {
                  for (var validator in field.validators!) {
                    final error = validator(value?.toString() ?? '');
                    if (error != null) return error;
                  }
                  return null;
                }
              : null,
        );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        alignment: AlignmentDirectional.centerStart,
        margin: EdgeInsets.only(bottom: 14.h),
        child: label,
      ),
      input,
    ],
  );
}

Widget _buildFieldLabel(
  BuildContext context,
  FormFieldConfig field,
  Color labelColor,
  double labelFontSize,
) {
  final text = field.required
      ? Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '* ',
                style: TextStyle(color: Colors.red),
              ),
              TextSpan(
                text: field.label,
                style: TextStyle(color: labelColor, fontSize: labelFontSize.sp),
              ),
            ],
          ),
          textAlign: TextAlign.start,
        )
      : Text(
          field.label,
          textAlign: TextAlign.start,
          style: TextStyle(color: labelColor, fontSize: labelFontSize.sp),
        );

  final helpText = field.labelHelpText;
  if (helpText == null || helpText.isEmpty) return text;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      text,
      SizedBox(width: 6.w),
      GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF20262D),
              title: Text(
                context.t.tips.title,
                style: TextStyle(color: Colors.white, fontSize: 17.sp),
              ),
              content: Text(
                helpText,
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.t.tips.ok),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 16.w,
          height: 16.h,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF00A2E9),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.priority_high, color: Colors.white, size: 12.sp),
        ),
      ),
    ],
  );
}

/// 通用表单页面（移动端使用）：表单项与 [SimpleFormDialog] 保持一致。
class SimpleFormPage extends StatefulWidget {
  const SimpleFormPage({
    super.key,
    required this.title,
    required this.fields,
    required this.onConfirm,
    this.confirmText,
    this.twoColumn = false,
    this.labelFontSize = 14,
    this.fieldContentPadding = 10,
    this.backgroundColor = const Color(0xFF20262D),
  });

  final String title;
  final List<FormFieldConfig> fields;
  final void Function(Map<String, dynamic> formData) onConfirm;
  final String? confirmText;
  final bool twoColumn;
  final double labelFontSize;
  final double fieldContentPadding;
  final Color backgroundColor;

  @override
  State<SimpleFormPage> createState() => _SimpleFormPageState();
}

class _SimpleFormPageState extends State<SimpleFormPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState?.value;
      Navigator.of(context).pop();
      widget.onConfirm(formData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelColor = Colors.white;
    const fillColor = Color(0x9921262C);
    const borderColor = Colors.white;
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(32.h),
        child: AppBar(
          backgroundColor: widget.backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(widget.title, style: TextStyle(fontSize: 15.sp)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.twoColumn
                    ? _buildTwoColumnFields(
                        context,
                        widget.fields,
                        labelColor,
                        fillColor,
                        borderColor,
                        widget.labelFontSize,
                        widget.fieldContentPadding,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildFormFields(
                          context,
                          widget.fields,
                          labelColor,
                          fillColor,
                          borderColor,
                          widget.labelFontSize,
                          widget.fieldContentPadding,
                        ),
                      ),
                SizedBox(height: 12.h),
                BaseButton(
                  minWidth: double.infinity,
                  height: 36.h,
                  textStyle: TextStyle(fontSize: 13.sp, color: Colors.white),
                  label: widget.confirmText ?? context.t.common.confirm,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
