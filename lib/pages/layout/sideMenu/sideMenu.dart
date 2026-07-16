import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SideMenu extends StatefulWidget {
  final void Function(int index) onSelected;
  const SideMenu({super.key, required this.onSelected});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with SideMenuMixin {
  @override
  Widget build(BuildContext context) {
    // setState(() {
    //   selectedIndex = menuIndex.selectedIndex;
    // });
    return SizedBox(
      width: 70,
      child: Container(
        color: const Color(0xFF171C22),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ...buildMenuItems(context, widget.onSelected),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
