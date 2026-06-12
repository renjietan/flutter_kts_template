import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/tree-view/tree-view.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

Future<void> _showLoginDialog() async {
  final _formKey = GlobalKey<FormBuilderState>();
  SmartDialog.show(
    clickMaskDismiss: true,
    maskColor: Colors.white.withOpacity(0.1),
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.w)),
      child: Padding(
        // 关键：根据键盘高度增加底部内边距，让弹窗整体上移，但按钮始终在弹窗底部
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          // 限制弹窗最大高度，避免超出屏幕
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ----- 标题区域（固定）-----
              Container(
                padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x4D21262C), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "新增电台",
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // ----- 滚动的内容区域（Expanded 保证占满剩余空间）-----
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(30.w, 16.h, 30.w, 16.h),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(bottom: 20.h),
                          child: Text(
                            "Device Type",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        FormBuilderTextField(
                          name: 'deviceType',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 20.h,
                              horizontal: 12.w,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                            filled: true,
                            fillColor: Color(0x9921262C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(top: 30.h, bottom: 20.h),
                          child: Text(
                            "Network Interface",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        FormBuilderTextField(
                          name: 'networkInterface',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 20.h,
                              horizontal: 12.w,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                            filled: true,
                            fillColor: Color(0x9921262C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
              // ----- 底部按钮区域（固定）-----
              Padding(
                padding: EdgeInsets.fromLTRB(30.w, 16.h, 30.w, 24.h),
                child: FlareButton(
                  label: "新增电台",
                  textStyle: TextStyle(fontSize: 12.sp),
                  height: 56.h, // 合理高度
                  borderRadius: 15.r,
                  colors: const [
                    Color(0xFF00A2E9),
                    Color(0xFF00A2E9),
                    Color(0xFF00A2E9),
                    Color(0xFF00A2E9),
                  ],
                  onPressed: () {
                    SmartDialog.dismiss();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ParamsInject extends StatefulWidget {
  final String text;
  const ParamsInject({super.key, required this.text});

  @override
  State<ParamsInject> createState() => _ParamsInjectState();
}

class _ParamsInjectState extends State<ParamsInject> with ParamsInjectMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _buildPlaceholderArea(paths)),
        Expanded(flex: 3, child: _buildPlaceholderArea(paths)),
      ],
    );
  }
}

/// 占位区域：中间/右侧留白空组件，仅用于展示比例与布局
Widget _buildPlaceholderArea(List<Uri> paths) {
  return Container(
    decoration: BoxDecoration(
      // 极浅的分隔线，仅用于视觉参考 (符合留白风格，不影响主体)
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(14.w, 15.h, 0, 15.h),
            child: Text("File Parse", style: TextStyle(fontSize: 20.sp)),
          ),
        ),
        Expanded(child: TreeView(paths: paths)),
      ],
    ),
  );
}
