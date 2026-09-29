import 'package:flutter/material.dart';
import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter_kts_template/components/TextField/simple.filter.search.textField.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_network_interface_bar.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/edit_package_dialog.dart';
import 'package:flutter_kts_template/theme/app_colors.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

/// 自更新安装包上传页面。
///
/// 页面 = 搜索框 + 【文件上传】按钮 + 安装包表格 + 分页。
/// 表格列：版本号 / 文件名称 / 备注 / 创建时间 / 操作。
///
/// 上传、删除、更新等具体动作通过回调交由上层处理，本页只负责展示与交互。
class SelfUpdatePage extends StatefulWidget {
  const SelfUpdatePage({
    super.key,
    required this.repository,
    required this.interfaces,
    required this.selectedInterfaceName,
    required this.automaticInterface,
    required this.interfacesLoading,
    this.onRefreshInterfaces,
    this.onSelectInterface,
    this.onUpload,
    this.onDelete,
    this.onUpdate,
    this.onEdit,
  });

  final InstallPackageRepository repository;
  final List<CpdsNetworkInterface> interfaces;
  final String selectedInterfaceName;
  final bool automaticInterface;
  final bool interfacesLoading;
  final VoidCallback? onRefreshInterfaces;
  final ValueChanged<String?>? onSelectInterface;
  final VoidCallback? onUpload;
  final void Function(InstallPackageEntity entity)? onDelete;
  final void Function(InstallPackageEntity entity)? onUpdate;
  final void Function(
    InstallPackageEntity entity,
    String version,
    String? remark,
  )?
  onEdit;

  @override
  State<SelfUpdatePage> createState() => _SelfUpdatePageState();
}

class _SelfUpdatePageState extends State<SelfUpdatePage> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  List<InstallPackageEntity> _all = const [];
  List<InstallPackageEntity> _filtered = const [];
  String _keyword = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _all = widget.repository.getAll();
      _applyFilter();
    });
  }

  void _applyFilter() {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      _filtered = List.of(_all);
    } else {
      _filtered = _all.where((entity) {
        return entity.version.toLowerCase().contains(keyword) ||
            entity.fileName.toLowerCase().contains(keyword) ||
            (entity.remark?.toLowerCase().contains(keyword) ?? false);
      }).toList();
    }
    _page = 0;
  }

  int get _pageCount {
    if (_filtered.isEmpty) {
      return 0;
    }
    return (_filtered.length + _pageSize - 1) ~/ _pageSize;
  }

  List<InstallPackageEntity> get _pageItems {
    if (_filtered.isEmpty) {
      return const [];
    }
    final start = _page * _pageSize;
    final end = (start + _pageSize) > _filtered.length
        ? _filtered.length
        : start + _pageSize;
    return _filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DataTablePlusThemeProvider(
                theme: getThemePreset(ThemePreset.dark),
                child: SimpleFilterSearchField(
                  height: 36,
                  controller: _searchController,
                  onChanged: (value) {
                    _keyword = value;
                    setState(_applyFilter);
                  },
                  onClear: () {
                    setState(() {
                      _keyword = '';
                      _searchController.text = '';
                      _applyFilter();
                    });
                  },
                  onSubmit: (value) {
                    setState(_applyFilter);
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                child: CpdsNetworkInterfaceBar(
                  interfaces: widget.interfaces,
                  selectedName: widget.selectedInterfaceName,
                  automatic: widget.automaticInterface,
                  loading: widget.interfacesLoading,
                  disabled: widget.interfacesLoading,
                  showLabel: false,
                  onSelected: widget.onSelectInterface ?? (_) {},
                ),
              ),
              const SizedBox(width: 8),
              BaseButton(
                label: Translations.of(context).cpds.refresh,
                minWidth: 72,
                height: 32,
                isLoading: widget.interfacesLoading,
                onPressed: widget.interfacesLoading
                    ? null
                    : widget.onRefreshInterfaces,
              ),
              const SizedBox(width: 8),
              BaseButton(
                label: '文件上传',
                minWidth: 110,
                onPressed: widget.onUpload,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildTable()),
          const SizedBox(height: 8),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final items = _pageItems;
    if (items.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 900.0;
        const columnSpacing = 24.0;
        const horizontalMargin = 24.0;
        const versionWidth = 96.0;
        const timeWidth = 180.0;
        const actionWidth = 160.0;
        const fixedColumnsWidth = versionWidth + timeWidth + actionWidth;
        const gapsWidth = columnSpacing * 4;
        const marginsWidth = horizontalMargin * 2;
        final flexibleTotal =
            maxWidth - fixedColumnsWidth - gapsWidth - marginsWidth;
        final flexible = flexibleTotal / 2;
        final fileNameWidth = flexible < 120 ? 120.0 : flexible;
        final remarkWidth = flexible < 100 ? 100.0 : flexible;

        return Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF353A41), width: 1)),
          ),
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: columnSpacing,
              columns: const [
                DataColumn(label: Text('版本号')),
                DataColumn(label: Text('文件名称')),
                DataColumn(label: Text('备注')),
                DataColumn(label: Text('创建时间')),
                DataColumn(label: Text('操作')),
              ],
              rows: [
                for (final entity in items)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: versionWidth,
                          child: Text(entity.version),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: fileNameWidth,
                          child: Text(
                            entity.fileName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: remarkWidth,
                          child: Text(
                            entity.remark ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: timeWidth,
                          child: Text(_formatTime(entity.createdAt)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: actionWidth,
                          child: _buildRowActions(entity),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRowActions(InstallPackageEntity entity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onEdit == null
              ? null
              : () => _showEditDialog(entity),
          icon: const Icon(Icons.edit, color: AppColors.primary),
          tooltip: '编辑',
        ),
        IconButton(
          onPressed: widget.onUpdate == null
              ? null
              : () => widget.onUpdate!(entity),
          icon: const Icon(Icons.system_update, color: Color(0xFF00A2E9)),
          tooltip: '更新到设备',
        ),
        IconButton(
          onPressed: widget.onDelete == null
              ? null
              : () => _confirmDelete(entity),
          icon: const Icon(Icons.delete_outline, color: Color(0xFFF15B64)),
          tooltip: '删除',
        ),
      ],
    );
  }

  Future<void> _showEditDialog(InstallPackageEntity entity) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return EditPackageDialog(
          entity: entity,
          onConfirm: (version, remark) {
            Navigator.of(dialogContext).pop();
            widget.onEdit?.call(entity, version, remark);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(InstallPackageEntity entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除提示'),
          content: Text('确认删除【${entity.version}】吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      widget.onDelete?.call(entity);
    }
  }

  Widget _buildPagination() {
    if (_pageCount == 0) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('第 ${_page + 1} / $_pageCount 页 · 共 ${_filtered.length} 条'),
        IconButton(
          onPressed: _page > 0 ? () => setState(() => _page--) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: _page < _pageCount - 1
              ? () => setState(() => _page++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
