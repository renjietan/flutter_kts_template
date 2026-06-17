import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../TextField/simple.form.textfield.dart';
import '../button/base.button.dart';

/// 表单字段配置模型

/// 显示通用表单对话框
Future<void> SimpleFormDialog({
  required String title,
  required List<FormFieldConfig> fields,
  required void Function(Map<String, dynamic> formData) onConfirm,
  String confirmText = '确认',
  Color? backgroundColor = Colors.black,
  Color? titleColor = Colors.white,
  Color? labelColor = Colors.white,
  Color? fieldFillColor = const Color(0x9921262C),
  Color? fieldBorderColor = Colors.white,
  double borderRadius = 10,
  double titleFontSize = 16,
  double labelFontSize = 12,
  double fieldLabelFontSize = 12,
  bool clickMaskDismiss = false,
  Color maskColor = const Color(0x1AFFFFFF),
}) async {
  final formKey = GlobalKey<FormBuilderState>();
  SmartDialog.show(
    clickMaskDismiss: clickMaskDismiss,
    maskColor: maskColor,
    builder: (context) => AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      titlePadding: EdgeInsets.fromLTRB(0, 15.h, 0, 15.h),
      actionsPadding: EdgeInsets.fromLTRB(
        30.w,
        25.h,
        30.w,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 20.h : 90.h,
      ),
      contentPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 25.h),
      titleTextStyle: TextStyle(fontSize: 14, color: titleColor),
      title: Container(
        padding: EdgeInsets.fromLTRB(18.w, 15.h, 18.w, 15.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.white38, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: titleFontSize.sp, color: titleColor),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => SmartDialog.dismiss(),
              icon: Icon(Icons.close_rounded, size: 16, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      content: SingleChildScrollView(
        child: SizedBox(
          width: 270.w,
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildFormFields(
                fields,
                labelColor!,
                fieldFillColor!,
                fieldBorderColor!,
                fieldLabelFontSize,
              ),
            ),
          ),
        ),
      ),
      actions: [
        BaseButton(
          label: confirmText,
          height: 100.h,
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
  List<FormFieldConfig> fields,
  Color labelColor,
  Color fillColor,
  Color borderColor,
  double labelFontSize,
) {
  final List<Widget> widgets = [];
  for (int i = 0; i < fields.length; i++) {
    final field = fields[i];
    widgets.add(
      Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsetsGeometry.only(top: i == 0 ? 0 : 45.h, bottom: 45.h),
        child: Text(
          field.label,
          textAlign: TextAlign.left,
          style: TextStyle(color: labelColor, fontSize: labelFontSize.sp),
        ),
      ),
    );
    // 添加输入框
    widgets.add(SimpleFormTextField(field: field, fillColor: fillColor, labelFontSize: labelFontSize,));
  }
  // 最后加一个底部间距
  widgets.add(SizedBox(height: 60.h));
  return widgets;
}
