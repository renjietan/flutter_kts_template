import 'package:composable_data_table/composable_data_table.dart';
import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/radioManager/radio.model.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../logger/logger.dart';
import '../../theme/table.theme.dart';

mixin RadioManagerMixin on State<RadioManagerPager> {
  late List<User> allUsers;
  List<User> filteredUsers = [];

  int currentPage = 1;
  int pageSize = 10;

  String searchQuery = '';

  final Set<String> selectedIds = {};
  final bool showCheckboxes = true;

  bool showColumnInfo = false;

  // =============================================================================
  // 2026/6/15 下午3:02 判断是否是深色主题, 用于样式判断
  // =============================================================================
  bool get isDark => widget.themePreset == ThemePreset.dark;

  // =============================================================================
  // 2026/6/15 下午2:47 分页相关
  // =============================================================================

  void applyFilters() {
    filteredUsers = allUsers.where((user) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
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

  List<User> get paginatedUsers {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredUsers.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredUsers.length);
    return filteredUsers.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredUsers.length / pageSize).ceil().clamp(1, 999);

  // =============================================================================
  // 2026/6/15 下午2:54 构建 widget
  // =============================================================================
  Widget buildToolbar() {
    return TableFilterToolbar(
      mainFilters: [
        Text(
          "电台管理",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ],
      trailingActions: [
        FilterSearchField(
          hint: 'Search...',
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              applyFilters();
            });
          },
        ),
        FlareButton(
          textStyle: TextStyle(fontSize: 16, color: Colors.white),
          label: "添加电台",
          width: 120,
          height: 38,
          borderRadius: 5,
          colors: const [
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
          ],
          onPressed: () {
            GlobalLogger.logDebug("添加电台");
          },
        ),
        FilterResetButton(
          onReset: () {
            setState(() {
              searchQuery = '';
              applyFilters();
            });
          },
        ),
      ],
    );
  }

  List<ColumnDefinition<User>> buildColumns() {
    return [
      ColumnDefinition<User>(
        label: '电台别名',
        description: '自定义的电台别名',
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field1),
      ),
      ColumnDefinition<User>(
        label: '使用人',
        description: '电台的使用人',
        flex: 2,
        cellBuilder: TextCellBuilder.text<User>((u) => u.field2),
      ),
      ColumnDefinition<User>(
        label: '位置',
        description: '电台位置',
        flex: 3,
        cellBuilder: TextCellBuilder.text<User>((u) => u.field3),
      ),
      ColumnDefinition<User>(
        label: 'SN',
        description: '电台SN号',
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field4),
      ),
    ];
  }

  Widget buildActionCell(User user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: isDark ? Colors.white : Colors.orange,
          ),
          tooltip: 'Edit',
          onPressed: () {
            // 编辑按钮
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: isDark ? Colors.white : Colors.red,
          ),
          tooltip: 'Delete',
          onPressed: () {
            // 删除按钮
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget buildEmptyWidget() {
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
              'No users found',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // 2026/6/15 下午2:54 勾选相关
  // =============================================================================
  bool get allSelected {
    final current = paginatedUsers;
    if (current.isEmpty) return false;
    return current.every((u) => selectedIds.contains(u.id));
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void toggleSelectAll() {
    setState(() {
      final current = paginatedUsers;
      if (allSelected) {
        for (final user in current) {
          selectedIds.remove(user.id);
        }
      } else {
        for (final user in current) {
          selectedIds.add(user.id);
        }
      }
    });
  }

  void clearSelection() {
    setState(() => selectedIds.clear());
  }
}
