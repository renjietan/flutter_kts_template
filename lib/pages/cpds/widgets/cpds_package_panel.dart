import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';

class CpdsPackagePanel extends StatefulWidget {
  const CpdsPackagePanel({
    super.key,
    required this.state,
    required this.uploading,
    required this.parsing,
    required this.onBrowse,
    required this.onParse,
    required this.onSelectNode,
  });

  final CpdsApplicationState state;
  final bool uploading;
  final bool parsing;
  final VoidCallback onBrowse;
  final VoidCallback onParse;
  final ValueChanged<String> onSelectNode;

  @override
  State<CpdsPackagePanel> createState() => _CpdsPackagePanelState();
}

class _CpdsPackagePanelState extends State<CpdsPackagePanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final package = widget.state.package;
    final nodesById = {
      for (final node in package?.nodes ?? const <CpdsNode>[]) node.id: node,
    };
    final units = _filterUnits(package?.units ?? const [], _query, nodesById);

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
                  width: 96,
                  height: 32,
                  icon: HyIcons.wenjian,
                  isLoading: widget.uploading,
                  onPressed:
                      widget.state.active || widget.uploading
                      ? null
                      : widget.onBrowse,
                ),
                const SizedBox(width: 8),
                BaseButton(
                  label: t.cpds.parse,
                  width: 88,
                  height: 32,
                  isLoading: widget.parsing,
                  onPressed:
                      widget.state.upload == null ||
                          widget.state.active ||
                          widget.parsing
                      ? null
                      : widget.onParse,
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
                    height: 78,
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
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
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
                    child: units.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty
                                  ? t.cpds.nodesEmpty
                                  : t.common.noData,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView(
                            children: units
                                .expand(
                                  (unit) => _buildUnitRows(
                                    unit,
                                    nodesById,
                                    widget.state.selectedNodeId,
                                    0,
                                  ),
                                )
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

  List<CpdsUnit> _filterUnits(
    List<CpdsUnit> units,
    String query,
    Map<String, CpdsNode> nodesById,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<CpdsUnit>.from(units);

    CpdsUnit? filter(CpdsUnit unit) {
      final unitMatches = unit.name.toLowerCase().contains(normalized);
      final matchedNodeIds = unit.nodeIds
          .where(
            (id) =>
                (nodesById[id]?.name.toLowerCase().contains(normalized) ??
                    false),
          )
          .toList();
      final filteredChildren = unit.subUnits
          .map(filter)
          .whereType<CpdsUnit>()
          .toList();
      final matches =
          unitMatches || matchedNodeIds.isNotEmpty || filteredChildren.isNotEmpty;
      if (!matches) return null;
      return CpdsUnit(
        id: unit.id,
        name: unit.name,
        nodeIds: unitMatches ? unit.nodeIds : matchedNodeIds,
        subUnits: filteredChildren,
      );
    }

    return units.map(filter).whereType<CpdsUnit>().toList();
  }

  List<Widget> _buildUnitRows(
    CpdsUnit unit,
    Map<String, CpdsNode> nodesById,
    String selectedNodeId,
    int depth,
  ) {
    final rows = <Widget>[
      _TreeRow(
        depth: depth,
        icon: HyIcons.zhihuisuo,
        title: unit.name,
        selected: false,
        onTap: null,
      ),
    ];
    for (final nodeId in unit.nodeIds) {
      final node = nodesById[nodeId];
      rows.add(
        _TreeRow(
          depth: depth + 1,
          icon: switch (node?.nodeType) {
            1 => HyIcons.ren,
            2 => HyIcons.che,
            _ => HyIcons.zhihuisuo,
          },
          title: node?.name ?? nodeId,
          selected: selectedNodeId == nodeId,
          onTap: () => widget.onSelectNode(nodeId),
        ),
      );
    }
    for (final child in unit.subUnits) {
      rows.addAll(
        _buildUnitRows(child, nodesById, selectedNodeId, depth + 1),
      );
    }
    return rows;
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.depth,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final int depth;
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: EdgeInsets.only(left: 12.0 + depth * 24),
        color: selected ? const Color(0xFF004098) : Colors.transparent,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
