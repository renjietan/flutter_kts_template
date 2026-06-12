import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../components/search_input.dart';
import '../../components/table-render.dart';

class RadioManager extends StatefulWidget {
  const RadioManager({super.key});

  @override
  State<RadioManager> createState() => _RadioManagerState();
}

class _RadioManagerState extends State<RadioManager> with RadioManagerMixin {
  late List<PlutoColumn> pColumns = [];
  late List<PlutoRow> pRows = [];
  late PlutoGridStateManager? stateManager;
  final TextEditingController? searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pColumns = genColumns();
  }

  Future<PlutoLazyPaginationResponse> getList(List<PlutoColumn> columns) async {
    List<PlutoRow> data = List<int>.generate(45, (index) => index).map((_) {
      Map<String, PlutoCell> m = {};
      for (PlutoColumn column in pColumns) {
        m[column.field] = PlutoCell(
          value: column.field,
        );
      }
      return PlutoRow(cells: m);
    }).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    return Future.value(PlutoLazyPaginationResponse(
      totalPage: 5,
      rows: data,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(15.w, 60.h, 15.w, 60.h),
                child: Text("电台管理",
                  style: TextStyle(
                    fontSize: 15.sp,
                  ),
                ),
              ),
              const Spacer(), // 占据所有剩余空间，把后面的组件推到右边
              SizedBox(
                width: 300.w, height: 90.h,
                child: SearchText(
                  controller: searchController,
                  hintText: 'Search',
                  onChanged: (value) {
                    // 处理输入变化
                  },
                  onSubmitted: () {
                    // 处理提交
                  },
                )
              ),
              SizedBox(width: 15.w),
              FlareButton(
                label: "添加电台",
                width: 110.w,
                height: 90.h,
                borderRadius: 15.r,
                colors: const [
                  Color(0xFF00A2E9),
                  Color(0xFF00A2E9),
                  Color(0xFF00A2E9),
                  Color(0xFF00A2E9),
                ],
                onPressed: () {

                },
              ),
              SizedBox(width: 15.w),
            ],
        ),
        Expanded(
            child: TableRender(
                pData: pRows, pColumns: pColumns,
                fetch: getList,
                onRowChecked: (Map<int,bool> v) {
                  GlobalLogger.logInfo("checked: $v");
                },
                onLoaded: (PlutoGridStateManager? instance) {
                  stateManager = instance;
                  // Future.delayed(Duration(seconds: 12)).then((_) {
                  //   setState(() {
                  //     if (stateManager!= null) {
                  //       pRows = genData(pColumns);
                  //       stateManager?.scroll.bodyRowsVertical!.jumpTo(0);
                  //       stateManager?.refRows.clearFromOriginal();
                  //       stateManager?.insertRows(0, pRows);
                  //       stateManager?.setShowLoading(false);
                  //     }
                  //   });
                  // });
                }
            )
        ),

      ],
    );
  }
}
