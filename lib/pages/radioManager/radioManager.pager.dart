import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/radioManager/radio.model.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.mixin.dart';

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
  // final Set<String> selectedIds = {};
  // final bool showCheckboxes = true;
  // late List<User> allUsers;
  // List<User> filteredUsers = [];
  //
  // int currentPage = 1;
  // int pageSize = 10;
  //
  // String searchQuery = '';
  //
  // bool showColumnInfo = false;
  //

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    allUsers = generateUsers(300);
    applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
            DataTablePlusThemeProvider(
              theme: widget.theme,
              child: TableContextualBar(
                selectedCount: selectedIds.length,
                normalToolbar: buildToolbar(),
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
                        ? 'Deselect All'
                        : 'Select All (${paginatedUsers.length})',
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
                      'Clear',
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
                      clearSelection();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${selectedIds.length})'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.theme.dangerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                  child: DataTablePlus<User>(
                    items: paginatedUsers,
                    idGetter: (user) => user.id,
                    selectedIds: selectedIds,
                    allSelected: allSelected,
                    showCheckboxes: showCheckboxes,
                    onSelectionChanged: toggleSelection,
                    onSelectAllChanged: toggleSelectAll,
                    columns: buildColumns(),
                    // 设置未null时,不显示操作列
                    actionBuilder: buildActionCell,
                    actionLabel: 'Actions',
                    emptyWidget: buildEmptyWidget(),
                    // 在列头下方显示[字段描述]
                    showColumnInfo: showColumnInfo,
                    // 显示字段描述, showColumnInfo 设置为 false 时,此处无效
                    onToggleColumnInfo: () =>
                        setState(() => showColumnInfo = !showColumnInfo),
                  ),
                ),
              ),
            ),
            DataTablePlusThemeProvider(
              theme: widget.theme,
              child: TablePagination(
                currentPage: currentPage,
                totalPages: totalPages,
                totalItems: filteredUsers.length,
                pageSize: pageSize,
                pageSizeOptions: const [10, 20, 50, 100],
                onPageSizeChanged: (size) => setState(() {
                  pageSize = size;
                  currentPage = 1;
                }),
                onPageChanged: (page) => setState(() => currentPage = page),
                itemRangeTemplate: 'Showing {start}-{end} of {total} users',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
