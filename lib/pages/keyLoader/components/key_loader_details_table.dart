import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:composable_data_table/composable_data_table.dart';
import 'package:dage/dage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/core/utils/time.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'set_password_dialog.dart';

class KeyLoaderDetailsTable extends StatefulWidget {
  const KeyLoaderDetailsTable({
    super.key,
    required this.keyLoaderEntity,
    this.themePreset = ThemePreset.dark,
  });

  final KeyLoadersEntity? keyLoaderEntity;
  final ThemePreset themePreset;

  @override
  State<KeyLoaderDetailsTable> createState() => _KeyLoaderDetailsTableState();
}

class _KeyLoaderDetailsTableState extends State<KeyLoaderDetailsTable> {
  late final DataTablePlusTheme _theme;
  int _currentPage = 1;
  int _pageSize = 10;
  List<KeyLoaderDetailsEntity> _allData = [];
  final Set<String> _selectedIds = {};
  Future<List<KeyLoaderDetailsEntity>>? _future;
  RadiosProvider? _radiosProvider;

  @override
  void initState() {
    super.initState();
    _theme = _buildTheme();
    _future = _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RadiosProvider>();
      _radiosProvider = provider;
      provider.addListener(_onRadiosChanged);
    });
  }

  void _onRadiosChanged() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  void dispose() {
    _radiosProvider?.removeListener(_onRadiosChanged);
    super.dispose();
  }

  DataTablePlusTheme _buildTheme() {
    return const DataTablePlusTheme(
      backgroundColor: Colors.transparent,
      headerBackgroundColor: Colors.transparent,
      borderColor: Color(0xFF353A41),
      borderLightColor: Color(0xFF282D33),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFB7BCC6),
      textMutedColor: Color(0xFF8A94A6),
      accentColor: Color(0xFF00A2E9),
      accentLightColor: Color(0xFF1E3A5F),
      successColor: Color(0xFF2FC88F),
      successLightColor: Color(0xFF1B3D1B),
      warningColor: Color(0xFFF0A43A),
      warningLightColor: Color(0xFF4D3800),
      dangerColor: Color(0xFFF15B64),
      dangerLightColor: Color(0xFF4D1F1F),
      cellPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      headerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      cellTextStyle: TextStyle(fontSize: 13, color: Colors.white),
      headerTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant KeyLoaderDetailsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyLoaderEntity?.id != widget.keyLoaderEntity?.id) {
      _future = _load();
      _currentPage = 1;
      _allData = [];
      _selectedIds.clear();
    }
  }

  Future<List<KeyLoaderDetailsEntity>> _load() async {
    final entity = widget.keyLoaderEntity;
    if (entity == null) return [];
    final response = await KeyLoadersApi.getDetails(entity.id);
    final list = response.data['list'] as List? ?? const [];
    return list
        .map(
          (item) =>
              KeyLoaderDetailsEntity.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  List<KeyLoaderDetailsEntity> get _pagedData {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _allData.length) return const [];
    final end = (start + _pageSize).clamp(0, _allData.length);
    return _allData.sublist(start, end);
  }

  int get _totalPages => (_allData.length / _pageSize).ceil().clamp(1, 999999);

  bool get _allSelected =>
      _pagedData.isNotEmpty &&
      _pagedData.every((item) => _selectedIds.contains(item.id.toString()));

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
      if (_allSelected) {
        for (final item in _pagedData) {
          _selectedIds.remove(item.id.toString());
        }
      } else {
        for (final item in _pagedData) {
          _selectedIds.add(item.id.toString());
        }
      }
    });
  }

  Future<void> _exportSelected() async {
    final selectedRows = _allData
        .where((item) => _selectedIds.contains(item.id.toString()))
        .toList();

    if (selectedRows.any((item) => item.radioId == null)) {
      SimplePopup.error(t.cpds.export.radioRequired);
      return;
    }

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const SetPasswordDialog(),
    );
    if (password == null) return;

    final selectedJson = selectedRows.map((item) => item.toJson()).toList();
    GlobalLogger.logInfo(
      'EXPORT_SELECTED ${const JsonEncoder.withIndent('  ').convert(selectedJson)}',
    );
    GlobalLogger.logInfo('EXPORT_PASSWORD $password');

    await _extractAndPrintPackage(selectedRows, password);
  }

  Future<void> _extractAndPrintPackage(
    List<KeyLoaderDetailsEntity> selectedRows,
    String password,
  ) async {
    try {
      final uploadPath = await DirectoryManager.instance.getUploadsPath();
      final zipPath = await _findLatestZip(uploadPath);
      if (zipPath == null) {
        SimplePopup.error(t.cpds.export.zipNotFound(path: uploadPath));
        GlobalLogger.logError('EXPORT_ZIP_NOT_FOUND in $uploadPath');
        return;
      }
      GlobalLogger.logInfo('EXPORT_ZIP $zipPath');

      final outPath = p.withoutExtension(zipPath);
      await extractFileToDisk(
        zipPath,
        outPath,
        password: AppConfig.zipPassword,
      );
      GlobalLogger.logInfo('EXPORT_EXTRACTED $outPath');

      final savePath = await DirectoryManager.instance.getZipCache();
      final resourceEntries = _resourceEntries(outPath);
      final tarPaths = <String>[];
      for (final row in selectedRows) {
        final tarPath = await _exportOneRow(
          row,
          outPath,
          savePath,
          resourceEntries,
        );
        if (tarPath != null) {
          tarPaths.add(tarPath);
        }
      }

      if (tarPaths.isNotEmpty) {
        final zipEntries = tarPaths
            .map((tarPath) => ArchiveEntry(sourcePath: tarPath, innerDir: ''))
            .toList();
        final curTime = parseDateTime(
          DateTime.now(),
        ).replaceAll(RegExp(r'[-:\s]'), '');
        final packagePath = await FileTools.filesToZipFormPath(
          entries: zipEntries,
          outputPath: savePath,
          zipName: 'UAE_$curTime',
          type: ArchiveEncoderType.zip,
        );
        GlobalLogger.logInfo('EXPORT_ZIP_PACKAGE $packagePath');

        await _encryptZipToPad(packagePath, password, curTime);

        for (final tarPath in tarPaths) {
          final tarFile = File(tarPath);
          try {
            if (await tarFile.exists()) {
              await tarFile.delete();
              GlobalLogger.logInfo('EXPORT_TAR_DELETED $tarPath');
            }
          } catch (e) {
            GlobalLogger.logWarn('EXPORT_TAR_DELETE_FAILED $tarPath $e');
          }
        }
      }
    } catch (e, stackTrace) {
      SimplePopup.error(t.cpds.export.failed(error: e.toString()));
      GlobalLogger.logError('EXPORT_FAILED $e\n$stackTrace');
    }
  }

  Future<String?> _encryptZipToPad(
    String zipPath,
    String password,
    String curTime,
  ) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      GlobalLogger.logError('EXPORT_ZIP_MISSING_FOR_PAD $zipPath');
      return null;
    }

    final zipBytes = await zipFile.readAsBytes();
    final encryptedBytes = await _encryptWithPassphrase(zipBytes, password);
    final padPath = p.join(p.dirname(zipPath), 'UAE_$curTime.pad');
    await File(padPath).writeAsBytes(encryptedBytes, flush: true);
    GlobalLogger.logInfo('EXPORT_PAD $padPath');
    return padPath;
  }

  Future<Uint8List> _encryptWithPassphrase(
    Uint8List data,
    String password,
  ) async {
    final chunks = await encryptWithPassphrase(
      Stream.value(data),
      passphraseProvider: _FixedPassphrase(password),
    ).toList();

    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<String?> _exportOneRow(
    KeyLoaderDetailsEntity row,
    String outPath,
    String savePath,
    List<ArchiveEntry> resourceEntries,
  ) async {
    final netNodeFilePath = p.join(
      outPath,
      '4_net_node',
      '${row.netNodePackageName}.json',
    );
    final dcFilePath = p.join(
      outPath,
      '3_device_config',
      '${row.dcPackageName}.json',
    );

    final entries = <ArchiveEntry>[...resourceEntries];

    final netNodeFile = File(netNodeFilePath);
    if (await netNodeFile.exists()) {
      final netNodeContent = await netNodeFile.readAsString();
      GlobalLogger.logInfo(
        'EXPORT_NET_NODE[${row.netNodePackageName}] $netNodeContent',
      );
      entries.add(
        ArchiveEntry(sourcePath: netNodeFilePath, innerDir: '4_net_node'),
      );
    } else {
      _notifyMissingFile(
        '${row.netNodePackageName} - ${row.dcPackageName} - '
        '4_net_node/${row.netNodePackageName}.json',
      );
    }

    final dcFile = File(dcFilePath);
    if (await dcFile.exists()) {
      final dcContent = await dcFile.readAsString();
      final dcJson = jsonDecode(dcContent);
      GlobalLogger.logInfo(
        'EXPORT_DEVICE_CONFIG[${row.dcPackageName}] '
        '${const JsonEncoder.withIndent('  ').convert(dcJson)}',
      );
      entries.add(
        ArchiveEntry(sourcePath: dcFilePath, innerDir: '3_device_config'),
      );

      final channels = dcJson['Channels'];
      if (channels is Map) {
        for (final value in channels.values) {
          if (value is! Map) continue;
          final subnet = value['Subnet'];
          if (subnet is! String || subnet.isEmpty) continue;

          final subnetFileName = '$subnet.json';
          final subnetFilePath = p.join(
            outPath,
            '2_radio_subnet',
            subnetFileName,
          );
          if (File(subnetFilePath).existsSync()) {
            entries.add(
              ArchiveEntry(
                sourcePath: subnetFilePath,
                innerDir: '2_radio_subnet',
              ),
            );
          } else {
            _notifyMissingFile(
              '${row.netNodePackageName} - ${row.dcPackageName} - '
              '2_radio_subnet/$subnetFileName',
            );
          }
        }
      }
    } else {
      _notifyMissingFile(
        '${row.netNodePackageName} - ${row.dcPackageName} - '
        '3_device_config/${row.dcPackageName}.json',
      );
    }

    if (entries.isEmpty) {
      GlobalLogger.logWarn('EXPORT_TAR_EMPTY for ${row.netNodePackageName}');
      return null;
    }

    final zipName = '${row.SN ?? ''}-${row.consumer ?? ''}';
    final tarPath = await FileTools.filesToZipFormPath(
      entries: entries,
      outputPath: savePath,
      zipName: zipName,
      type: ArchiveEncoderType.tar,
    );
    GlobalLogger.logInfo('EXPORT_TAR $tarPath');
    return tarPath;
  }

  List<ArchiveEntry> _resourceEntries(String outPath) {
    final resourceDir = Directory(p.join(outPath, '1_resource'));
    if (!resourceDir.existsSync()) return const [];

    final entries = <ArchiveEntry>[];
    for (final entity in resourceDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final relPath = p
          .relative(entity.path, from: outPath)
          .replaceAll('\\', '/');
      final slashIndex = relPath.lastIndexOf('/');
      final innerDir = slashIndex > 0 ? relPath.substring(0, slashIndex) : '';
      entries.add(ArchiveEntry(sourcePath: entity.path, innerDir: innerDir));
    }
    return entries;
  }

  void _notifyMissingFile(String missingPath) {
    SimplePopup.error(t.cpds.export.fileNotFound(path: missingPath));
    GlobalLogger.logWarn('EXPORT_FILE_MISSING $missingPath');
  }

  Future<String?> _findLatestZip(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return null;

    final zipFiles = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.zip')) {
        zipFiles.add(entity);
      }
    }
    if (zipFiles.isEmpty) return null;

    zipFiles.sort((a, b) {
      final timeCompare = b.statSync().modified.compareTo(
        a.statSync().modified,
      );
      if (timeCompare != 0) return timeCompare;
      return b.path.compareTo(a.path);
    });
    return zipFiles.first.path;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Spacer(),
              BaseButton(
                label: Translations.of(context).button.injectEncrypt.export,
                width: 70,
                onPressed: () => _exportSelected(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFF353A41)),
        Expanded(
          child: FutureBuilder<List<KeyLoaderDetailsEntity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                GlobalLogger.logError(
                  'load key loader details: ${snapshot.error}',
                );
                return _buildEmpty(context);
              }
              _allData = snapshot.data ?? [];
              return DataTablePlusThemeProvider(
                theme: _theme,
                child: DataTablePlus<KeyLoaderDetailsEntity>(
                  items: _pagedData,
                  idGetter: (item) => item.id.toString(),
                  selectedIds: _selectedIds,
                  allSelected: _allSelected,
                  showCheckboxes: true,
                  onSelectionChanged: _toggleSelection,
                  onSelectAllChanged: () => _toggleSelectAll(),
                  columns: _buildColumns(context),
                  emptyWidget: _buildEmpty(context),
                ),
              );
            },
          ),
        ),
        DataTablePlusThemeProvider(
          theme: _theme,
          child: TablePagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _allData.length,
            pageSize: _pageSize,
            pageSizeOptions: const [10, 20, 50, 100],
            onPageSizeChanged: (size) => setState(() {
              _pageSize = size;
              _currentPage = 1;
            }),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemRangeTemplate: '',
          ),
        ),
      ],
    );
  }

  List<ColumnDefinition<KeyLoaderDetailsEntity>> _buildColumns(
    BuildContext context,
  ) {
    final t = Translations.of(context);
    final radios = context.read<RadiosProvider>().radios;

    return [
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.parameterPacket,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.dcPackageName,
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.radio,
        size: const ColumnSize.fixed(160),
        cellBuilder: (item) {
          final usedRadioIds = _allData
              .where((other) => other.id != item.id && other.radioId != null)
              .map((other) => other.radioId!)
              .toSet();
          final radioOptions = radios
              .where(
                (radio) =>
                    !usedRadioIds.contains(radio.id) ||
                    radio.id == item.radioId,
              )
              .map(
                (radio) => DropdownMenuItem<int?>(
                  value: radio.id,
                  child: Text(radio.alias),
                ),
              )
              .toList();
          final hasCurrentRadio = radios.any(
            (radio) => radio.id == item.radioId,
          );
          return SimpleDropdown<int?>(
            hint: t.cpds.saveDialog.selectPlaceholder,
            value: hasCurrentRadio ? item.radioId : null,
            items: radioOptions,
            onChanged: (value) {
              if (item.radioId == value) return;
              item.radioId = value;
              final radio = radios.firstWhere((r) => r.id == value);
              item.consumer = radio.consumer;
              item.location = radio.location;
              item.SN = radio.sn;
              KeyLoadersApi.updateOneDetail(item.id, data: item.toJson());
              setState(() {});
            },
          );
        },
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.consumer,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.consumer ?? '',
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.location,
        flex: 2,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.location ?? '',
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.SN,
        flex: 1,
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.SN ?? '',
        ),
      ),
    ];
  }

  Widget _buildEmpty(BuildContext context) {
    final t = Translations.of(context);
    return Center(
      child: Text(
        t.common.noData,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}

class _FixedPassphrase extends PassphraseProvider {
  final String password;

  _FixedPassphrase(this.password);

  @override
  Future<String> passphrase() async => password;
}
