import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';

import '../../../components/TextField/simple.textfield.dart';
import '../../../theme/table.theme.dart';
import '../../radioManager/radio.model.dart';

class ParamsInjectTable extends StatefulWidget {
  // final int? currentPage;
  // final int? pageSize;
  // final String? searchQuery;
  final ThemePreset? themePreset;

  const ParamsInjectTable({super.key, this.themePreset = ThemePreset.dark});

  @override
  State<ParamsInjectTable> createState() => _ParamsInjectTableState();
}

class _ParamsInjectTableState extends State<ParamsInjectTable> {
  late final DataTablePlusTheme theme;
  List<User> allUsers = [];
  List<User> filteredUsers = [];
  int currentPage = 1;
  int pageSize = 10;
  String? searchQuery = "";
  bool get isDark => widget.themePreset == ThemePreset.dark;

  List<User> get paginatedUsers {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredUsers.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredUsers.length);
    return filteredUsers.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredUsers.length / pageSize).ceil().clamp(1, 999);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    theme = widget.themePreset == null
        ? getThemePreset(ThemePreset.dark)
        : getThemePreset(widget.themePreset!);
    allUsers = generateUsers(300);
    applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Loader"),
        SizedBox(height: 10),
        DataTablePlusThemeProvider(
          theme: theme,
          child: SimpleTextfield(
            height: 35,
            hint: "",
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            onChanged: (v) {
              searchQuery = v;
            },
          ),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          child: DataTablePlusThemeProvider(
            theme: theme,
            child: DataTablePlus<User>(
              items: paginatedUsers,
              idGetter: (user) => user.id,
              columns: buildColumns(),
              emptyWidget: buildEmptyWidget(),
              showCheckboxes: false,
            ),
          ),
        ),
      ],
    );
  }

  void applyFilters() {
    filteredUsers = allUsers.where((user) {
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

  List<ColumnDefinition<User>> buildColumns() {
    return [
      ColumnDefinition<User>(
        label: '通信参数包',
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field1),
      ),
      ColumnDefinition<User>(
        label: '配对电台',
        flex: 2,
        cellBuilder: TextCellBuilder.text<User>((u) => u.field2),
      ),
      ColumnDefinition<User>(
        label: '使用人',
        flex: 3,
        cellBuilder: TextCellBuilder.text<User>((u) => u.field3),
      ),
      ColumnDefinition<User>(
        label: '位置',
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field4),
      ),
      ColumnDefinition<User>(
        label: 'SN',
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<User>((u) => u.field4),
      ),
    ];
  }
}
