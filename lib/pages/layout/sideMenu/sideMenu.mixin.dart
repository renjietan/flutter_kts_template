import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.model.dart';
import 'package:provider/provider.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../../icons/hy_icons.dart';
import '../../../utils/provider/menu.provider.dart';

mixin SideMenuMixin<T extends StatefulWidget> on State<T> {
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

  int selectedIndex = 0;

  List<Widget> buildMenuItems(BuildContext ctx, void Function(int) onSelected) {
    late final t = Translations.of(ctx);
    final menuIndex = Provider.of<MenuProvider>(context);
    List<MenuItem> menuItems = [
      MenuItem(icon: HyIcons.canshujiazhu, label: t.app.appbar.paramsInject),
      MenuItem(icon: HyIcons.diantaiguanli, label: t.app.appbar.radioManager),
      MenuItem(icon: HyIcons.zhuyueqiangguanli, label: t.app.appbar.keyManager),
      MenuItem(icon: Icons.thirteen_mp_outlined, label: "测试"),
    ];
    return List.generate(menuItems.length, (index) {
      final item = menuItems[index];
      final isSelected = menuIndex.selectedIndex == index;
      final style = isSelected ? selectedStyle["1"] : selectedStyle["0"];
      // 手势识别器
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
            ctx.read<MenuProvider>().selectedIndex = index;
            onSelected(index);
          });
        },
        child: Container(
          width: 70,
          // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: style!["bg_color"] as Color),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 28,
                // color:  Colors.white.withOpacity(0.85),
                color: style["color"] as Color,
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: style["font-weight"] as FontWeight,
                  // color: Colors.white.withOpacity(0.9),
                  color: style["color"] as Color,
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
