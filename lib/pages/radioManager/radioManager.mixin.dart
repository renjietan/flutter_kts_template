import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/dialog/simple.form.dialog.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_kts_template/utils/enum/dialog_enum.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../api/RadiosManagerApi.dart';
import '../../components/TextField/simple.filter.search.textField.dart';
import '../../components/TextField/simple.form.textfield.dart';
import '../../core/entities/radios/radiosEntity.dart';
import '../../i18n/handle/translations.g.dart';
import '../../theme/table.theme.dart';

mixin RadioManagerMixin on State<RadioManagerPager> {
  // =============================================================================
  // 2026/6/30 下午4:34 table 相关
  // =============================================================================
  final searchFieldController = TextEditingController();
  late List<RadiosEntity> data = [];
  final Set<String> selectedIds = {};
  final bool showCheckboxes = true;
  int totalItems = 0;
  int currentPage = 1;
  int pageSize = 10;
  int totalPages = 0;
  String searchQuery = '';
  bool showColumnInfo = false;
  // =============================================================================
  // 2026/6/30 下午4:34 表单相关
  // =============================================================================
  final formKey = GlobalKey<FormBuilderState>();
  final aliasTextEditController = TextEditingController();
  final consumerTextEditController = TextEditingController();
  final locationTextEditController = TextEditingController();
  final snTextEditController = TextEditingController();

  // =============================================================================
  // 2026/6/29 接口请求
  // =============================================================================
  void getList() {
    RadiosManagerApi.getList(
      page: currentPage.toString(),
      pageSize: pageSize.toString(),
      keyword: searchQuery,
    ).then((res) {
      Future.delayed(Duration(milliseconds: 70)).then((_) {
        SimplePopup.hideLoading();
        setState(() {
          data = res.data.list;
          GlobalLogger.logInfo(data.length.toString());
          totalItems = res.data.total;
          totalPages = (totalItems / pageSize).ceil().clamp(1, 999);
        });
      });
    });
  }

  void create(Map<String, dynamic> v) {
    RadiosManagerApi.create(v).then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  void delete(RadiosEntity data) {
    RadiosManagerApi.delete("${data.id}").then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  void patchDelete() {
    String idsStr = selectedIds.join("、");
    RadiosManagerApi.delete(idsStr).then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      clearSelection();
      getList();
    });
  }

  void update(RadiosEntity? data, Map<String, dynamic> v) {
    RadiosManagerApi.update(data!.id, data: v).then((res) {
      getList();
      SimplePopup.toast(t.common.OperationSuccess);
    });
  }

  // =============================================================================
  // 2026/6/15 下午3:02
  // 判断是否是深色主题, 用于样式判断
  //
  // =============================================================================
  bool get isDark => widget.themePreset == ThemePreset.dark;
  // =============================================================================
  // 2026/6/15 下午2:54 构建 widget
  // =============================================================================
  // 搜索-工具栏
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
        SimpleFilterSearchField(
          height: 36,
          controller: searchFieldController,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          onSubmit: (value) {
            SimplePopup.loading();
            currentPage = 1;
            getList();
          },
        ),
        BaseButton(
          label: t.button.radioManager.createRadio,
          width: 100,
          onPressed: () {
            aliasTextEditController.text = "";
            consumerTextEditController.text = "";
            locationTextEditController.text = "";
            snTextEditController.text = "";
            showDialog(DialogTypeEnum.create, null);
          },
        ),
        FilterResetButton(
          tooltip: t.button.radioManager.resetRadio,
          onReset: () {
            setState(() {
              searchQuery = '';
              searchFieldController.text = "";
              SimplePopup.loading();
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
  Widget buildActionCell(RadiosEntity data) {
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
            showDialog(DialogTypeEnum.edit, data);
            aliasTextEditController.text = data.alias;
            consumerTextEditController.text = data.consumer;
            locationTextEditController.text = data.location;
            snTextEditController.text = data.sn;
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
            delete(data);
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

  Future<void> showDialog(DialogTypeEnum type, RadiosEntity? rowData) async {
    SimpleFormDialog(
      title: t.button.radioManager.createRadio,
      confirmText: t.button.radioManager.createRadio,
      fields: [
        FormFieldConfig(
          name: 'alias',
          label: t.tableColumn.radioManager.alias,
          hintText: t.Form.radioManager.alias.placeholder,
          textEditingController: aliasTextEditController,
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
          textEditingController: consumerTextEditController,
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
          textEditingController: locationTextEditController,
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
          textEditingController: snTextEditController,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.sn.validate,
            ),
          ],
        ),
      ],
      onConfirm: (v) {
        if (type == DialogTypeEnum.create) {
          create(v);
        } else {
          update(rowData, v);
        }
      },
    );
  }

  // =============================================================================
  // 2026/6/15 下午2:54 勾选相关
  // =============================================================================
  bool get allSelected {
    final current = data;
    if (current.isEmpty) return false;
    return current.every((u) => selectedIds.contains(u.id.toString()));
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
      final current = data;
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

  @override
  void dispose() {
    aliasTextEditController.dispose();
    consumerTextEditController.dispose();
    locationTextEditController.dispose();
    snTextEditController.dispose();
    searchFieldController.dispose();
    super.dispose();
  }
}
