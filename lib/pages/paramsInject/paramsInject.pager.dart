import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/tree-view/tree-view.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager> with ParamsInjectMixin {
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
