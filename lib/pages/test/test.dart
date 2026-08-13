import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/test/cpds_page.dart';

class TestPager extends StatefulWidget {
  const TestPager({super.key});

  @override
  State<TestPager> createState() => _TestPagerState();
}

class _TestPagerState extends State<TestPager> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: CpdsPage()));
  }
}
