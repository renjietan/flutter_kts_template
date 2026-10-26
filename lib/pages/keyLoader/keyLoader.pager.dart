// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

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
  AppLocale? _lastLocale;
  bool _wasVisible = false;
  final ScrollController _scrollTableController = ScrollController();

  @override
  void dispose() {
    _scrollTableController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = TranslationProvider.of(context).locale;
    if (_lastLocale != null && _lastLocale != locale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SmartDialog.dismiss();
        nameTextEditController.clear();
      });
    }
    _lastLocale = locale;

    // IndexedStack 分支切换时，TickerMode 会从 false 变为 true。
    // 用它判断“页面从不可见变为可见”，比监听路由信息更可靠。
    final isVisible = TickerMode.of(context);
    if (isVisible && !_wasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          getList();
          getRadios();
        }
      });
    }
    _wasVisible = isVisible;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        SizedBox(
          width: rtl ? 200 : 140,
          child: Column(
            children: [
              Container(
                height: 45.h,
                padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 6, 0),
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
                          child: Icon(Icons.add, size: 18, color: Colors.white),
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
                            contentPadding: EdgeInsetsDirectional.only(
                              start: 10.w,
                              end: 0,
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
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, size: 17.sp),
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
          child: defaultTargetPlatform == TargetPlatform.windows
              ? KeyLoaderDetailsTable(
                  keyLoaderEntity: selectKeyLoader,
                  refreshToken: refreshToken,
                )
              : Scrollbar(
                  controller: _scrollTableController,
                  thumbVisibility: true, // 常驻显示滚动条（移动端默认是滚动时才显示）
                  trackVisibility: true, // 显示轨道（需 thumbVisibility 为 true）
                  thickness: 4,
                  radius: const Radius.circular(2),
                  scrollbarOrientation:
                      ScrollbarOrientation.bottom, // 横向时建议显式指定
                  child: SingleChildScrollView(
                    controller: _scrollTableController, // 必须与 Scrollbar 共用
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1500.w,
                      child: KeyLoaderDetailsTable(
                        keyLoaderEntity: selectKeyLoader,
                        refreshToken: refreshToken,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
