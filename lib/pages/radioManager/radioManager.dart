import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../components/TextField/search_textfield.dart';
import '../../components/table/table.dart';

Future<void> _showLoginDialog() async {
  final _formKey = GlobalKey<FormBuilderState>();

  SmartDialog.show(
    clickMaskDismiss: false,
    maskColor: Colors.white.withOpacity(0.1), // 半透明白色遮罩
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black, // 设置背景色为淡黄色
      shape: RoundedRectangleBorder(
        // 自定义形状
        borderRadius: BorderRadius.circular(7.w), // 设置圆角半径为15
      ),
      titlePadding: EdgeInsets.fromLTRB(0, 15.h, 0, 15.h),
      actionsPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 90.h),
      contentPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 25.h),
      titleTextStyle: TextStyle(fontSize: 14, color: Colors.white),
      title: Container(
        padding: EdgeInsets.fromLTRB(18.w, 30.h, 18.w, 30.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x4D21262C), width: 1),
          ),
        ),
        child: Row(
          children: [Text("新增电台", style: TextStyle(fontSize: 16.sp))],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      content: Container(
        width: 270.w,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsetsGeometry.only(top: 0, bottom: 45.h),
                child: Text(
                  "Device Type",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FormBuilderTextField(
                name: 'field1',
                decoration: InputDecoration(
                  labelText: '字段1',
                  isDense: true, // 紧凑布局
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 35.h,
                    horizontal: 12.w,
                  ), // 控制高度
                  labelStyle: TextStyle(
                    color: Colors.white, // 标签颜色
                    fontSize: 11.sp,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white, // 提示文字颜色（如果设置 hintText）
                    fontSize: 11.sp,
                  ),
                  // 背景色
                  filled: true,
                  fillColor: Color(0x9921262C),
                  // 框线（边框）
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // 未聚焦时无边框（可根据需要调整）
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  // 可调整内容内边距
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsetsGeometry.only(top: 45.h, bottom: 45.h),
                child: Text(
                  "Network Interface",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FormBuilderTextField(
                name: 'field1',
                decoration: InputDecoration(
                  labelText: '字段1',
                  isDense: true, // 紧凑布局
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 35.h,
                    horizontal: 12.w,
                  ), // 控制高度
                  labelStyle: TextStyle(
                    color: Colors.white, // 标签颜色
                    fontSize: 11.sp,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white, // 提示文字颜色（如果设置 hintText）
                    fontSize: 11.sp,
                  ),
                  // 背景色
                  filled: true,
                  fillColor: Color(0x9921262C),
                  // 框线（边框）
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // 未聚焦时无边框（可根据需要调整）
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  // 可调整内容内边距
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
      actions: [
        FlareButton(
          label: "新增电台",
          textStyle: TextStyle(fontSize: 12.sp),
          height: 100.h,
          borderRadius: 15.r,
          colors: const [
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
          ],
          onPressed: () {
            SmartDialog.dismiss();
          },
        ),
      ],
    ),
  );
}

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
        m[column.field] = PlutoCell(value: column.field);
      }
      return PlutoRow(cells: m);
    }).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    return Future.value(PlutoLazyPaginationResponse(totalPage: 5, rows: data));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(15.w, 60.h, 15.w, 60.h),
              child: Text("电台管理", style: TextStyle(fontSize: 15.sp)),
            ),
            const Spacer(), // 占据所有剩余空间，把后面的组件推到右边
            SizedBox(
              width: 300.w,
              height: 100.h,
              child: SearchTextfield(
                controller: searchController,
                hintText: 'Search',
                onChanged: (value) {
                  // 处理输入变化
                },
                onSubmitted: () {
                  // 处理提交
                },
              ),
            ),
            SizedBox(width: 15.w),
            FlareButton(
              textStyle: TextStyle(fontSize: 14.sp, color: Colors.white),
              label: "添加电台",
              width: 140.w,
              height: 100.h,
              borderRadius: 15.r,
              colors: const [
                Color(0xFF00A2E9),
                Color(0xFF00A2E9),
                Color(0xFF00A2E9),
                Color(0xFF00A2E9),
              ],
              onPressed: () {
                _showLoginDialog();
              },
            ),
            SizedBox(width: 15.w),
          ],
        ),
        Expanded(
          child: TableRender(
            pData: pRows,
            pColumns: pColumns,
            fetch: getList,
            onRowChecked: (Map<int, bool> v) {
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
            },
          ),
        ),
      ],
    );
  }
}
