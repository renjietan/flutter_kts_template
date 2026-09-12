import 'package:flutter/material.dart';
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
  Color maskColor = const Color(0x1AFFFFFF),
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
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      titlePadding: EdgeInsets.symmetric(vertical: 7),
      contentPadding: EdgeInsets.fromLTRB(5, 15, 0, 0),
      titleTextStyle: TextStyle(fontSize: 16, color: titleColor),
      title: Container(
        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.white38, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 15),
            TextTitle(text: title, fontSize: titleFontSize, color: titleColor),
            const Spacer(),
            IconButton(
              onPressed: () => SmartDialog.dismiss(),
              icon: Icon(Icons.close_rounded, size: 16, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      content: SizedBox(
        width: dialogWidth ?? 320,
        child: FormBuilder(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
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
          minWidth: confirmBtnMinWidth,
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
        alignment: Alignment.centerLeft,
        margin: EdgeInsetsGeometry.only(top: i == 0 ? 0 : 20, bottom: 20),
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
          items: field.items ?? [],
          labelBuilder: field.labelBuilder ?? (v) => v,
          initialValue: field.initialValue,
          onChanged: field.onChanged,
          decoration: InputDecoration(
            labelText: field.hintText ?? field.label,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            labelStyle: TextStyle(color: Colors.white, fontSize: labelFontSize),
            hintStyle: TextStyle(color: Colors.white, fontSize: labelFontSize),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF64B5F6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
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
  widgets.add(SizedBox(height: 60));
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
  for (var i = 0; i < fields.length; i += 2) {
    final first = _buildFieldItem(
      context,
      fields[i],
      labelColor,
      fillColor,
      borderColor,
      labelFontSize,
      contentPadding,
    );
    final second = i + 1 < fields.length
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
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      ),
    );
    rows.add(const SizedBox(height: 14));
  }
  rows.add(const SizedBox(height: 48));
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
          items: field.items ?? [],
          labelBuilder: field.labelBuilder ?? (v) => v,
          initialValue: field.initialValue,
          onChanged: field.onChanged,
          decoration: InputDecoration(
            labelText: field.hintText ?? field.label,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: contentPadding,
              horizontal: 12,
            ),
            labelStyle: TextStyle(color: Colors.white, fontSize: labelFontSize),
            hintStyle: TextStyle(color: Colors.white, fontSize: labelFontSize),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Color(0xFF64B5F6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
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
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 14),
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
                style: TextStyle(color: labelColor, fontSize: labelFontSize),
              ),
            ],
          ),
        )
      : Text(
          field.label,
          textAlign: TextAlign.left,
          style: TextStyle(color: labelColor, fontSize: labelFontSize),
        );

  final helpText = field.labelHelpText;
  if (helpText == null || helpText.isEmpty) return text;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      text,
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF20262D),
              title: Text(
                context.t.tips.title,
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              content: Text(
                helpText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
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
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF00A2E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
        ),
      ),
    ],
  );
}
