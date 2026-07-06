import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';

import '../../components/text/text.title.dart';
import '../../theme/table.theme.dart';
import '../../utils/enum/dialog_enum.dart';
import 'InjectEncryptionStick.mixin.dart';
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

class _InjectEncryptStickPagerState extends State<InjectEncryptionStickPager>
    with InjectEncryptionStickMixin {
  int selectIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
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
                      onPressed: () {
                        showCustomDialog(DialogTypeEnum.create, null);
                      },
                      icon: Icon(Icons.add, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: data.length == 0
                    ? Center(child: buildEmptyWidget(context))
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data[index].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == "edit") {
                                      showCustomDialog(
                                        DialogTypeEnum.edit,
                                        data[index],
                                      );
                                    } else {
                                      delete(data[index]);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('编辑'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('删除'),
                                    ),
                                  ],
                                ),
                              ],
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
