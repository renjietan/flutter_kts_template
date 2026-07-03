import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';

import '../../theme/table.theme.dart';
import 'components/InjectEncryptionTable.dart';

class InjectEncryptionStickPager extends StatefulWidget {
  final DataTablePlusTheme theme;
  final ThemePreset themePreset;
  const InjectEncryptionStickPager({
    super.key,
    required this.theme,
    required this.themePreset,
  });

  @override
  State<InjectEncryptionStickPager> createState() =>
      _InjectEncryptStickPagerState();
}

class _InjectEncryptStickPagerState extends State<InjectEncryptionStickPager> {
  int selectIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Column(
            children: [
              Container(
                height: 45,
                padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white70, // 极细的浅色描边
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextTitle(text: "注钥枪管理"),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.add, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 85,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(
                        'Item #$index Item #$index',
                        style: TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                      selectedTileColor: Color(0xFF004098),
                      selected: index == selectIndex,
                      onTap: () {
                        setState(() {
                          selectIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 0),
        Expanded(child: InjectEncryptionTable()),
      ],
    );
  }
}
