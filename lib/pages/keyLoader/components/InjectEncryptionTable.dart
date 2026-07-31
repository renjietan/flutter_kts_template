import 'dart:io';

import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../theme/table.theme.dart';

class InjectEncryptionTable extends StatefulWidget {
  final ThemePreset? themePreset;
  final KeyLoadersEntity? keyLoaderEntity;
  const InjectEncryptionTable({
    super.key,
    this.themePreset = ThemePreset.dark,
    this.keyLoaderEntity,
  });

  @override
  State<InjectEncryptionTable> createState() => _InjectEncryptionTableState();
}

class _InjectEncryptionTableState extends State<InjectEncryptionTable> {
  late final DataTablePlusTheme theme;
  int currentPage = 1;
  int pageSize = 10;
  String? searchQuery = "";
  List<KeyLoaderDetailsEntity>? allData;

  List<RadiosEntity> radios = [];

  List<DropdownMenuItem> get radioOptions => radios.fold([], (cur, pre) {
    DropdownMenuItem temp = DropdownMenuItem(
      value: pre.id,
      child: Text(pre.alias),
    );
    cur.add(temp);
    return cur;
  });

  bool get isDark => widget.themePreset == ThemePreset.dark;
  String rootFilePath = "";
  String get rFilePath => p.join(rootFilePath, "1_resource");
  String get rsFilePath => p.join(rootFilePath, "2_radio_subnet");
  String get dcFilePath => p.join(rootFilePath, "3_device_config");
  String get nnFilePath => p.join(rootFilePath, "4_net_node");

  final Set<String> selectedIds = {};
  List<KeyLoaderDetailsEntity> get paginatedData {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= filteredData.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredData.length / pageSize).ceil().clamp(1, 999);

  List<KeyLoaderDetailsEntity> get filteredData => allData ?? [];
  @override
  void initState() {
    super.initState();
    theme = widget.themePreset == null
        ? getThemePreset(ThemePreset.dark)
        : getThemePreset(widget.themePreset!);
  }

  Future<List<KeyLoaderDetailsEntity>> getDetails(
    KeyLoadersEntity? entity,
  ) async {
    String defaultUploadPath = await DirectoryManager.instance.getUploadsPath();
    List<Directory> subFolders = await FileTools.getDirectSubFolders(
      defaultUploadPath,
    );
    rootFilePath = subFolders.first.path;

    if (entity?.id != null) {
      return await KeyLoadersApi.getDetails(entity!.id).then((res) {
        final listData = res.data["list"] as List;
        return listData.map((item) {
          return KeyLoaderDetailsEntity.fromJson(item as Map<String, dynamic>);
        }).toList();
      });
    }
    return [];
  }

  Future<void> updateOneDetail(
    int id, {
    required Map<String, dynamic> detail,
  }) async {
    KeyLoadersApi.updateOneDetail(id, data: detail).then((res) {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              TextTitle(text: t.pager.injectEncrypt.paramPairing),
              const Spacer(),
              // 导出
              BaseButton(
                label: t.button.injectEncrypt.export,
                onPressed: () {
                  buildTar();
                },
                width: 70,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: FutureBuilder<List<KeyLoaderDetailsEntity>>(
              future: getDetails(widget.keyLoaderEntity),
              builder: (context, snapshot) {
                allData = [];
                final p = context.read<RadiosProvider>();
                radios = p.radios;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return buildEmptyWidget(context);
                } else if (snapshot.hasData) {
                  allData = snapshot.data;
                  return DataTablePlusThemeProvider(
                    theme: theme,
                    child: DataTablePlus<KeyLoaderDetailsEntity>(
                      items: paginatedData,
                      idGetter: (item) => item.id.toString(),
                      selectedIds: selectedIds,
                      allSelected: allSelected,
                      showCheckboxes: true,
                      onSelectionChanged: toggleSelection,
                      onSelectAllChanged: toggleSelectAll,
                      columns: buildColumns(context),
                      emptyWidget: buildEmptyWidget(context),
                    ),
                  );
                } else {
                  return buildEmptyWidget(context);
                }
              },
            ),
          ),
        ),
        DataTablePlusThemeProvider(
          theme: theme,
          child: TablePagination(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: filteredData.length,
            pageSize: pageSize,
            pageSizeOptions: const [10, 20, 50, 100],
            onPageSizeChanged: (size) => setState(() {
              pageSize = size;
              currentPage = 1;
            }),
            onPageChanged: (page) => setState(() => currentPage = page),
            // pageSizeTemplate: "{size}",
            // itemRangeTemplate: 'Showing {start}-{end} of {total} data',
            itemRangeTemplate: "",
          ),
        ),
      ],
    );
  }

  Future<void> buildTar() async {
    String savePath = await DirectoryManager.instance.getZipCache();
    List<KeyLoaderDetailsEntity>? entities = allData
        ?.where((item) => selectedIds.contains("${item.id}"))
        .toList();
    // 根据 3_device_config 中的 Channels 字段 获取 Subnets 列表，后续 将 根据 Subnets 字段 查找 2_radio_subnet 问价
    List<String> dcJsonFilesPath = (entities ?? []).fold<List<String>>([], (
      cur,
      pre,
    ) {
      cur.add(p.join(dcFilePath, "${pre.dcPackageName}.json"));
      return cur;
    });
    List<ArchiveEntry> dcJsonArchiveEntries = dcJsonFilesPath.fold([], (
      cur,
      pre,
    ) {
      cur.add(ArchiveEntry(sourcePath: pre, innerDir: "3_device_config"));
      return cur;
    });
    List<String> nnJsonFilesPath = (entities ?? [])
        .fold<Map<String, dynamic>>({}, (cur, pre) {
          String keys = p.join(nnFilePath, "${pre.netNodePackageName}.json");
          cur[keys] = keys;
          return cur;
        })
        .keys
        .toList();
    List<ArchiveEntry> nnJsonArchiveEntries = nnJsonFilesPath.fold([], (
      cur,
      pre,
    ) {
      cur.add(ArchiveEntry(sourcePath: pre, innerDir: "4_net_node"));
      return cur;
    });

    List<String> resourceFileNames = await FileTools.getJsonFileNameByFPath(
      rFilePath,
    );
    List<ArchiveEntry> resourceEntries = resourceFileNames
        .fold<List<ArchiveEntry>>([], (cur, pre) {
          ArchiveEntry temp = ArchiveEntry(
            sourcePath: p.join(rFilePath, pre),
            innerDir: "1_resource",
          );
          cur.add(temp);
          return cur;
        });
    List<String> dcChannelsValues = [];
    for (var dcJsonFilePath in dcJsonFilesPath) {
      Map<String, dynamic> dcContent = FileTools.readFileContentAsMap(
        dcJsonFilePath,
      );
      Map<String, dynamic>? dcChannels = dcContent["Channels"] ?? {};
      List<String> dcv = (dcChannels?.values.toList() ?? []).fold<List<String>>(
        [],
        (cur, pre) {
          String subnet = pre["Subnet"] ?? '';
          if (subnet.isNotEmpty) {
            cur.add("$subnet.json");
          }
          return cur;
        },
      ).toList();
      dcChannelsValues = [...dcChannelsValues, ...dcv];
    }

    List<ArchiveEntry> entries = dcChannelsValues.fold<List<ArchiveEntry>>(
      [...resourceEntries, ...dcJsonArchiveEntries, ...nnJsonArchiveEntries],
      (cur, pre) {
        String sourcePath = p.join(rootFilePath, "2_radio_subnet", pre);
        ArchiveEntry temp = ArchiveEntry(
          sourcePath: sourcePath,
          innerDir: "2_radio_subnet",
        );
        cur.add(temp);
        return cur;
      },
    );

    // // 汇总 4_net_node + 3_device_config + 2_radio_subnet + 1_resource
    String serviceTarPath = await FileTools.filesToZipFormPath(
      entries: entries,
      outputPath: savePath,
      zipName: "radios",
    );
    GlobalLogger.logInfo("保存路径: $serviceTarPath");
  }

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

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id.toString())) {
        selectedIds.remove(id.toString());
      } else {
        selectedIds.add(id.toString());
      }
    });
  }

  bool get allSelected {
    final current = paginatedData;
    if (current.isEmpty) return false;
    return current.every((u) => selectedIds.contains(u.id.toString()));
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

  List<ColumnDefinition<KeyLoaderDetailsEntity>> buildColumns(
    BuildContext context,
  ) {
    final t = Translations.of(context);
    return [
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.parameterPacket,
        size: const ColumnSize.fixed(150),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (u) => u.netNodePackageName,
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.radio,
        flex: 2,
        cellBuilder: (item) => SimpleDropdown(
          hint: t.tableColumn.injectEncrypt.radio,
          value: item.radioId,
          items: radioOptions,
          onChanged: (v) {
            if (item.radioId == v) return;
            item.radioId = v;
            RadiosEntity radio = radios.firstWhere((item) => item.id == v);
            item.location = radio.location;
            item.SN = radio.sn;
            item.consumer = radio.consumer;
            Map<String, dynamic> params = item.toJson();
            updateOneDetail(item.id, detail: params);
            setState(() {});
          },
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.consumer,
        size: const ColumnSize.fixed(200),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.consumer ?? "",
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.location,
        size: const ColumnSize.fixed(200),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.location ?? "",
        ),
      ),
      ColumnDefinition<KeyLoaderDetailsEntity>(
        label: t.tableColumn.injectEncrypt.SN,
        size: const ColumnSize.fixed(200),
        cellBuilder: TextCellBuilder.text<KeyLoaderDetailsEntity>(
          (item) => item.SN ?? "",
        ),
      ),
    ];
  }
}
