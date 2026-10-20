import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 三端响应式基准（设备桶）。
///
/// - 手机：恒横屏，原生逻辑尺寸 780 × 360，1:1 显示。
/// - Pad：恒横屏，原生逻辑尺寸 1024 × 640，1:1 显示。
/// - Windows：固定 1:1 显示（不缩放）并冻结，窗口变化不重算（不放大、不变形）。
enum DeviceBucket { phoneLandscape, padLandscape, windows }

/// 根据设备桶计算 designSize、缩放策略与布局切换阈值的统一入口。
class ScreenStrategy {
  ScreenStrategy._();

  /// 手机横屏设计画布（逻辑 dp）。
  static const Size phoneDesignSize = Size(780, 360);

  /// Pad 横屏设计画布（逻辑 dp）。
  static const Size padDesignSize = Size(1024, 640);

  /// Windows 固定缩放系数（宽高统一，保证不变形）。
  static const double windowsScale = 1.0;

  /// 单栏 / 双栏切换阈值（逻辑宽度，dp）。
  static const double masterDetailBreakpoint = 900;

  /// 判定当前设备属于哪个桶。
  static DeviceBucket bucketOf({
    required bool isWindows,
    required Size logicalSize,
  }) {
    if (isWindows) return DeviceBucket.windows;
    return logicalSize.width >= masterDetailBreakpoint
        ? DeviceBucket.padLandscape
        : DeviceBucket.phoneLandscape;
  }

  /// 根据桶与启动时逻辑尺寸得到 designSize。
  ///
  /// Windows 用「启动窗口逻辑尺寸 ÷ windowsScale(1.0)」作为画布，
  /// 使缩放系数恒定为 1.0（即 1:1 显示）。
  static Size designSizeOf(DeviceBucket bucket, Size logicalSize) {
    switch (bucket) {
      case DeviceBucket.phoneLandscape:
        return phoneDesignSize;
      case DeviceBucket.padLandscape:
        return padDesignSize;
      case DeviceBucket.windows:
        return Size(
          logicalSize.width / windowsScale,
          logicalSize.height / windowsScale,
        );
    }
  }

  /// 是否冻结缩放：Windows 冻结（窗口变化不重算），移动端随尺寸变化重算。
  static RebuildFactor rebuildFactorOf(DeviceBucket bucket) {
    return bucket == DeviceBucket.windows
        ? RebuildFactors.none
        : RebuildFactors.size;
  }
}
