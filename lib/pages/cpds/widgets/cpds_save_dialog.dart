import 'dart:async';
import 'dart:convert';

import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_messages.dart';

class CpdsFutureWarriorSaveDialog extends StatefulWidget {
  const CpdsFutureWarriorSaveDialog({
    super.key,
    required this.devices,
    required this.unitId,
    required this.units,
    required this.keyLoaders,
    required this.onSave,
  });

  final List<CpdsFutureWarriorDevice> devices;
  final String unitId;
  final List<CpdsUnit> units;
  final List<KeyLoadersEntity> keyLoaders;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  State<CpdsFutureWarriorSaveDialog> createState() =>
      _CpdsFutureWarriorSaveDialogState();
}

class _CpdsFutureWarriorSaveDialogState
    extends State<CpdsFutureWarriorSaveDialog> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  List<RadiosEntity> _radios = [];
  List<KeyLoadersEntity> _keyLoaders = [];
  Map<String, int?> _selectedRadioId = {};
  int? _selectedKeyLoaderId;
  int _currentPage = 1;
  int _pageSize = 10;
  StreamSubscription<AppLocale>? _localeSubscription;
  bool _closed = false;
  bool _saving = false;
  Set<int> _boundRadioIds = {};
  bool _radioOptionsLoading = false;

  @override
  void initState() {
    super.initState();
    _keyLoaders = List<KeyLoadersEntity>.from(widget.keyLoaders);
    _selectedRadioId = {
      for (final fwDevice in widget.devices) fwDevice.key: null,
    };
    _loadRadios();
    _loadKeyLoaders();
    _localeSubscription = LocaleSettings.getLocaleStream().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _localeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRadios() async {
    try {
      final response = await RadiosManagerApi.getAll();
      if (!mounted) return;
      setState(() {
        _radios = response.data.list;
      });
    } catch (error) {
      GlobalLogger.logError('load radios failed: $error');
    }
  }

  Future<void> _loadKeyLoaders() async {
    try {
      final response = await KeyLoadersApi.getAll();
      if (!mounted) return;
      setState(() {
        _keyLoaders = List<KeyLoadersEntity>.from(response.data.list as List);
      });
    } catch (error) {
      GlobalLogger.logError('load key loaders failed: $error');
    }
  }

  Future<void> _loadBoundRadioIds(int keyLoaderId) async {
    final detailBox = DatabaseManager.instance.box<KeyLoaderDetailsEntity>();
    final existing = detailBox
        .query(KeyLoaderDetailsEntity_.keyLoaderId.equals(keyLoaderId))
        .build()
        .find();
    final boundIds = {
      for (final item in existing)
        if (item.radioId != null) item.radioId!,
    };
    if (!mounted) return;
    setState(() {
      _boundRadioIds = boundIds;
      _radioOptionsLoading = false;
    });
  }

  Future<void> _onKeyLoaderChanged(int? value) async {
    setState(() {
      _selectedKeyLoaderId = value;
      _boundRadioIds = {};
      _radioOptionsLoading = value != null;
      for (final fwDevice in widget.devices) {
        _selectedRadioId[fwDevice.key] = null;
      }
    });
    if (value != null) {
      await _loadBoundRadioIds(value);
    }
  }

  int get _pageCount =>
      (widget.devices.length / _pageSize).ceil().clamp(1, 999999);

  List<CpdsFutureWarriorDevice> get _pagedDevices {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= widget.devices.length) return const [];
    final end = (start + _pageSize).clamp(0, widget.devices.length);
    return widget.devices.sublist(start, end);
  }

  RadiosEntity? _radioFor(CpdsFutureWarriorDevice fwDevice) {
    final id = _selectedRadioId[fwDevice.key];
    if (id == null) return null;
    for (final radio in _radios) {
      if (radio.id == id) return radio;
    }
    return null;
  }

  List<RadiosEntity> _availableRadiosFor(CpdsFutureWarriorDevice fwDevice) {
    if (_selectedKeyLoaderId == null || _radioOptionsLoading) return const [];
    final selectedByOthers = <int>{};
    _selectedRadioId.forEach((key, id) {
      if (key != fwDevice.key && id != null) {
        selectedByOthers.add(id);
      }
    });
    return _radios
        .where(
          (radio) =>
              !_boundRadioIds.contains(radio.id) &&
              !selectedByOthers.contains(radio.id),
        )
        .toList();
  }

  void _clearRadio(CpdsFutureWarriorDevice fwDevice) {
    setState(() {
      _selectedRadioId[fwDevice.key] = null;
    });
  }

  Widget _buildRadioDropdown(CpdsFutureWarriorDevice fwDevice) {
    final t = Translations.of(context);
    final items = [
      ..._availableRadiosFor(fwDevice).map(
        (item) => DropdownMenuItem<int?>(
          value: item.id,
          child: Text(item.alias),
        ),
      ),
    ];
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF282D33),
        border: Border.all(color: const Color(0xFF353A41)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedRadioId[fwDevice.key],
                isExpanded: true,
                hint: Text(
                  t.cpds.saveDialog.selectPlaceholder,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white54,
                ),
                dropdownColor: const Color(0xFF282D33),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: items,
                onChanged: (value) {
                  setState(() {
                    _selectedRadioId[fwDevice.key] = value;
                  });
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _clearRadio(fwDevice),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    if (_closed || _saving) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_closed || _saving) return;
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final keyLoaderId = _selectedKeyLoaderId;
    if (keyLoaderId == null) return;

    final parentIdPath = _findUnitPath(widget.units, widget.unitId).join('/');
    final items = widget.devices.map((fwDevice) {
      final radio = _radioFor(fwDevice);
      return {
        'netNodePackageName': fwDevice.nodeId,
        'dcPackageName': fwDevice.device.id,
        'nodeName': fwDevice.nodeName,
        'deviceAlias': fwDevice.device.alias,
        'deviceType': fwDevice.device.type.value,
        'deviceModel': fwDevice.device.model,
        'radioId': radio?.id,
        'radioAlias': radio?.alias ?? '',
        'consumer': radio?.consumer,
        'location': radio?.location,
        'sn': radio?.sn,
      };
    }).toList();

    setState(() => _saving = true);
    try {
      final duplicates = await _findDuplicates(
        keyLoaderId,
        items,
        parentIdPath,
      );
      final duplicateKeys = {
        for (final item in duplicates)
          _detailKey(
            item['netNodePackageName']?.toString() ?? '',
            item['dcPackageName']?.toString() ?? '',
            parentIdPath,
          ),
      };
      final nonDuplicates = items.where((item) {
        final key = _detailKey(
          item['netNodePackageName']?.toString() ?? '',
          item['dcPackageName']?.toString() ?? '',
          parentIdPath,
        );
        return !duplicateKeys.contains(key);
      }).toList();

      if (duplicates.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) =>
              CpdsFutureWarriorDuplicateDialog(duplicates: duplicates),
        );
        if (proceed != true) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }

      _closed = true;
      if (mounted) Navigator.of(context).pop();
      final json = {
        'keyLoaderId': keyLoaderId,
        'parentIdPath': parentIdPath,
        'items': nonDuplicates,
        'overwrites': duplicates,
      };
      GlobalLogger.logInfo('SAVE_JSON ${jsonEncode(json)}');
      widget.onSave(json);
    } catch (error) {
      GlobalLogger.logError('save future warrior failed: $error');
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<Map<String, dynamic>>> _findDuplicates(
    int keyLoaderId,
    List<Map<String, dynamic>> items,
    String parentIdPath,
  ) async {
    final detailBox = DatabaseManager.instance.box<KeyLoaderDetailsEntity>();
    final existing = detailBox
        .query(KeyLoaderDetailsEntity_.keyLoaderId.equals(keyLoaderId))
        .build()
        .find();
    final existingKeys = {
      for (final row in existing)
        _detailKey(row.netNodePackageName, row.dcPackageName, row.parentIdPath),
    };
    return items.where((item) {
      final key = _detailKey(
        item['netNodePackageName']?.toString() ?? '',
        item['dcPackageName']?.toString() ?? '',
        parentIdPath,
      );
      return existingKeys.contains(key);
    }).toList();
  }

  String _detailKey(
    String netNodePackageName,
    String dcPackageName,
    String parentIdPath,
  ) => '$netNodePackageName\u0000$dcPackageName\u0000$parentIdPath';

  List<String> _findUnitPath(List<CpdsUnit> units, String unitId) {
    final path = <String>[];
    bool search(List<CpdsUnit> items) {
      for (final unit in items) {
        if (unit.id == unitId) {
          path.add(unit.id);
          return true;
        }
        if (search(unit.subUnits)) {
          path.insert(0, unit.id);
          return true;
        }
      }
      return false;
    }

    search(units);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        t.button.radioManager.save,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 920,
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedKeyLoaderId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t.Form.paramsInject.selectKeyLoader.text,
                    hintText: t.Form.paramsInject.selectKeyLoader.placeholder,
                    filled: true,
                    fillColor: const Color(0xFF282D33),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  items: _keyLoaders
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: _onKeyLoaderChanged,
                  validator: (value) => value == null
                      ? t.Form.paramsInject.selectKeyLoader.placeholder
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  t.pager.injectEncrypt.paramPairing,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_radios.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          border: TableBorder.all(
                            color: const Color(0xFF353A41),
                          ),
                          headingRowColor: WidgetStatePropertyAll(
                            const Color(0xFF292E33),
                          ),
                          horizontalMargin: 0,
                          columnSpacing: 8,
                          columns: [
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.parameterPacket,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  CpdsMessages.tr(context, '别名', 'Alias', 'الاسم المستعار'),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  t.Form.paramsInject.deviceType.text,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.radio,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.location,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.SN,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          rows: _pagedDevices.map((fwDevice) {
                            final device = fwDevice.device;
                            final radio = _radioFor(fwDevice);
                            final index = widget.devices.indexOf(fwDevice);
                            return DataRow(
                              color: WidgetStatePropertyAll(
                                index.isEven
                                    ? const Color(0xFF171C22)
                                    : const Color(0xFF292E33),
                              ),
                              cells: [
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      device.id,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      device.alias,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      device.model,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _buildRadioDropdown(fwDevice),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      radio?.location ?? '--',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      radio?.sn ?? '--',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      DataTablePlusThemeProvider(
                        theme: getThemePreset(ThemePreset.dark),
                        child: TablePagination(
                          currentPage: _currentPage,
                          totalPages: _pageCount,
                          totalItems: widget.devices.length,
                          pageSize: _pageSize,
                          pageSizeOptions: const [10, 20, 50, 100],
                          onPageSizeChanged: (size) {
                            setState(() {
                              _pageSize = size;
                              _currentPage = 1;
                            });
                          },
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemRangeTemplate: '',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _cancel,
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(t.button.radioManager.save),
        ),
      ],
    );
  }
}

class CpdsFutureWarriorDuplicateDialog extends StatelessWidget {
  const CpdsFutureWarriorDuplicateDialog({super.key, required this.duplicates});

  final List<Map<String, dynamic>> duplicates;

  Widget _headerCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _bodyCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        t.tips.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CpdsMessages.tr(
                  context,
                  '以下数据已存在，是否确认覆盖？',
                  'The following data already exists. Overwrite?',
                  'البيانات التالية موجودة بالفعل. هل تريد الكتابة فوقها؟'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: const Color(0xFF6B7480)),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        _headerCell(t.pager.radioManager.netNode),
                        _headerCell(
                          '${t.tableColumn.injectEncrypt.parameterPacket}'
                          '${CpdsMessages.tr(context, '别名', ' Alias', 'الاسم المستعار')}',
                        ),
                        _headerCell(
                          t.tableColumn.injectEncrypt.parameterPacket,
                        ),
                      ],
                    ),
                    for (final item in duplicates)
                      TableRow(
                        children: [
                          _bodyCell(item['nodeName']?.toString() ?? '--'),
                          _bodyCell(item['deviceAlias']?.toString() ?? '--'),
                          _bodyCell(item['dcPackageName']?.toString() ?? '--'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.tips.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.tips.ok),
        ),
      ],
    );
  }
}
