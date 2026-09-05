import 'dart:async';
import 'dart:convert';

import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

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
  Map<String, int?> _selectedRadioId = {};
  int? _selectedKeyLoaderId;
  int _currentPage = 1;
  int _pageSize = 10;
  StreamSubscription<AppLocale>? _localeSubscription;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _loadRadios();
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
        _selectedRadioId = {
          for (final fwDevice in widget.devices) fwDevice.key: null,
        };
      });
    } catch (error) {
      GlobalLogger.logError('load radios failed: $error');
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
    final selectedByOthers = <int>{};
    _selectedRadioId.forEach((key, id) {
      if (key != fwDevice.key && id != null) {
        selectedByOthers.add(id);
      }
    });
    return _radios
        .where((radio) => !selectedByOthers.contains(radio.id))
        .toList();
  }

  void _save() {
    if (_closed) return;
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final parentIdPath = _findUnitPath(widget.units, widget.unitId);
    final json = {
      'keyLoaderId': _selectedKeyLoaderId,
      'parentIdPath': parentIdPath.join('/'),
      'items': widget.devices.map((fwDevice) {
        final radio = _radioFor(fwDevice);
        return {
          'netNodePackageName': fwDevice.nodeId,
          'dcPackageName': fwDevice.device.id,
          'deviceType': fwDevice.device.type.value,
          'deviceModel': fwDevice.device.model,
          'radioId': radio?.id,
          'radioAlias': radio?.alias ?? '',
          'consumer': radio?.consumer ?? '',
          'location': radio?.location ?? '',
          'sn': radio?.sn ?? '',
        };
      }).toList(),
    };
    GlobalLogger.logInfo('SAVE_JSON ${jsonEncode(json)}');
    _closed = true;
    widget.onSave(json);
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
                  items: widget.keyLoaders
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKeyLoaderId = value;
                    });
                  },
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
                                  t.tableColumn.injectEncrypt.consumer,
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
                                      device.model,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: DropdownButton<int?>(
                                      value: _selectedRadioId[fwDevice.key],
                                      hint: Text(
                                        t.cpds.saveDialog.selectPlaceholder,
                                      ),
                                      items: [
                                        ..._availableRadiosFor(fwDevice).map(
                                          (item) => DropdownMenuItem<int?>(
                                            value: item.id,
                                            child: Text(item.alias),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRadioId[fwDevice.key] =
                                              value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      radio?.consumer ?? '--',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
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
          onPressed: () {
            if (_closed) return;
            _closed = true;
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(t.button.radioManager.save)),
      ],
    );
  }
}
