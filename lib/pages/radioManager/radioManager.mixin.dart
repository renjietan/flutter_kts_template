import 'package:composable_data_table/composable_data_table.dart';
import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/pages/radioManager/radio.model.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../logger/logger.dart';
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
          width: 125,
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
          30.w,
          25.h,
          30.w,
          MediaQuery.of(context).viewInsets.bottom > 0
              ? 20.h
              : 90.h, // 键盘弹出时减小底部间距
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
              key: formKey,
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
                        fontSize: 16.sp,
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
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
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
                        fontSize: 16.sp,
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
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
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
