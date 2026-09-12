import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/dialog/simple.form.dialog.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_kts_template/utils/enum/dialog_enum.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

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
      Future.delayed(Duration(milliseconds: 70)).then((_) async {
        var radioResponse = await RadiosManagerApi.getAll();
        if (mounted) {
          context.read<RadiosProvider>().setRadios = radioResponse.data.list;
        }
        setState(() {
          data = res.data.list;
          GlobalLogger.logInfo(data.length.toString());
          totalItems = res.data.total;
          totalPages = (totalItems / pageSize).ceil().clamp(1, 999);
        });
        SimplePopup.hideLoading();
      });
    });
  }

  void create(Map<String, dynamic> v) {
    RadiosManagerApi.create(v).then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  Future<void> delete(RadiosEntity data) async {
    if (!await _confirmDelete()) return;
    RadiosManagerApi.delete("${data.id}").then((res) {
      _clearRadioBindings([data.id]);
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  Future<void> patchDelete() async {
    if (!await _confirmDelete()) return;
    String idsStr = selectedIds.join("、");
    RadiosManagerApi.delete(idsStr).then((res) {
      final ids = selectedIds
          .map((item) => int.tryParse(item) ?? 0)
          .where((item) => item != 0)
          .toList();
      _clearRadioBindings(ids);
      SimplePopup.success(t.common.OperationSuccess);
      clearSelection();
      getList();
    });
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await material.showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        title: Text(
          t.tips.title,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          t.tips.keyLoaders.confirmDelete,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.tips.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.common.confirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void update(RadiosEntity? data, Map<String, dynamic> v) {
    RadiosManagerApi.update(data!.id, data: v).then((res) {
      _updateRadioBindings(
        data.id,
        consumer: v['consumer'] as String?,
        location: v['location'] as String?,
        sn: v['sn'] as String?,
      );
      getList();
      SimplePopup.success(t.common.OperationSuccess);
    });
  }

  void _clearRadioBindings(List<int> radioIds) {
    if (radioIds.isEmpty) return;
    for (final radioId in radioIds) {
      final query = DatabaseManager.instance
          .box<KeyLoaderDetailsEntity>()
          .query(KeyLoaderDetailsEntity_.radioId.equals(radioId))
          .build();
      final details = query.find();
      for (final detail in details) {
        detail.radioId = null;
        detail.consumer = null;
        detail.location = null;
        detail.SN = null;
        DatabaseManager.instance.put<KeyLoaderDetailsEntity>(detail);
      }
    }
  }

  bool _isAliasCharAllowed(int code) {
    if ((code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        code == 0x20 ||
        _isChinese(code) ||
        _isArabicLetter(code) ||
        _isAsciiHalfWidthSymbol(code)) {
      return true;
    }
    return false;
  }

  int _aliasUnits(String value) {
    var units = 0;
    for (final code in value.runes) {
      units += _isAliasWide(code) ? 2 : 1;
    }
    return units;
  }

  bool _isAliasWide(int code) => _isChinese(code) || _isArabicLetter(code);

  bool _isChinese(int code) {
    return (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0xF900 && code <= 0xFAFF);
  }

  bool _isArabicLetter(int code) {
    return (code >= 0x0621 && code <= 0x063A) ||
        (code >= 0x0641 && code <= 0x064A) ||
        (code >= 0x066E && code <= 0x06D3) ||
        code == 0x06D5 ||
        (code >= 0x06EE && code <= 0x06EF) ||
        (code >= 0x06FA && code <= 0x06FC) ||
        code == 0x06FF ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFF);
  }

  bool _isAsciiHalfWidthSymbol(int code) {
    // 文件名非法字符：\ / : * ? " < > |
    const invalidFileNameSymbols = {
      0x22,
      0x2A,
      0x2F,
      0x3A,
      0x3C,
      0x3E,
      0x3F,
      0x5C,
      0x7C,
    };
    if (invalidFileNameSymbols.contains(code)) return false;
    return (code >= 0x21 && code <= 0x2F) ||
        (code >= 0x3A && code <= 0x40) ||
        (code >= 0x5B && code <= 0x60) ||
        (code >= 0x7B && code <= 0x7E);
  }

  void _updateRadioBindings(
    int radioId, {
    required String? consumer,
    required String? location,
    required String? sn,
  }) {
    final query = DatabaseManager.instance
        .box<KeyLoaderDetailsEntity>()
        .query(KeyLoaderDetailsEntity_.radioId.equals(radioId))
        .build();
    final details = query.find();
    for (final detail in details) {
      detail.radioId = radioId;
      detail.consumer = consumer;
      detail.location = location;
      detail.SN = sn;
      DatabaseManager.instance.put<KeyLoaderDetailsEntity>(detail);
    }
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
          textInputAction: TextInputAction.done,
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
          minWidth: 110,
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
        label: t.tableColumn.radioManager.location,
        description: t.tableColumn.radioManager.location_desc,
        flex: 1,
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.location),
      ),
      ColumnDefinition<RadiosEntity>(
        label: t.tableColumn.radioManager.sn,
        description: t.tableColumn.radioManager.sn_desc,
        // size: const ColumnSize.auto(),
        flex: 1,
        cellBuilder: TextCellBuilder.text<RadiosEntity>((u) => u.sn),
      ),
    ];
  }

  // 编辑、删除
  Widget buildActionCell(RadiosEntity data) {
    return Row(
      // mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF00A2E9)),
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
        SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 16, color: Color(0xFFF15B64)),
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
    final isEdit = type == DialogTypeEnum.edit;
    SimpleFormDialog(
      title: isEdit
          ? t.button.radioManager.editRadio
          : t.button.radioManager.createRadio,
      confirmText: isEdit
          ? t.button.radioManager.editRadio
          : t.button.radioManager.createRadio,
      twoColumn: true,
      dialogWidth: MediaQuery.sizeOf(context).width * 0.7,
      fields: [
        FormFieldConfig(
          name: 'alias',
          label: t.tableColumn.radioManager.alias,
          hintText: t.Form.radioManager.alias.placeholder,
          textEditingController: aliasTextEditController,
          required: true,
          labelHelpText: t.Form.radioManager.alias.help,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.alias.validate,
            ),
            (value) {
              if (value == null || value.isEmpty) return null;
              final units = _aliasUnits(value);
              if (units < 1 || units > 12) {
                return t.Form.radioManager.alias.invalidLength;
              }
              if (value != value.trim() ||
                  value.startsWith('.') ||
                  value.endsWith('.')) {
                return t.Form.radioManager.alias.invalid;
              }
              for (final code in value.runes) {
                if (!_isAliasCharAllowed(code)) {
                  return t.Form.radioManager.alias.invalid;
                }
              }
              return null;
            },
          ],
        ),
        FormFieldConfig(
          name: 'location',
          label: t.tableColumn.radioManager.location,
          hintText: t.Form.radioManager.location.placeholder,
          textEditingController: locationTextEditController,
          validators: [
            FormBuilderValidators.match(
              RegExp(r'^[a-zA-Z0-9 _]{0,50}$'),
              errorText: t.Form.radioManager.location.invalid,
              checkNullOrEmpty: false,
            ),
          ],
        ),
        FormFieldConfig(
          name: 'sn',
          label: t.tableColumn.radioManager.sn,
          hintText: t.Form.radioManager.sn.placeholder,
          textEditingController: snTextEditController,
          required: true,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.radioManager.sn.validate,
            ),
            FormBuilderValidators.match(
              RegExp(r'^[a-zA-Z0-9]{10}$'),
              errorText: t.Form.radioManager.sn.invalid,
              checkNullOrEmpty: false,
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
