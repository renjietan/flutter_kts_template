import 'package:composable_data_table/composable_data_table.dart';
import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/radioManager/radio.model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../logger/logger.dart';
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
    with AutomaticKeepAliveClientMixin {
  final Set<String> _selectedIds = {};
  final bool _showCheckboxes = true;
  late List<User> _allUsers;
  List<User> _filteredUsers = [];

  int _currentPage = 1;
  int _pageSize = 10;

  String _searchQuery = '';

  bool _showColumnInfo = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _allUsers = generateUsers(300);
    _applyFilters();
  }

  bool get _isDark => widget.themePreset == ThemePreset.dark;

  void _applyFilters() {
    _filteredUsers = _allUsers.where((user) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.field1.toLowerCase().contains(query) &&
            !user.field2.toLowerCase().contains(query) &&
            !user.id.toLowerCase().contains(query) &&
            !user.field3.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
    _currentPage = 1;
  }

  List<User> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= _filteredUsers.length) return [];
    final endIndex = (startIndex + _pageSize).clamp(0, _filteredUsers.length);
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  int get _totalPages =>
      (_filteredUsers.length / _pageSize).ceil().clamp(1, 999);

  bool get _allSelected {
    final current = _paginatedUsers;
    if (current.isEmpty) return false;
    return current.every((u) => _selectedIds.contains(u.id));
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final current = _paginatedUsers;
      if (_allSelected) {
        for (final user in current) {
          _selectedIds.remove(user.id);
        }
      } else {
        for (final user in current) {
          _selectedIds.add(user.id);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                selectedCount: _selectedIds.length,
                normalToolbar: _buildToolbar(),
                selectedCountTemplate: '{count} selected',
                selectAllWidget: OutlinedButton(
                  onPressed: _toggleSelectAll,
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
                    _allSelected
                        ? 'Deselect All'
                        : 'Select All (${_paginatedUsers.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                actions: [
                  // 执行操作按钮时的弹窗
                  OutlinedButton.icon(
                    onPressed: _clearSelection,
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
                      _clearSelection();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${_selectedIds.length})'),
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
                    items: _paginatedUsers,
                    idGetter: (user) => user.id,
                    selectedIds: _selectedIds,
                    allSelected: _allSelected,
                    showCheckboxes: _showCheckboxes,
                    onSelectionChanged: _toggleSelection,
                    onSelectAllChanged: _toggleSelectAll,
                    columns: _buildColumns(),
                    // 设置未null时,不显示操作列
                    actionBuilder: _buildActionCell,
                    actionLabel: 'Actions',
                    emptyWidget: _buildEmptyWidget(),
                    // 在列头下方显示[字段描述]
                    showColumnInfo: _showColumnInfo,
                    // 显示字段描述, showColumnInfo 设置为 false 时,此处无效
                    onToggleColumnInfo: () =>
                        setState(() => _showColumnInfo = !_showColumnInfo),
                  ),
                ),
              ),
            ),
            DataTablePlusThemeProvider(
              theme: widget.theme,
              child: TablePagination(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _filteredUsers.length,
                pageSize: _pageSize,
                pageSizeOptions: const [10, 20, 50, 100],
                onPageSizeChanged: (size) => setState(() {
                  _pageSize = size;
                  _currentPage = 1;
                }),
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemRangeTemplate: 'Showing {start}-{end} of {total} users',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
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
              _searchQuery = value;
              _applyFilters();
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
              _searchQuery = '';
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  List<ColumnDefinition<User>> _buildColumns() {
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

  Widget _buildActionCell(User user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: _isDark ? Colors.white : Colors.orange,
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
            color: _isDark ? Colors.white : Colors.red,
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

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: _isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 14,
                color: _isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 12,
                color: _isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
