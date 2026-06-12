import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/pages/paramsInject/tree-view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

Future<void> _showLoginDialog() async {
  final _formKey = GlobalKey<FormBuilderState>();

  SmartDialog.show(
    clickMaskDismiss: false,
    maskColor: Colors.white.withOpacity(0.1), // 半透明白色遮罩
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black, // 设置背景色为淡黄色
      shape: RoundedRectangleBorder(       // 自定义形状
        borderRadius: BorderRadius.circular(7.w), // 设置圆角半径为15
      ),
      titlePadding: EdgeInsets.fromLTRB(0, 15.h, 0, 15.h),
      actionsPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 90.h),
      contentPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 25.h),
      titleTextStyle:  TextStyle(
          fontSize: 14,
          color: Colors.white
      ),
      title: Container(
        padding: EdgeInsets.fromLTRB(18.w, 30.h, 18.w, 30.h),
        decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x4D21262C), width: 1),
            ),
        ),
        child: Row(
          children: [
            Text("新增电台", style: TextStyle(
                fontSize: 16.sp
            ),),
          ],
        )
      ),
      actionsAlignment: MainAxisAlignment.center,
      content: Container(
        width: 270.w,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsetsGeometry.only(
                  top: 0,
                  bottom: 45.h
                ),
                child: Text("Device Type",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500
                    )),
              ),
              FormBuilderTextField(
                name: 'field1',
                decoration: InputDecoration(
                  labelText: '字段1',
                  isDense: true, // 紧凑布局
                  contentPadding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 12.w), // 控制高度
                  labelStyle: TextStyle(
                    color: Colors.white, // 标签颜色
                    fontSize: 11.sp,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white, // 提示文字颜色（如果设置 hintText）
                    fontSize: 11.sp,
                  ),
                  // 背景色
                  filled: true,
                  fillColor: 	Color(0x9921262C),
                  // 框线（边框）
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // 未聚焦时无边框（可根据需要调整）
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  // 可调整内容内边距
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsetsGeometry.only(
                    top: 45.h,
                    bottom: 45.h
                ),
                child: Text("Network Interface",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                        fontWeight: FontWeight.w500
                    )),
              ),
              FormBuilderTextField(
                name: 'field1',
                decoration: InputDecoration(
                  labelText: '字段1',
                  isDense: true, // 紧凑布局
                  contentPadding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 12.w), // 控制高度
                  labelStyle: TextStyle(
                    color: Colors.white, // 标签颜色
                    fontSize: 11.sp,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white, // 提示文字颜色（如果设置 hintText）
                    fontSize: 11.sp,
                  ),
                  // 背景色
                  filled: true,
                  fillColor: 	Color(0x9921262C),
                  // 框线（边框）
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // 未聚焦时无边框（可根据需要调整）
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  // 可调整内容内边距
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
      actions: [
        FlareButton(
          label: "新增电台",
          textStyle: TextStyle(
            fontSize: 12.sp
          ),
          height: 100.h,
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
      ],
    ),
  );
}

class ParamsInject extends StatefulWidget {
  final String text;
  const ParamsInject({super.key, required this.text});

  @override
  State<ParamsInject> createState() => _ParamsInjectState();
}

class _ParamsInjectState extends State<ParamsInject> {
  @override
  Widget build(BuildContext context) {
    _showLoginDialog();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4,child: _buildPlaceholderArea("${widget.text}中间")),
        Expanded(flex: 3,child: _buildPlaceholderArea("${widget.text}右侧"))
      ],
    );
  }
}


/// 占位区域：中间/右侧留白空组件，仅用于展示比例与布局
Widget _buildPlaceholderArea(String hintText) {
  return Container(
    decoration: BoxDecoration(
      // 极浅的分隔线，仅用于视觉参考 (符合留白风格，不影响主体)
      border: Border.all(
        color: Colors.white.withOpacity(0.05),
        width: 0.5,
      ),
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(
                14.w,
                15.h,
                0,
                15.h
              ),
            child: Text("File Parse", style: TextStyle(
              fontSize: 20.sp,
            )),
          )
        ),
        Expanded(child: TreeView())
      ],
    )
  );
}