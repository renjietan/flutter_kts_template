import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/splash/splash.mixin.dart';

import '../../components/image/responsive.asset.image.dart';

//类似广告启动页
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SplashMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: ResponsiveAssetImage(
        'assets/appbar/logo.png',
        width: 150,
        height: 150,
      ),
    );
  }
}
