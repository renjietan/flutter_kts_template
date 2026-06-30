import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.mixin.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../theme/table.theme.dart';

class RadioManagerPager extends StatefulWidget {
  final DataTablePlusTheme theme;
  final ThemePreset themePreset;

  const RadioManagerPager({
    super.key,
    required this.theme,
    required this.themePreset,
  });

  @override
  State<RadioManagerPager> createState() => _RadioManagerPagerState();
}

class _RadioManagerPagerState extends State<RadioManagerPager>
    with AutomaticKeepAliveClientMixin, RadioManagerMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // TableContextualBar
          DataTablePlusThemeProvider(
            theme: widget.theme,
            child: TableContextualBar(
              selectedCount: selectedIds.length,
              normalToolbar: buildToolbar(context),
              selectedCountTemplate: '{count} selected',
              selectAllWidget: OutlinedButton(
                onPressed: toggleSelectAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.theme.accentColor,
                  side: BorderSide(
                    color: widget.theme.accentColor.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  allSelected
                      ? t.checkbox.DeselectAll
                      : t.checkbox.SelectAll(count: data.length),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                // 执行操作按钮时的弹窗
                OutlinedButton.icon(
                  onPressed: clearSelection,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: widget.theme.textSecondaryColor,
                  ),
                  label: Text(
                    t.button.radioManager.clear,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.theme.textSecondaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    side: BorderSide(color: widget.theme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () {
                    patchDelete();
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    '${t.button.radioManager.delete} (${selectedIds.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTablePlusThemeProvider(
                theme: widget.theme,
                child: DataTablePlus<RadiosEntity>(
                  items: data,
                  idGetter: (item) => item.id.toString(),
                  selectedIds: selectedIds,
                  allSelected: allSelected,
                  showCheckboxes: showCheckboxes,
                  onSelectionChanged: toggleSelection,
                  onSelectAllChanged: toggleSelectAll,
                  columns: buildColumns(context),
                  // 设置未null时,不显示操作列
                  actionBuilder: buildActionCell,
                  actionLabel: t.tableColumn.base.actions,
                  emptyWidget: buildEmptyWidget(context),
                  // 在列头下方显示[字段描述]
                  // showColumnInfo: showColumnInfo,
                  // 显示字段描述, showColumnInfo 设置为 false 时,此处无效
                  // onToggleColumnInfo: () =>
                  //     setState(() => showColumnInfo = !showColumnInfo),
                ),
              ),
            ),
          ),
          // 分页
          DataTablePlusThemeProvider(
            theme: widget.theme,
            child: TablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              pageSize: pageSize,
              pageSizeOptions: const [10, 20, 50, 100],
              // pageSizeTemplate: "{count}",
              onPageSizeChanged: (size) => setState(() {
                pageSize = size;
                currentPage = 1;
                Pop.loading();
                getList();
              }),
              onPageChanged: (page) {
                setState(() => currentPage = page);
                Pop.loading();
                getList();
              },
              itemRangeTemplate: 'Showing {start}-{end} of {total} data',
            ),
          ),
        ],
      ),
    );
  }
}
