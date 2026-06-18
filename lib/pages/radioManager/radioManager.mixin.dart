import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/dialog/simple.form.dialog.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/radioManager/radio.model.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../components/TextField/simple.form.textfield.dart';
import '../../theme/table.theme.dart';

mixin RadioManagerMixin on State<RadioManagerPager> {
  late List<User> allUsers;
  final Set<String> selectedIds = {};
  final bool showCheckboxes = true;
  final formKey = GlobalKey<FormBuilderState>();

  List<User> filteredUsers = [];

  int currentPage = 1;
  int pageSize = 10;

  String searchQuery = '';

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
      padding: EdgeInsets.all(12),
      mainFilters: [
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: TextTitle(text: "电台管理"),
        ),
      ],
      trailingActions: [
        FilterSearchField(
          height: 36,
          hint: 'Search...',
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              applyFilters();
            });
          },
        ),
        BaseButton(
          label: "添加电台",
          width: 100,
          onPressed: () {
            showDialog();
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
              'No Data Found',
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

  Future<void> showDialog() async {
    SimpleFormDialog(
      title: '新增电台',
      confirmText: '新增电台',
      fields: [
        FormFieldConfig(
          name: 'deviceType',
          label: 'Device Type',
          hintText: '请输入设备类型',
          validators: [FormBuilderValidators.required(errorText: '设备类型不能为空')],
        ),
        FormFieldConfig(
          name: 'networkInterface',
          label: 'Network Interface',
          hintText: '请输入网络接口',
          validators: [],
        ),
      ],
      onConfirm: (v) {
        // 提交逻辑
        GlobalLogger.logInfo("表单数据: $v");
      },
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
