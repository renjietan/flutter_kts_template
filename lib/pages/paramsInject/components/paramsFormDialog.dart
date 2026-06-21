import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/pages/paramsInject/components/paramsInjectTable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../../components/TextField/simple.form.textfield.dart';
import '../../../components/button/base.button.dart';
import '../../../theme/table.theme.dart';

class ParamsFormDialog {
  static DataTablePlusTheme theme = getThemePreset(ThemePreset.dark);
  static void showDialog({
    required String title,
    required List<FormFieldConfig> fields,
    required void Function(Map<String, dynamic> formData) onConfirm,
    String confirmText = 'Save',
    String cancelText = 'Cancel',
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
  }) {
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
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        // content: SingleChildScrollView(
        //   child: SizedBox(
        //     width: 1000.w,
        //     child: FormBuilder(key: formKey, child: ParamsInjectTable()),
        //   ),
        // ),
        content: SizedBox(
          width: 1000.w,
          height: 1300.h,
          child: SingleChildScrollView(
            child: FormBuilder(key: formKey, child: ParamsInjectTable()),
          ),
          // child: FormBuilder(key: formKey, child: ParamsInjectTable()),
        ),
        actions: [
          Row(
            children: [
              const Spacer(),
              BaseButton(
                label: cancelText,
                width: 70,
                colors: [
                  Color(0xFF42474E),
                  Color(0xFF42474E),
                  Color(0xFF42474E),
                  Color(0xFF42474E),
                ],
                onPressed: () {
                  SmartDialog.dismiss();
                },
              ),
              const SizedBox(width: 10),
              BaseButton(
                label: confirmText,
                width: 70,
                onPressed: () {
                  if (formKey.currentState?.saveAndValidate() ?? false) {
                    final formData = formKey.currentState?.value;
                    SmartDialog.dismiss();
                    onConfirm(formData!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
