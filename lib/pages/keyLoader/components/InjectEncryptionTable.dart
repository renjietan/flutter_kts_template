import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/TextField/simple.textfield.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import '../../../theme/table.theme.dart';

class InjectEncryptionTable extends StatefulWidget {
  final ThemePreset? themePreset;
  final List<KeyLoaderDetailsEntity> allData;

  const InjectEncryptionTable({
    super.key,
    this.themePreset = ThemePreset.dark,
    required this.allData,
  });

  @override
  State<InjectEncryptionTable> createState() => _InjectEncryptionTableState();
}

class _InjectEncryptionTableState extends State<InjectEncryptionTable> {
  late final DataTablePlusTheme theme;
  int currentPage = 1;
  int pageSize = 10;
  String? searchQuery = "";
  bool get isDark => widget.themePreset == ThemePreset.dark;
  final Set<String> selectedIds = {};

  List<KeyLoaderDetailsEntity> get paginatedData {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredData.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredData.length / pageSize).ceil().clamp(1, 999);

  List<KeyLoaderDetailsEntity> get filteredData => widget.allData;
  @override
  void initState() {
    super.initState();
    theme = widget.themePreset == null
        ? getThemePreset(ThemePreset.dark)
        : getThemePreset(widget.themePreset!);
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
              child: DataTablePlus<KeyLoaderDetailsEntity>(
                items: paginatedData,
                idGetter: (item) => item.id.toString(),
                selectedIds: selectedIds,
                allSelected: allSelected,
                showCheckboxes: false,
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

  List<ColumnDefinition<KeyLoaderDetailsEntity>> buildColumns(
    BuildContext context,
  ) {
    final t = Translations.of(context);
    return [
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.parameterPacket,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (u) => u.netNodePackageName,
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.radio,
        flex: 2,
        cellBuilder: (item) => SimpleDropdown(
          hint: t.tableColumn.injectEncrypt.radio,
          value: item.radioId,
          items: [],
          onChanged: (v) {},
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.consumer,
        size: const ColumnSize.fixed(200),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.consumer ?? "",
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.location,
        size: const ColumnSize.fixed(200),
        cellBuilder: (item) => SimpleTextfield(
          hint: "",
          height: 30,
          contentPadding: EdgeInsets.symmetric(horizontal: 7),
          onChanged: (v) {
            item.location = v;
          },
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.SN,
        size: const ColumnSize.fixed(200),
        cellBuilder: (item) => SimpleTextfield(
          hint: "",
          height: 30,
          contentPadding: EdgeInsets.symmetric(horizontal: 7),
          onChanged: (v) {
            item.SN = v;
          },
        ),
      ),
    ];
  }
}
