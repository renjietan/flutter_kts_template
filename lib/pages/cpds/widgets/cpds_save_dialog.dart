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
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_radio_picker.dart';

String cpdsDetailKey(
  String netNodePackageName,
  String dcPackageName,
  String parentIdPath,
) => '$netNodePackageName\u0000$dcPackageName\u0000$parentIdPath';

String cpdsDisplayDownlinkIp(String? value) =>
    (value == null || value.trim().isEmpty) ? '--' : value;

int? cpdsDefaultRadioIdForDevice({
  required CpdsFutureWarriorDevice device,
  required String parentIdPath,
  required List<KeyLoaderDetailsEntity> existingDetails,
  required Set<int> availableRadioIds,
}) {
  final key = cpdsDetailKey(device.nodeId, device.device.id, parentIdPath);
  for (final detail in existingDetails) {
    if (cpdsDetailKey(
          detail.netNodePackageName,
          detail.dcPackageName,
          detail.parentIdPath,
        ) ==
        key) {
      final radioId = detail.radioId;
      if (radioId != null && availableRadioIds.contains(radioId)) {
        return radioId;
      }
      return null;
    }
  }
  return null;
}

List<RadiosEntity> cpdsAvailableRadios({
  required List<RadiosEntity> radios,
  required int? ownExistingRadioId,
  required int? ownSelectedRadioId,
  required Set<int> boundRadioIds,
  required Set<int> selectedByOthers,
}) {
  return radios.where((radio) {
    final id = radio.id;
    if (id == ownExistingRadioId || id == ownSelectedRadioId) return true;
    return !boundRadioIds.contains(id) && !selectedByOthers.contains(id);
  }).toList();
}

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
  Map<String, int?> _existingRadioIdByDevice = {};
  int? _selectedKeyLoaderId;
  int _currentPage = 1;
  int _pageSize = 10;
  StreamSubscription<AppLocale>? _localeSubscription;
  bool _closed = false;
  bool _saving = false;
  Set<int> _boundRadioIds = {};
  bool _radioOptionsLoading = false;
  Future<void>? _radiosFuture;
  List<KeyLoaderDetailsEntity> _existingDetails = const [];

  @override
  void initState() {
    super.initState();
    _keyLoaders = List<KeyLoadersEntity>.from(widget.keyLoaders);
    _selectedRadioId = {
      for (final fwDevice in widget.devices) fwDevice.key: null,
    };
    _radiosFuture = _loadRadios();
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
    _existingDetails = List<KeyLoaderDetailsEntity>.from(existing);
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
      _existingRadioIdByDevice = {};
      _radioOptionsLoading = value != null;
      for (final fwDevice in widget.devices) {
        _selectedRadioId[fwDevice.key] = null;
      }
    });
    if (value != null) {
      await _radiosFuture;
      await _loadBoundRadioIds(value);
      _applyExistingRadioDefaults();
    }
  }

  void _applyExistingRadioDefaults() {
    if (!mounted) return;
    final keyLoaderId = _selectedKeyLoaderId;
    if (keyLoaderId == null || _radios.isEmpty || _existingDetails.isEmpty) {
      return;
    }
    final availableRadioIds = {for (final radio in _radios) radio.id};
    final parentIdPath = _findUnitPath(widget.units, widget.unitId).join('/');
    final defaults = <String, int?>{};
    final ownExisting = <String, int?>{};
    for (final fwDevice in widget.devices) {
      final radioId = cpdsDefaultRadioIdForDevice(
        device: fwDevice,
        parentIdPath: parentIdPath,
        existingDetails: _existingDetails,
        availableRadioIds: availableRadioIds,
      );
      defaults[fwDevice.key] = radioId;
      ownExisting[fwDevice.key] = radioId;
    }
    setState(() {
      _selectedRadioId.addAll(defaults);
      _existingRadioIdByDevice = ownExisting;
    });
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
    return cpdsAvailableRadios(
      radios: _radios,
      ownExistingRadioId: _existingRadioIdByDevice[fwDevice.key],
      ownSelectedRadioId: _selectedRadioId[fwDevice.key],
      boundRadioIds: _boundRadioIds,
      selectedByOthers: selectedByOthers,
    );
  }

  void _clearRadio(CpdsFutureWarriorDevice fwDevice) {
    setState(() {
      _selectedRadioId[fwDevice.key] = null;
    });
  }

  Widget _buildRadioPicker(CpdsFutureWarriorDevice fwDevice) {
    final t = Translations.of(context);
    return CpdsRadioPickerField(
      selected: _radioFor(fwDevice),
      hint: t.cpds.saveDialog.selectPlaceholder,
      onTap: () => _openRadioPicker(fwDevice),
      onClear: () => _clearRadio(fwDevice),
    );
  }

  Future<void> _openRadioPicker(CpdsFutureWarriorDevice fwDevice) async {
    if (_selectedKeyLoaderId == null) {
      await _showSelectKeyLoaderFirstDialog();
      return;
    }
    final selected = await showCpdsRadioSidePanel(
      context: context,
      radios: _availableRadiosFor(fwDevice),
      selected: _radioFor(fwDevice),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedRadioId[fwDevice.key] = selected.id;
    });
  }

  Future<void> _showSelectKeyLoaderFirstDialog() async {
    final t = Translations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var closed = false;
        return AlertDialog(
          backgroundColor: const Color(0xFF20262D),
          title: Text(
            t.tips.title,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          content: Text(
            CpdsMessages.tr(
              dialogContext,
              '请先选择注钥枪',
              'Please select a key loader first',
              'يرجى تحديد جهاز تحميل المفاتيح أولاً',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                if (closed) return;
                closed = true;
                Navigator.of(dialogContext).pop();
              },
              child: Text(t.common.confirm),
            ),
          ],
        );
      },
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
        'downlinkIp': fwDevice.device.ip,
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
    final existingByKey = <String, KeyLoaderDetailsEntity>{};
    for (final row in existing) {
      existingByKey[_detailKey(
            row.netNodePackageName,
            row.dcPackageName,
            row.parentIdPath,
          )] =
          row;
    }
    return items
        .where((item) {
          final key = _detailKey(
            item['netNodePackageName']?.toString() ?? '',
            item['dcPackageName']?.toString() ?? '',
            parentIdPath,
          );
          return existingByKey.containsKey(key);
        })
        .map((item) {
          final key = _detailKey(
            item['netNodePackageName']?.toString() ?? '',
            item['dcPackageName']?.toString() ?? '',
            parentIdPath,
          );
          final existing = existingByKey[key];
          return <String, dynamic>{
            ...item,
            'originalRadioAlias': _radioAliasById(existing?.radioId),
          };
        })
        .toList();
  }

  String _detailKey(
    String netNodePackageName,
    String dcPackageName,
    String parentIdPath,
  ) => cpdsDetailKey(netNodePackageName, dcPackageName, parentIdPath);

  String? _radioAliasById(int? radioId) {
    if (radioId == null) return null;
    for (final radio in _radios) {
      if (radio.id == radioId) return radio.alias;
    }
    return null;
  }

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
                              columnWidth: FlexColumnWidth(1.0),
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
                              columnWidth: FlexColumnWidth(1.3),
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  CpdsMessages.tr(
                                    context,
                                    '别名',
                                    'Alias',
                                    'الاسم المستعار',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              columnWidth: FlexColumnWidth(1.2),
                              label: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  CpdsMessages.tr(
                                    context,
                                    '下发IP',
                                    'Downlink IP',
                                    'IP الإرسال',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              columnWidth: FlexColumnWidth(1.3),
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
                              columnWidth: FlexColumnWidth(1.6),
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
                              columnWidth: FlexColumnWidth(1.0),
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
                              columnWidth: FlexColumnWidth(1.0),
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
                                      cpdsDisplayDownlinkIp(device.ip),
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
                                    child: _buildRadioPicker(fwDevice),
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

  String _radioAliasOrDash(String? value) =>
      (value == null || value.trim().isEmpty) ? '--' : value;

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
                'البيانات التالية موجودة بالفعل. هل تريد الكتابة فوقها؟',
              ),
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
                    3: FlexColumnWidth(1.2),
                    4: FlexColumnWidth(1.2),
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
                        _headerCell(
                          CpdsMessages.tr(
                            context,
                            '配对电台(旧)',
                            'Matching Radio (Old)',
                            'جهاز الراديو المقترن (قديم)',
                          ),
                        ),
                        _headerCell(
                          CpdsMessages.tr(
                            context,
                            '配对电台(新)',
                            'Matching Radio (New)',
                            'جهاز الراديو المقترن (جديد)',
                          ),
                        ),
                      ],
                    ),
                    for (final item in duplicates)
                      TableRow(
                        children: [
                          _bodyCell(item['nodeName']?.toString() ?? '--'),
                          _bodyCell(item['deviceAlias']?.toString() ?? '--'),
                          _bodyCell(item['dcPackageName']?.toString() ?? '--'),
                          _bodyCell(
                            _radioAliasOrDash(
                              item['originalRadioAlias']?.toString(),
                            ),
                          ),
                          _bodyCell(
                            _radioAliasOrDash(item['radioAlias']?.toString()),
                          ),
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
