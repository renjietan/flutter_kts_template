import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class RowLazyPaginationScreen extends StatefulWidget {
  static const routeName = 'feature/row-lazy-pagination';

  const RowLazyPaginationScreen({super.key});

  @override
  State<RowLazyPaginationScreen> createState() =>
      _RowLazyPaginationScreenState();
}

class _RowLazyPaginationScreenState extends State<RowLazyPaginationScreen> {
  late final PlutoGridStateManager stateManager;

  final List<PlutoColumn> columns = [];

  // Pass an empty row to the grid initially.
  final List<PlutoRow> rows = [];

  final List<PlutoRow> fakeFetchedRows = [];

  @override
  void initState() {
    super.initState();

    final dummyData = DummyData(10, 1000);

    columns.addAll(dummyData.columns);

    // Instead of fetching data from the server,
    // Create a fake row in advance.
    fakeFetchedRows.addAll(dummyData.rows);
  }

  Future<PlutoLazyPaginationResponse> fetch(
    PlutoLazyPaginationRequest request,
  ) async {
    List<PlutoRow> tempList = fakeFetchedRows;
    if (request.filterRows.isNotEmpty) {
      final filter = FilterHelper.convertRowsToFilter(
        request.filterRows,
        stateManager.refColumns,
      );

      tempList = fakeFetchedRows.where(filter!).toList();
    }

    if (request.sortColumn != null && !request.sortColumn!.sort.isNone) {
      tempList = [...tempList];

      tempList.sort((a, b) {
        final sortA = request.sortColumn!.sort.isAscending ? a : b;
        final sortB = request.sortColumn!.sort.isAscending ? b : a;

        return request.sortColumn!.type.compare(
          sortA.cells[request.sortColumn!.field]!.valueForSorting,
          sortB.cells[request.sortColumn!.field]!.valueForSorting,
        );
      });
    }

    final page = request.page;
    const pageSize = 100;
    final totalPage = (tempList.length / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final end = start + pageSize;

    Iterable<PlutoRow> fetchedRows = tempList.getRange(
      max(0, start),
      min(tempList.length, end),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    return Future.value(
      PlutoLazyPaginationResponse(
        totalPage: totalPage,
        rows: fetchedRows.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlutoGrid(
      columns: columns,
      rows: rows,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        stateManager = event.stateManager;
        stateManager.setShowColumnFilter(true);
      },
      onChanged: (PlutoGridOnChangedEvent event) {},
      configuration: const PlutoGridConfiguration(),
      createFooter: (stateManager) {
        return PlutoLazyPagination(
          // Determine the first page.
          // Default is 1.
          initialPage: 1,

          // First call the fetch function to determine whether to load the page.
          // Default is true.
          initialFetch: true,

          // Decide whether sorting will be handled by the server.
          // If false, handle sorting on the client side.
          // Default is true.
          fetchWithSorting: true,

          // Decide whether filtering is handled by the server.
          // If false, handle filtering on the client side.
          // Default is true.
          fetchWithFiltering: true,

          // Determines the page size to move to the previous and next page buttons.
          // Default value is null. In this case,
          // it moves as many as the number of page buttons visible on the screen.
          pageSizeToMove: null,
          fetch: fetch,
          stateManager: stateManager,
        );
      },
    );
  }
}

class DummyData {
  late List<PlutoColumn> columns;

  late List<PlutoRow> rows;

  DummyData(
    int columnLength,
    int rowLength, {
    List<int> leftFrozenColumnIndexes = const [],
    List<int> rightFrozenColumnIndexes = const [],
  }) {
    var faker = Faker();

    columns = List<int>.generate(columnLength, (index) => index).map((i) {
      return PlutoColumn(
        title: faker.food.cuisine(),
        field: i.toString(),
        readOnly: [1, 3, 5].contains(i),
        type: (int i) {
          if (i == 0) {
            return PlutoColumnType.number();
          } else if (i == 1) {
            return PlutoColumnType.currency();
          } else if (i == 2) {
            return PlutoColumnType.text();
          } else if (i == 3) {
            return PlutoColumnType.text();
          } else if (i == 4) {
            return PlutoColumnType.select(<String>[
              'One',
              'Two',
              'Three',
              'Four',
              'Five',
            ]);
          } else if (i == 5) {
            return PlutoColumnType.select(<String>[
              'One',
              'Two',
              'Three',
              'Four',
              'Five',
            ]);
          } else if (i == 6) {
            return PlutoColumnType.date();
          } else if (i == 7) {
            return PlutoColumnType.time();
          } else {
            return PlutoColumnType.text();
          }
        }(i),
        frozen: (int i) {
          if (leftFrozenColumnIndexes.contains(i)) {
            return PlutoColumnFrozen.start;
          }
          if (rightFrozenColumnIndexes.contains(i)) {
            return PlutoColumnFrozen.end;
          }
          return PlutoColumnFrozen.none;
        }(i),
      );
    }).toList();

    rows = rowsByColumns(length: rowLength, columns: columns);
  }

  static List<PlutoRow> rowsByColumns({
    required int length,
    required List<PlutoColumn> columns,
  }) {
    return List<int>.generate(length, (index) => index).map((_) {
      return rowByColumns(columns);
    }).toList();
  }

  static PlutoRow rowByColumns(List<PlutoColumn> columns) {
    return PlutoRow(cells: _cellsByColumn(columns));
  }

  static Map<String, PlutoCell> _cellsByColumn(List<PlutoColumn> columns) {
    final cells = <String, PlutoCell>{};

    for (var column in columns) {
      cells[column.field] = PlutoCell(value: valueByColumnType(column));
    }

    return cells;
  }

  static dynamic valueByColumnType(PlutoColumn column) {
    if (column.type.isNumber || column.type.isCurrency) {
      return faker.randomGenerator.decimal(scale: 1000000000, min: -500000000);
    } else if (column.type.isSelect) {
      return (column.type.select.items.toList()..shuffle()).first;
    } else if (column.type.isDate) {
      return DateTime.now()
          .add(Duration(days: faker.randomGenerator.integer(365, min: -365)))
          .toString();
    } else if (column.type.isTime) {
      final hour = faker.randomGenerator.integer(12).toString().padLeft(2, '0');
      final minute = faker.randomGenerator
          .integer(60)
          .toString()
          .padLeft(2, '0');
      return '$hour:$minute';
    } else {
      return faker.randomGenerator.element(multilingualWords);
    }
  }
}

const multilingualWords = [
  'معایبی',
  'دارد',
  'روغن',
  'شریعتی',
  'زنده‌یاد',
  'ante',
  'arcu',
  'at',
  'auctor',
  'augue',
  'bibendum',
  'blandit',
  'commodo',
  'condimentum',
  'congue',
  'consectetur',
  'Лорем',
  'ипсум',
  'долор',
  'сит',
  'амет',
  'करती',
  'और्४५०',
  'वर्णित',
  'प्राथमिक',
  'विभाग',
  '田',
  '民',
  '知',
  '新',
  '雌',
  'את',
  'שנורו',
  'המזנון',
  'או',
  '한글',
  '데이터 그리드',
  '떡볶이',
  '라면',
  '짜장면',
  '김치볶음밥',
];
