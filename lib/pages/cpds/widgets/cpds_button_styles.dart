import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 与 cpds 页面【浏览】按钮保持一致的高度(32)与字号(13)；
/// 不设置 shape，保留各按钮原有的圆角。
ButtonStyle cpdsFilledButtonStyle() => FilledButton.styleFrom(
  minimumSize: Size(0, 36.h),
  textStyle: TextStyle(fontSize: 13.sp),
);

ButtonStyle cpdsTextButtonStyle() => TextButton.styleFrom(
  minimumSize: Size(0, 36.h),
  textStyle: TextStyle(fontSize: 13.sp),
);

ButtonStyle cpdsOutlinedButtonStyle() => OutlinedButton.styleFrom(
  minimumSize: Size(0, 36.h),
  textStyle: TextStyle(fontSize: 13.sp),
);
