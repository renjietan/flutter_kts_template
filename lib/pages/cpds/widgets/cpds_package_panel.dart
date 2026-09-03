import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:flutter_kts_template/pages/cpds/cpds_package_tree.dart';

class CpdsPackagePanel extends StatefulWidget {
  const CpdsPackagePanel({
    super.key,
    required this.state,
    required this.uploading,
    required this.onBrowse,
    required this.onSelectNode,
    required this.onSelectFutureWarrior,
  });

  final CpdsApplicationState state;
  final bool uploading;
  final VoidCallback onBrowse;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String> onSelectFutureWarrior;

  @override
  State<CpdsPackagePanel> createState() => _CpdsPackagePanelState();
}

class _CpdsPackagePanelState extends State<CpdsPackagePanel> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedKeys = {};
  Set<String> _preSearchExpandedKeys = {};
  String _query = '';
  CpdsPackage? _lastPackage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpanded(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  List<CpdsTreeItem> _buildFullTree() {
    final package = widget.state.package;
    final nodesById = {
      for (final node in package?.nodes ?? const <CpdsNode>[]) node.id: node,
    };
    return buildCpdsPackageTree(
      package?.units ?? const [],
      nodesById,
      futureWarriorLabel: Translations.of(context).tree.futureWarrior,
    );
  }

  Set<String> _collectExpandableKeys(List<CpdsTreeItem> items) {
    final keys = <String>{};
    void walk(List<CpdsTreeItem> list) {
      for (final item in list) {
        if (item.children.isNotEmpty) {
          keys.add(item.key);
          walk(item.children);
        }
      }
    }

    walk(items);
    return keys;
  }

  void _applySearch(String value) {
    final wasSearching = _query.trim().isNotEmpty;
    final isSearching = value.trim().isNotEmpty;

    setState(() {
      _query = value;
      if (isSearching) {
        if (!wasSearching) {
          _preSearchExpandedKeys = Set.of(_expandedKeys);
        }
        final filtered = filterCpdsTree(_buildFullTree(), value);
        _expandedKeys.addAll(_collectExpandableKeys(filtered));
      } else if (wasSearching) {
        _expandedKeys
          ..clear()
          ..addAll(_preSearchExpandedKeys);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final searching = _query.trim().isNotEmpty;

    final fullTree = _buildFullTree();

    // 包变化时，重置为默认全部展开。
    if (widget.state.package != _lastPackage) {
      _lastPackage = widget.state.package;
      _expandedKeys
        ..clear()
        ..addAll(_collectExpandableKeys(fullTree));
    }

    final tree = searching ? filterCpdsTree(fullTree, _query) : fullTree;
    final rows = flattenCpdsTree(tree, _expandedKeys);

    return Container(
      color: const Color(0xFF0E1114),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 32,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.cpds.fileTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xFF282D33),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.state.upload?.fileName ?? t.cpds.filePlaceholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.state.upload == null
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BaseButton(
                  label: t.cpds.browse,
                  width: 100,
                  height: 32,
                  icon: HyIcons.wenjian,
                  isLoading: widget.uploading,
                  onPressed: widget.state.active || widget.uploading
                      ? null
                      : widget.onBrowse,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171C22),
                border: Border.all(color: const Color(0x26FFFFFF)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF353A41)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t.cpds.nodesTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          if (defaultTargetPlatform ==
                              TargetPlatform.android) {
                            // Android：输入时不搜索，仅在清空时恢复。
                            if (value.trim().isEmpty) {
                              _applySearch(value);
                            }
                          } else {
                            _applySearch(value);
                          }
                        },
                        onSubmitted: (value) {
                          if (defaultTargetPlatform ==
                              TargetPlatform.android) {
                            _applySearch(value);
                          }
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: t.TextField.search,
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF282D33),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: Color(0xFF353A41),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: Color(0xFF353A41),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: Color(0xFF00A2E9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(
                            child: Text(
                              searching
                                  ? t.common.noData
                                  : t.cpds.nodesEmpty,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView(
                            children: rows
                                .map((row) => _buildRow(row))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(CpdsVisibleRow row) {
    final item = row.item;
    final isNode = item.kind == CpdsTreeItemKind.node;
    final isFutureWarrior = item.kind == CpdsTreeItemKind.futureWarrior;
    final selected = isNode
        ? widget.state.selectedNodeId == item.nodeId
        : isFutureWarrior
        ? widget.state.selectedFutureWarriorUnitId == item.unitId
        : false;
    final VoidCallback? onTap = isNode
        ? () => widget.onSelectNode(item.nodeId!)
        : isFutureWarrior
        ? () => widget.onSelectFutureWarrior(item.unitId!)
        : item.isLeaf
        ? null
        : () => _toggleExpanded(item.key);

    return _CpdsTreeRow(
      item: item,
      selected: selected,
      expanded: row.expanded,
      onTap: onTap,
    );
  }
}

class _CpdsTreeRow extends StatelessWidget {
  const _CpdsTreeRow({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final CpdsTreeItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelectable = item.kind == CpdsTreeItemKind.node ||
        item.kind == CpdsTreeItemKind.futureWarrior;

    if (isSelectable) {
      // 可选中变色的节点：只变色，不显示水波纹。
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: EdgeInsets.only(left: 12.0 + item.depth * 24),
          color: selected ? const Color(0xFF004098) : Colors.transparent,
          child: _buildRowBody(),
        ),
      );
    }

    // unit：点击显示水波纹。
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: EdgeInsets.only(left: 12.0 + item.depth * 24),
          child: _buildRowBody(),
        ),
      ),
    );
  }

  Widget _buildRowBody() {
    final hasChildren = !item.isLeaf;
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: hasChildren
              ? Icon(
                  expanded
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  size: 18,
                  color: Colors.white70,
                )
              : null,
        ),
        _buildIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    if (item.kind == CpdsTreeItemKind.futureWarrior) {
      return SizedBox(
        width: 22,
        height: 16,
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              child: Icon(
                HyIcons.ren,
                size: 16,
                color: Colors.white70,
              ),
            ),
            Positioned(
              left: 6,
              top: 0,
              child: Icon(
                HyIcons.ren,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    final IconData icon = switch (item.kind) {
      CpdsTreeItemKind.unit => HyIcons.zhihuisuo,
      CpdsTreeItemKind.node => switch (item.nodeType) {
        1 => HyIcons.ren,
        2 => HyIcons.che,
        _ => HyIcons.zhihuisuo,
      },
      CpdsTreeItemKind.futureWarrior => HyIcons.ren,
    };
    return Icon(icon, size: 16, color: Colors.white70);
  }
}
