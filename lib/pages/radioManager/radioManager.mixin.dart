import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/dialog/simple.form.dialog.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../api/RadiosManagerApi.dart';
import '../../components/TextField/simple.form.textfield.dart';
import '../../core/entities/radios/radiosEntity.dart';
import '../../i18n/handle/translations.g.dart';
import '../../theme/table.theme.dart';
import '../../utils/response/BaseListResponse.dart';

mixin RadioManagerMixin on State<RadioManagerPager> {
  late List<RadiosEntity> data = [];
  late List<RadiosEntity> filteredData = [];
  int totalItems = 0;
  final Set<String> selectedIds = {};
  final bool showCheckboxes = true;
  final formKey = GlobalKey<FormBuilderState>();

  int currentPage = 1;
  int pageSize = 10;

  String searchQuery = '';

  bool showColumnInfo = false;

  // =============================================================================
  // 2026/6/29 数据获取
  // =============================================================================
  void getList() {
    RadiosManagerApi.getList(
      page: currentPage.toString(),
      pageSize: pageSize.toString(),
      keyword: searchQuery,
    ).then((BaseListResponse<RadiosEntity> res) {
      setState(() {
        data = res.list;
        totalItems = res.total;
      });
    });
  }

  // =============================================================================
  // 2026/6/15 下午3:02 判断是否是深色主题, 用于样式判断
  // =============================================================================
  bool get isDark => widget.themePreset == ThemePreset.dark;

  // =============================================================================
  // 2026/6/15 下午2:47 分页相关
  // =============================================================================

  void applyFilters() {
    filteredData = data.where((item) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!item.alias.toLowerCase().contains(query) &&
            !item.consumer.toLowerCase().contains(query) &&
            !item.location.toLowerCase().contains(query) &&
            !item.sn.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
    currentPage = 1;
  }

  List<RadiosEntity> get paginatedData {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredData.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int get totalPages => (totalItems / pageSize).ceil().clamp(1, 999);

  // =============================================================================
  // 2026/6/15 下午2:54 构建 widget
  // =============================================================================
  // 勾选框-工具栏
  Widget buildToolbar(BuildContext context) {
    final t = Translations.of(context);
    return TableFilterToolbar(
      padding: EdgeInsets.all(12),
      mainFilters: [
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: TextTitle(text: t.pager.radioManager.title),
        ),
      ],
      trailingActions: [
        FilterSearchField(
          height: 36,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              getList();
            });
          },
        ),
        BaseButton(
          label: t.button.radioManager.createRadio,
          width: 100,
          onPressed: () {
            showDialog(context);
          },
        ),
        FilterResetButton(
          tooltip: t.button.radioManager.resetRadio,
          onReset: () {
            setState(() {
              searchQuery = '';
              getList();
            });
          },
        ),
      ],
    );
  }

  // 列
  List<ColumnDefinition<RadiosEntity>> buildColumns(BuildContext context) {
    final t = Translations.of(context);
    return [
      ColumnDefinition<RadiosEntity>(
        label: t.tableColumn.radioManager.alias,
        description: t.tableColumn.radioManager.alias_desc,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.alias),
      ),
      ColumnDefinition<RadiosEntity>(
        label: t.tableColumn.radioManager.consumer,
        description: t.tableColumn.radioManager.consumer_desc,
        flex: 2,
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.consumer),
      ),
      ColumnDefinition<RadiosEntity>(
        label: t.tableColumn.radioManager.location,
        description: t.tableColumn.radioManager.location_desc,
        flex: 3,
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.location),
      ),
      ColumnDefinition<RadiosEntity>(
        label: t.tableColumn.radioManager.sn,
        description: t.tableColumn.radioManager.sn_desc,
        size: const ColumnSize.auto(),
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.sn),
      ),
    ];
  }

  // 编辑、删除
  Widget buildActionCell(RadiosEntity user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: isDark ? Colors.white : Colors.orange,
          ),
          tooltip: t.button.radioManager.edit,
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
          tooltip: t.button.radioManager.delete,
          onPressed: () {
            // 删除按钮
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // 空
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

  Future<void> showDialog(BuildContext context) async {
    final t = Translations.of(context);
    SimpleFormDialog(
      title: t.button.radioManager.createRadio,
      confirmText: t.button.radioManager.createRadio,
      fields: [
        FormFieldConfig(
          name: 'alias',
          label: t.tableColumn.radioManager.alias,
          hintText: t.Form.radioManager.alias.placeholder,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.alias.validate,
            ),
          ],
        ),
        FormFieldConfig(
          name: 'consumer',
          label: t.tableColumn.radioManager.consumer,
          hintText: t.Form.radioManager.consumer.placeholder,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.consumer.validate,
            ),
          ],
        ),
        FormFieldConfig(
          name: 'location',
          label: t.tableColumn.radioManager.location,
          hintText: t.Form.radioManager.location.placeholder,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.location.validate,
            ),
          ],
        ),
        FormFieldConfig(
          name: 'sn',
          label: t.tableColumn.radioManager.sn,
          hintText: t.Form.radioManager.sn.placeholder,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.sn.validate,
            ),
          ],
        ),
      ],
      onConfirm: (v) {
        // 提交逻辑
        RadiosManagerApi.create(v).then((res) {
          GlobalLogger.logInfo("表单数据: $v");
        });
      },
    );
  }

  // =============================================================================
  // 2026/6/15 下午2:54 勾选相关
  // =============================================================================
  bool get allSelected {
    final current = paginatedData;
    if (current.isEmpty) return false;
    return current.every((u) => selectedIds.contains(u.id));
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

  void clearSelection() {
    setState(() => selectedIds.clear());
  }
}
