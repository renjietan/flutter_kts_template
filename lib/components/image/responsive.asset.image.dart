import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width; // 设计稿中的宽度，逻辑像素
  final double? height; // 设计稿中的高度，逻辑像素
  final BoxFit? fit;

  const ResponsiveAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 使用 screenutil 进行尺寸适配 (逻辑像素)
    //    如果未指定宽高，则设为 null，让图片按原始尺寸或父容器约束显示
    final double? adaptedWidth = width?.w;
    final double? adaptedHeight = height?.w;

    // 2. 获取设备像素密度
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // 3. 计算 cacheWidth 和 cacheHeight (物理像素)
    //    如果 adaptedWidth 或 adaptedHeight 为 null，则对应的 cache 参数也设为 null
    final int? cacheWidth = adaptedWidth != null
        ? (adaptedWidth * pixelRatio).toInt()
        : null;
    final int? cacheHeight = adaptedHeight != null
        ? (adaptedHeight * pixelRatio).toInt()
        : null;

    return Image.asset(
      assetPath,
      width: adaptedWidth, // 控制显示尺寸 (逻辑像素)
      height: adaptedHeight, // 控制显示尺寸 (逻辑像素)
      cacheWidth: cacheWidth, // 控制解码尺寸 (物理像素)，优化内存
      cacheHeight: cacheHeight, // 控制解码尺寸 (物理像素)，优化内存
      fit: fit,
    );
  }
}
