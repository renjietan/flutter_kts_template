import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class TableRender extends StatefulWidget {
  final List<PlutoRow> pData;
  final List<PlutoColumn> pColumns;
  final void Function(PlutoGridStateManager? instance) onLoaded;
  final void Function(Map<int,bool>) onRowChecked;
  final Future<PlutoLazyPaginationResponse> Function(List<PlutoColumn> columns) fetch;
  const TableRender({
    super.key, required this.pData, required this.pColumns,
    required this.onRowChecked, required this.onLoaded, required this.fetch
  });

  @override
  _TableRenderState createState() => _TableRenderState();
}

class _TableRenderState extends State<TableRender> {
  final List<PlutoColumn> columns = [];

  final List<PlutoRow> rows = [];

  final Map<int,bool> checkedRows = {};

  late PlutoGridStateManager? stateManager;

  Color checkedColor = const Color.fromRGBO(30, 35, 40, 1);
  Color noCheckedColor = const Color.fromRGBO(44, 52, 62, 1);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: ThemeData.dark(), child: PlutoGrid(
      columns: widget.pColumns,
      rows: widget.pData,
      configuration: PlutoGridConfiguration.dark(
        columnSize: PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale, // 平均分布列
          resizeMode: PlutoResizeMode.normal, // 不允许用户手动调整列宽
        ),
        style: PlutoGridStyleConfig.dark(
            oddRowColor: checkedColor,             // 奇数行背景色 (索引 0, 2, 4...)
            evenRowColor: noCheckedColor,          // 偶数行背景色 (索引 1, 3, 5...)
        )
      ),
      createFooter: (stateManager) {
        return PlutoLazyPagination(
          initialPage: 1,
          initialFetch: true,
          fetchWithSorting: true,
          fetchWithFiltering: false,
          pageSizeToMove: null,
          fetch: (PlutoLazyPaginationRequest request){
            checkedRows.clear();
            widget.onRowChecked(checkedRows);
            return widget.fetch(widget.pColumns);
          },
          stateManager: stateManager,
        );
      },
      onSelected: (event) {
      },
      onChanged: (PlutoGridOnChangedEvent event) {
      },
      onRowChecked: (PlutoGridOnRowCheckedEvent event) {
        if(event.row == null && event.rowIdx == null && event.isChecked == true) {
          checkedRows.clear();
          for(var i = 0; i<=widget.pData.length; i++) {
            checkedRows[i] = true;
          }
        } else if (event.row == null && event.rowIdx == null && event.isChecked == false) {
          checkedRows.clear();
        } else if (event.row != null && event.rowIdx != null && event.isChecked == true){
          checkedRows[event.rowIdx ?? -1] = true;
        } else if (event.row != null && event.rowIdx != null && event.isChecked == false){
            checkedRows.remove(event.rowIdx);
        }
        widget.onRowChecked(checkedRows);
      },
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(PlutoGridSelectingMode.cell);
        stateManager = event.stateManager;
        widget.onLoaded(stateManager);
      },
    ));
  }
}