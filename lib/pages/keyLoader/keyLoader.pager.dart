import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/router/router.dart';

import '../../components/text/text.title.dart';
import '../../theme/table.theme.dart';
import '../../utils/enum/dialog_enum.dart';
import 'components/InjectEncryptionTable.dart';
import 'keyLoader.mixin.dart';

class KeyLoaderPager extends StatefulWidget {
  final DataTablePlusTheme theme;
  final ThemePreset themePreset;
  const KeyLoaderPager({
    super.key,
    required this.theme,
    required this.themePreset,
  });

  @override
  State<KeyLoaderPager> createState() => _InjectEncryptStickPagerState();
}

class _InjectEncryptStickPagerState extends State<KeyLoaderPager>
    with KeyLoaderMixin {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getList();
    });
    router.routeInformationProvider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final currentLocation = router.routerDelegate.currentConfiguration.uri
        .toString();
    // 判断是否是第三个菜单的路径，例如 '/third'
    if (currentLocation == "/injectEncryptStick") {
      getList();
    }
  }

  @override
  void dispose() {
    router.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 210,
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
                    TextTitle(
                      text: t.pager.injectEncrypt.keyLoaderManager,
                      fontSize: 14,
                    ),
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
                child: data.isEmpty
                    ? Center(child: buildEmptyWidget(context))
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            contentPadding: EdgeInsetsGeometry.only(
                              left: 10,
                              right: 0,
                            ),
                            shape: Border(
                              bottom: BorderSide(
                                color: index == selectIndex
                                    ? Color(0xFF004098)
                                    : Colors.grey.shade700,
                                width: 1,
                              ),
                            ),
                            minVerticalPadding: 0,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data[index].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 17),
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
                                getDetails();
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
        Expanded(child: InjectEncryptionTable(allData: tableData)),
      ],
    );
  }
}
