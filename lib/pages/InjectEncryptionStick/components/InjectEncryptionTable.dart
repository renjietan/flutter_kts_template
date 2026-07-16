import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import '../../../theme/table.theme.dart';
import '../../radioManager/radio.model.dart';

class InjectEncryptionTable extends StatefulWidget {
  final ThemePreset? themePreset;

  const InjectEncryptionTable({super.key, this.themePreset = ThemePreset.dark});

  @override
  State<InjectEncryptionTable> createState() => _InjectEncryptionTableState();
}

class _InjectEncryptionTableState extends State<InjectEncryptionTable> {
  late final DataTablePlusTheme theme;
  List<User> allData = [];
  List<User> filteredData = [];
  int currentPage = 1;
  int pageSize = 10;
  String? searchQuery = "";
  bool get isDark => widget.themePreset == ThemePreset.dark;
  final Set<String> selectedIds = {};

  List<User> get paginatedData {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredData.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredData.length / pageSize).ceil().clamp(1, 999);

  @override
  void initState() {
    super.initState();
    theme = widget.themePreset == null
        ? getThemePreset(ThemePreset.dark)
        : getThemePreset(widget.themePreset!);
    allData = generateUsers(300);
    applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextTitle(text: t.pager.injectEncrypt.paramPairing),
              BaseButton(
                label: t.button.injectEncrypt.export,
                onPressed: () {},
                width: 70,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: DataTablePlusThemeProvider(
              theme: theme,
              child: DataTablePlus<User>(
                items: paginatedData,
                idGetter: (item) => item.id.toString(),
                selectedIds: selectedIds,
                allSelected: allSelected,
                showCheckboxes: true,
                onSelectionChanged: toggleSelection,
                onSelectAllChanged: toggleSelectAll,
                columns: buildColumns(context),
                emptyWidget: buildEmptyWidget(context),
              ),
            ),
          ),
        ),
        DataTablePlusThemeProvider(
          theme: theme,
          child: TablePagination(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: filteredData.length,
            pageSize: pageSize,
            pageSizeOptions: const [10, 20, 50, 100],
            onPageSizeChanged: (size) => setState(() {
              pageSize = size;
              currentPage = 1;
            }),
            onPageChanged: (page) => setState(() => currentPage = page),
            // itemRangeTemplate: 'Showing {start}-{end} of {total} data',
            itemRangeTemplate: "",
          ),
        ),
      ],
    );
  }

  void applyFilters() {
    filteredData = allData.where((user) {
      if (searchQuery?.isNotEmpty ?? false) {
        final query = searchQuery!.toLowerCase();
        if (!user.field1.toLowerCase().contains(query) &&
            !user.field2.toLowerCase().contains(query) &&
            !user.id.toLowerCase().contains(query) &&
            !user.field3.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
    currentPage = 1;
  }

  Widget buildEmptyWidget(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              t.common.noData,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id.toString())) {
        selectedIds.remove(id.toString());
      } else {
        selectedIds.add(id.toString());
      }
    });
  }

  bool get allSelected {
    final current = paginatedData;
    if (current.isEmpty) return false;
    return current.every((u) => selectedIds.contains(u.id.toString()));
  }

  void toggleSelectAll() {
    setState(() {
      final current = paginatedData;
      if (allSelected) {
        for (final item in current) {
          selectedIds.remove(item.id.toString());
        }
      } else {
        for (final item in current) {
          selectedIds.add(item.id.toString());
        }
      }
    });
  }

  List<ColumnDefinition<User>> buildColumns(BuildContext context) {
    final t = Translations.of(context);
    return [
      ColumnDefinition<User>(
        label: t.tableColumn.injectEncrypt.parameterPacket,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field1),
      ),
      ColumnDefinition<User>(
        label: t.tableColumn.injectEncrypt.radio,
        flex: 2,
        cellBuilder: (user) => SimpleDropdown(
          hint: t.tableColumn.injectEncrypt.radio,
          value: "",
          items: [],
          onChanged: (v) {},
        ),
      ),
      ColumnDefinition<User>(
        label: t.tableColumn.injectEncrypt.consumer,
        flex: 3,
        cellBuilder: TextCellBuilder.text<User>((u) => u.field3),
      ),
      ColumnDefinition<User>(
        label: t.tableColumn.injectEncrypt.location,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field4),
      ),
      ColumnDefinition<User>(
        label: t.tableColumn.injectEncrypt.SN,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field4),
      ),
    ];
  }
}
