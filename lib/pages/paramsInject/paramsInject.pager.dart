import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.dart';
import 'package:flutter_kts_template/components/FileUploads/fileUploads.dart';
import 'package:flutter_kts_template/components/TextField/simple.filter.search.textField.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:flutter_kts_template/components/loading/simple.async.loading.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/core/express.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:provider/provider.dart';
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';

import '../../components/button/base.button.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  @override
  void initState() {
    super.initState();

    LocaleSettings.getLocaleStream().listen((event) {
      resetMasterTree();
      initLeftTree(null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SimplePopup.loading();
      // 在这个页面进行初始化，减轻【启动页】负担
      Future.wait([DatabaseManager.init(), Express.start(), initUdp()]).then((
        res,
      ) async {
        var radioResponse = await RadiosManagerApi.getAll();
        List<RadiosEntity> radios = radioResponse.data.list;
        if (mounted) {
          RadiosProvider radiosProvider = Provider.of<RadiosProvider>(
            context,
            listen: false,
          );
          radiosProvider.setRadios = radios;
        }
        resetMasterTree();
        initLeftTree(null);
        SimpleAsyncPopup.hideLoading(Duration(milliseconds: 300));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeData.dark().primaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: _buildMasterTree(context)),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 5, child: _buildDetailTree(context)),
        ],
      ),
    );
  }

  /// master tree
  Widget _buildMasterTree(BuildContext ctx) {
    final t = Translations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        BaseButton(
          label: "测试 套接字 广播",
          onPressed: () {
            initSocket();
          },
        ),
        BaseButton(
          label: "关闭",
          onPressed: () {
            dtc.socketIOManager?.disconnect();
          },
        ),
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(16, 10, 0, 0),
          child: TextTitle(text: t.pager.radioManager.fileParse),
        ),
        FileUploads(
          onUpdate: (String path) {
            resetMasterTree();
            initLeftTree(path);
          },
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF171C22),
                border: Border.all(
                  width: 1,
                  color: Color(0x8A00A2E9),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(16, 5, 0, 10),
                    child: Row(
                      children: [
                        Text(
                          t.pager.radioManager.netNode,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  DataTablePlusThemeProvider(
                    theme: getThemePreset(ThemePreset.dark),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      child: SimpleFilterSearchField(
                        value: mtc.searchValue,
                        onChanged: (v) {
                          updateTreeWithSearchingTitle(mtc.data, v);
                          setState(() {});
                        },
                        controller: mtc.searchTextFieldController,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Visibility(
                        visible: mtc.visible,
                        child: SimpleTreeView(
                          mtc.data,
                          onNodeDataChanged: masterTreeOnSelect,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// detail tree
  Widget _buildDetailTree(BuildContext ctx) {
    final t = Translations.of(ctx);
    // 获取当前 Locale
    final currentLocale = Localizations.localeOf(context);
    // 提取语言代码，如 'en'、'zh'
    final languageCode = currentLocale.languageCode;
    return Visibility(
      visible: dtc.visible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(12, 15, 10, 15),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 5, color: Color(0xFF00A2E9)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 15),
                  TextTitle(text: mtc.select.title),
                  const Spacer(),
                  // mtc.select.type == 1
                  //     ? BaseButton(
                  //         label: t.button.paramsInject.bind,
                  //         width: 65,
                  //         height: 30,
                  //         onPressed: () {
                  //           bind(ctx);
                  //         },
                  //       )
                  //     : SizedBox(),
                ],
              ),
            ),
          ),
          // 业务网卡
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(12, 0, 10, 0),
            child: Row(
              children: [
                // 业务网卡
                SimpleDarkDropdown<int>(
                  width: 260,
                  height: 36,
                  hintText: t.TextField.select,
                  prefixIcon: Icons.network_check_rounded,
                  value: dtc.selectWifi,
                  items: networkOptions,
                  onChanged: (value) {
                    setState(() => dtc.selectWifi = value!);
                  },
                ),
                const Spacer(),
                // 刷新
                Container(
                  // FlareButton 没有边框可供配置,所以在 FlareButton  外围套了一层 container,此 container 只作边框使用
                  width: 74,
                  height: 36,
                  margin: EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Color(0xFF00A2E9), width: 2),
                  ),
                  child: Center(
                    child: BaseButton(
                      label: t.button.paramsInject.refresh,
                      width: 70,
                      height: 30,
                      colors: const [
                        Color(0xFF0A1D35),
                        Color(0xFF0A1D35),
                        Color(0xFF0A1D35),
                        Color(0xFF0A1D35),
                      ],
                      onPressed: detailRefresh,
                    ),
                  ),
                ),
                // 下发
                BaseButton(
                  label: t.button.paramsInject.issue,
                  width: 74,
                  height: 36,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // 步骤条
          Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(12, 15, 10, 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF171C22),
                border: Border.all(
                  width: 1,
                  color: Color(0x8A00A2E9),
                  style: BorderStyle.solid,
                ),
              ),
              child: SimpleNumberStep(
                steps: steps,
                lineWidth: languageCode == "zh" ? 20 : 13,
                activeStep: dtc.activeStep,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 10, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF171C22),
                  border: Border.all(
                    width: 1,
                    color: Color(0x8A00A2E9),
                    style: BorderStyle.solid,
                  ),
                ),
                child: ListView.builder(
                  itemCount: dtc.data.length,
                  itemBuilder: (context, index) {
                    return SimpleTreeView(
                      dtc.data[index],
                      onNodeDataChanged: (v) {
                        setState(() {});
                        String id = "${v.data.id}";
                        if (dtc.selectRows[id] == null) {
                          dtc.selectRows[id] = v;
                        } else {
                          dtc.selectRows.remove(id);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
