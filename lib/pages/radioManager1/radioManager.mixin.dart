import 'package:flare_button/flare_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pluto_grid/pluto_grid.dart';

mixin RadioManagerMixin<T extends StatefulWidget> on State<T> {
  static const tableTitleColor = Color.fromRGBO(44, 52, 62, 1);
  final formKey = GlobalKey<FormBuilderState>();
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



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // pData =
  }
}
