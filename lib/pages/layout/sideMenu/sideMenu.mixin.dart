import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.model.dart';
import 'package:flutter_kts_template/utils/provider/menu_provider.dart';
import 'package:provider/provider.dart';

import '../../../icons/hy_icons.dart';

mixin SideMenuMixin<T extends StatefulWidget> on State<T> {
  final List<MenuItem> _menuItems = const [
    MenuItem(icon: HyIcons.canshujiazhu, label: '参数加注'),
    MenuItem(icon: HyIcons.diantaiguanli, label: '电台管理'),
    MenuItem(icon: HyIcons.zhuyueqiangguanli, label: '注销管理'),
  ];
  final selectedStyle = {
    "0": const {
      // 未选中
      "bg_color": Colors.transparent,
      "color": Colors.white,
      "font-weight": FontWeight.w500,
    },
    "1": const {
      // 选中
      "bg_color": Color(0xFF122339),
      "color": Color.fromRGBO(12, 181, 255, 1),
      "font-weight": FontWeight.normal,
    },
  };
  int _selectedIndex = 0;

  List<Widget> buildMenuItems(BuildContext ctx, void Function(int) onSelected) {
    return List.generate(_menuItems.length, (index) {
      final item = _menuItems[index];
      final isSelected = _selectedIndex == index;
      final _selectedStyle = isSelected
          ? selectedStyle["1"]
          : selectedStyle["0"];
      // final bgColor = _selectedStyle!["bg_color"];
      // 手势识别器
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            context.read<MenuProvider>().selectedIndex = index;
            onSelected(index);
          });
        },
        child: Container(
          width: 70,
          // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _selectedStyle!["bg_color"] as Color,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 28,
                // color:  Colors.white.withOpacity(0.85),
                color: _selectedStyle["color"] as Color,
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: _selectedStyle["font-weight"] as FontWeight,
                  // color: Colors.white.withOpacity(0.9),
                  color: _selectedStyle["color"] as Color,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }
}
