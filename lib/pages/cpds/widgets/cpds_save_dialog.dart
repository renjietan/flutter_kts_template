import 'dart:async';
import 'dart:convert';

import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/api/RadiosManagerApi.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CpdsFutureWarriorSaveDialog extends StatefulWidget {
  const CpdsFutureWarriorSaveDialog({
    super.key,
    required this.devices,
    required this.selectedNodeId,
    required this.units,
    required this.onSave,
  });

  final List<CpdsDevice> devices;
  final String selectedNodeId;
  final List<CpdsUnit> units;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  State<CpdsFutureWarriorSaveDialog> createState() =>
      _CpdsFutureWarriorSaveDialogState();
}

class _CpdsFutureWarriorSaveDialogState
    extends State<CpdsFutureWarriorSaveDialog> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _nameController = TextEditingController();
  List<RadiosEntity> _radios = [];
  Map<String, int?> _selectedRadioId = {};
  int _currentPage = 1;
  int _pageSize = 10;
  StreamSubscription<AppLocale>? _localeSubscription;

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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRadios() async {
    try {
      final response = await RadiosManagerApi.getAll();
      if (!mounted) return;
      setState(() {
        _radios = response.data.list;
        _selectedRadioId = {
          for (final device in widget.devices) device.key: null,
        };
      });
    } catch (error) {
      GlobalLogger.logError('load radios failed: $error');
    }
  }

  int get _pageCount =>
      (widget.devices.length / _pageSize).ceil().clamp(1, 999999);

  List<CpdsDevice> get _pagedDevices {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= widget.devices.length) return const [];
    final end = (start + _pageSize).clamp(0, widget.devices.length);
    return widget.devices.sublist(start, end);
  }

  RadiosEntity? _radioFor(CpdsDevice device) {
    final id = _selectedRadioId[device.key];
    if (id == null) return null;
    for (final radio in _radios) {
      if (radio.id == id) return radio;
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final parentIdPath = _findParentIdPath(
      widget.units,
      widget.selectedNodeId,
    );
    final json = {
      'name': _nameController.text.trim(),
      'nodeId': widget.selectedNodeId,
      'parentIdPath': parentIdPath.join('/'),
      'items': widget.devices.map((device) {
        final radio = _radioFor(device);
        return {
          'communicationParameterPackage': device.id,
          'deviceType': device.type.value,
          'deviceModel': device.model,
          'radioId': radio?.id,
          'radioAlias': radio?.alias ?? '',
          'consumer': radio?.consumer ?? '',
          'location': radio?.location ?? '',
          'sn': radio?.sn ?? '',
        };
      }).toList(),
    };
    GlobalLogger.logInfo('SAVE_JSON ${jsonEncode(json)}');
    widget.onSave(json);
  }

  List<String> _findParentIdPath(List<CpdsUnit> units, String nodeId) {
    final path = <String>[];
    bool search(List<CpdsUnit> items) {
      for (final unit in items) {
        if (unit.nodeIds.contains(nodeId)) {
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
                FormBuilderTextField(
                  name: 'name',
                  controller: _nameController,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: t.cpds.saveDialog.nameRequired,
                    ),
                    (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return null;
                      final valid = RegExp(
                        r'^[a-zA-Z0-9_\-\u4e00-\u9fa5]+$',
                      ).hasMatch(input);
                      return valid ? null : t.cpds.saveDialog.nameInvalid;
                    },
                  ]),
                  decoration: InputDecoration(
                    labelText: t.cpds.saveDialog.nameLabel,
                    hintText: t.cpds.saveDialog.nameHint,
                    filled: true,
                    fillColor: const Color(0xFF282D33),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.pager.injectEncrypt.paramPairing,
                  style: TextStyle(
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
                                padding: EdgeInsets.only(left: 8),
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
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.radio,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.consumer,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.location,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  t.tableColumn.injectEncrypt.SN,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          rows: _pagedDevices.map((device) {
                            final radio = _radioFor(device);
                            final index = widget.devices.indexOf(device);
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
                                      value: _selectedRadioId[device.key],
                                      hint: Text(
                                        t.cpds.saveDialog.selectPlaceholder,
                                      ),
                                      items: [
                                        ..._radios.map(
                                          (item) => DropdownMenuItem<int?>(
                                            value: item.id,
                                            child: Text(item.alias),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRadioId[device.key] = value;
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(t.button.radioManager.save)),
      ],
    );
  }
}
