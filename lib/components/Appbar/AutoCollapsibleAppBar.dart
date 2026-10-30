import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_button_styles.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_messages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AutoCollapsibleAppBar extends StatefulWidget {
  /// 标题，由外部传入（已翻译好的文字）。
  final String title;

  /// “确定”按钮点击事件，通常用于提交表单。
  final FutureOr<void> Function() onConfirm;

  /// 追加到 Actions 的其他按钮。
  final List<Widget> actions;

  /// 自定义返回逻辑；不传则默认 pop。
  final VoidCallback? onBack;

  /// 是否隐藏：键盘弹起时，可以从外部传入，让 APPBAR 隐藏
  final bool hideWhenKeyboardVisible;

  const AutoCollapsibleAppBar({
    super.key,
    required this.title,
    required this.onConfirm,
    this.actions = const [],
    this.onBack,
    this.hideWhenKeyboardVisible = true, // 是否隐藏：键盘弹起时，可以从外部传入，让 APPBAR 隐藏
  });

  @override
  State<AutoCollapsibleAppBar> createState() => _AutoCollapsibleAppBarState();
}

class _AutoCollapsibleAppBarState extends State<AutoCollapsibleAppBar> {
  late bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: widget.hideWhenKeyboardVisible
          ? const SizedBox.shrink()
          : SizedBox(
              height: 48.h,
              child: AppBar(
                toolbarHeight: 48.h,
                automaticallyImplyLeading: true,
                backgroundColor: const Color(0xFF20262D),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                leadingWidth: 80.w,
                leading: InkWell(
                  onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 8.w),
                      Transform.translate(
                        offset: Offset(0, 1.sp),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        CpdsMessages.tr(context, '返回', 'Back', 'رجوع'),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15.sp,
                          height: 1.0.h,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(widget.title, style: TextStyle(fontSize: 15.sp)),
                actions: [
                  TextButton(
                    style: cpdsTextButtonStyle(),
                    onPressed: () async {
                      if (loading == true) return;
                      try {
                        loading = true;
                        widget.onConfirm();
                      } finally {
                        loading = false;
                      }
                    },
                    child: Text(
                      CpdsMessages.tr(context, '确定', 'Confirm', 'تأكيد'),
                      style: TextStyle(
                        color: const Color(0xFF00A2E9),
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  ...widget.actions,
                  SizedBox(width: 15.w),
                ],
              ),
            ),
    );
  }
}
