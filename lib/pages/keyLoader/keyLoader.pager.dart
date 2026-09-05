import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/dialog/simple.tips.dialog.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/router/router.dart';

import '../../components/text/text.title.dart';
import '../../theme/table.theme.dart';
import '../../utils/enum/dialog_enum.dart';
import 'components/key_loader_details_table.dart';
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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getList();
    });
    router.routeInformationProvider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final currentLocation = router.routerDelegate.currentConfiguration.uri
        .toString();
    // 判断是否是第三个菜单的路径，例如 '/injectEncryptStick'
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
          width: 140,
          child: Column(
            children: [
              Container(
                height: 45,
                padding: EdgeInsets.fromLTRB(10, 0, 6, 0),
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
                    Tooltip(
                      message: t.button.injectEncrypt.create,
                      child: InkWell(
                        onTap: () =>
                            showCustomDialog(DialogTypeEnum.create, null),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
                                color: data[index].id == selectKeyLoader?.id
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
                                      SimpleTipsDialog(
                                        context,
                                        title: t.tips.keyLoaders.delete,
                                        contentText:
                                            t.tips.keyLoaders.confirmDelete,
                                        func: () {
                                          delete(data[index]);
                                        },
                                      );
                                      // delete(data[index]);
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final ts = Translations.of(context);
                                    return [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          ts.button.radioManager.edit,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          ts.button.radioManager.delete,
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                            selectedTileColor: Color(0xFF004098),
                            selected: data[index].id == selectKeyLoader?.id,
                            onTap: () {
                              setState(() {
                                selectKeyLoader = data[index];
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
        Expanded(
          child: KeyLoaderDetailsTable(
            keyLoaderEntity: selectKeyLoader,
            refreshToken: refreshToken,
          ),
        ),
      ],
    );
  }
}
