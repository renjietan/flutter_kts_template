import 'package:flare_button/flare_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pluto_grid/pluto_grid.dart';

mixin RadioManagerMixin<T extends StatefulWidget> on State<T> {
  static const tableTitleColor = Color.fromRGBO(44, 52, 62, 1);
  List<PlutoRow> genData(List<PlutoColumn> pColumns) {
   return List<int>.generate(15, (index) => index).map((index) {
     var keyIndex = 0;
     Map<String, PlutoCell> _map = {};
     for (PlutoColumn column in pColumns) {
        _map[column.field] = PlutoCell(
           value: keyIndex * index,
         );
        keyIndex++;
     }
     return PlutoRow(cells: _map);
   }).toList();
  }

  List<PlutoColumn> genColumns() {
    return [
      PlutoColumn(
        title: 'column111',
        field: 'column1',
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center, // 表头剧中
        readOnly: true,
        backgroundColor: tableTitleColor,
        enableRowChecked: true, // 启动勾选框
        enableEditingMode: false,
        enableSorting: false, // 禁止列头排序
        enableContextMenu: false, // 禁止列头弹出菜单
        enableDropToResize: false, // 禁止改变列款
        enableFilterMenuItem: false, // 禁用列头弹出菜单
        enableAutoEditing: false, // 禁止编辑单元格
        enableRowDrag: false, // 禁止拖拽行
        enableColumnDrag: false, // 禁止拖拽列头
        width: 250,
        minWidth: 175,
        renderer: (rendererContext) {
          return Center(child: Text(
            rendererContext.cell.value
                .toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),);
        },
      ),
      PlutoColumn(
        title: 'column2',
        field: 'column2',
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center, // 表头剧中
        backgroundColor: tableTitleColor,
        enableEditingMode: false,
        enableSorting: false, // 禁止列头排序
        enableContextMenu: false, // 禁止列头弹出菜单
        enableDropToResize: false, // 禁止改变列款
        enableFilterMenuItem: false, // 禁用列头弹出菜单
        enableAutoEditing: false, // 禁止编辑单元格
        enableRowDrag: false, // 禁止拖拽行
        enableRowChecked: false, // 启动勾选框
        enableColumnDrag: false, // 禁止拖拽列头
        renderer: (rendererContext) {
          return Center(child: Text(
            rendererContext.cell.value
                .toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),);
        },
      ),
      PlutoColumn(
        title: 'column3',
        field: 'column3',
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center, // 表头剧中
        backgroundColor: tableTitleColor,
        enableEditingMode: false,
        enableSorting: false, // 禁止列头排序
        enableContextMenu: false, // 禁止列头弹出菜单
        enableDropToResize: false, // 禁止改变列款
        enableFilterMenuItem: false, // 禁用列头弹出菜单
        enableAutoEditing: false, // 禁止编辑单元格
        enableRowDrag: false, // 禁止拖拽行
        enableRowChecked: false, // 启动勾选框
        enableColumnDrag: false, // 禁止拖拽列头
        renderer: (rendererContext) {
          return Center(child: Text(
            rendererContext.cell.value
                .toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),);
        },
      ),
      PlutoColumn(
        title: 'column4',
        field: 'column4',
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center, // 表头剧中
        backgroundColor: tableTitleColor,
        enableEditingMode: false,
        enableSorting: false, // 禁止列头排序
        enableContextMenu: false, // 禁止列头弹出菜单
        enableDropToResize: false, // 禁止改变列款
        enableFilterMenuItem: false, // 禁用列头弹出菜单
        enableAutoEditing: false, // 禁止编辑单元格
        enableRowDrag: false, // 禁止拖拽行
        enableRowChecked: false, // 启动勾选框
        enableColumnDrag: false, // 禁止拖拽列头
        renderer: (rendererContext) {
          return Center(child: Text(
            rendererContext.cell.value
                .toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),);
        },
      ),
      // PlutoColumn(
      //   title: 'column5',
      //   field: 'column5',
      //   type: PlutoColumnType.text(),
      //   enableEditingMode: false,
      //   renderer: (rendererContext) {
      //     return Image.asset('assets/images/cat.jpg');
      //   },
      // ),
    ];
  }

  Future<void> showLoginDialog() async {
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
        actionsPadding: EdgeInsets.fromLTRB(
          30.w, 25.h, 30.w,
          MediaQuery.of(context).viewInsets.bottom > 0 ? 20.h : 90.h,  // 键盘弹出时减小底部间距
        ),
        contentPadding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 25.h),
        titleTextStyle: TextStyle(fontSize: 14, color: Colors.white),
        title: Container(
          padding: EdgeInsets.fromLTRB(18.w, 30.h, 18.w, 30.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x4D21262C), width: 2),
            ),
          ),
          child: Row(
            children: [Text("新增电台", style: TextStyle(fontSize: 16.sp))],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        content: SingleChildScrollView(
          child: SizedBox(
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
                          fontSize: 16.sp
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
                          fontSize: 16.sp
                      ),
                    ),
                  ),
                  FormBuilderTextField(
                    name: 'field2',
                    decoration: InputDecoration(
                      labelText: '字段1',
                      isDense: true, // 紧凑布局
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 35.h,
                        horizontal: 12.w,
                      ), // 控制高度
                      labelStyle: TextStyle(
                        color: Colors.white, // 标签颜色
                        fontSize: 14.sp,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white, // 提示文字颜色（如果设置 hintText）
                        fontSize: 14.sp,
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // pData =
  }
}
