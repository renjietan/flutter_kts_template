import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_messages.dart';

Future<RadiosEntity?> showCpdsRadioSidePanel({
  required BuildContext context,
  required List<RadiosEntity> radios,
  RadiosEntity? selected,
}) {
  return showGeneralDialog<RadiosEntity?>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'radio-picker',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CpdsRadioSidePanel(
        animation: animation,
        radios: radios,
        selected: selected,
      );
    },
  );
}

class CpdsRadioSidePanel extends StatefulWidget {
  const CpdsRadioSidePanel({
    super.key,
    required this.animation,
    required this.radios,
    this.selected,
  });

  final Animation<double> animation;
  final List<RadiosEntity> radios;
  final RadiosEntity? selected;

  @override
  State<CpdsRadioSidePanel> createState() => _CpdsRadioSidePanelState();
}

class _CpdsRadioSidePanelState extends State<CpdsRadioSidePanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RadiosEntity> get _filtered {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return widget.radios;
    return widget.radios.where((radio) {
      return radio.alias.toLowerCase().contains(keyword) ||
          radio.sn.toLowerCase().contains(keyword);
    }).toList();
  }

  void _pop([RadiosEntity? result]) {
    if (mounted) Navigator.of(context).pop(result);
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final searchHint = CpdsMessages.tr(
      context,
      '搜索别名 / SN',
      'Search alias / SN',
      'بحث الاسم المستعار / SN',
    );
    final noAvailable = CpdsMessages.tr(
      context,
      '无可用电台',
      'No available radio',
      'لا يوجد جهاز راديو متاح',
    );
    final noResult = CpdsMessages.tr(
      context,
      '无搜索结果',
      'No search results',
      'لا توجد نتائج بحث',
    );

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: widget.animation,
            child: GestureDetector(
              onTap: () => _pop(),
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: widget.animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: SizedBox(
              width: 400,
              height: double.infinity,
              child: Material(
                color: const Color(0xFF20262D),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF353A41)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.tableColumn.injectEncrypt.radio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _pop(),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.white54,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                ),
                          hintText: searchHint,
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B2026),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF353A41),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF353A41),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.radios.isEmpty
                          ? _buildEmpty(noAvailable)
                          : _filtered.isEmpty
                          ? _buildEmpty(noResult)
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final radio = _filtered[index];
                                final isSelected =
                                    widget.selected?.id == radio.id;
                                return ListTile(
                                  dense: true,
                                  onTap: () => _pop(radio),
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF1E3A5F),
                                  title: Text(
                                    radio.alias,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'SN: ${radio.sn}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF8A94A6),
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CpdsRadioPickerField extends StatelessWidget {
  const CpdsRadioPickerField({
    super.key,
    required this.selected,
    required this.hint,
    required this.onTap,
    this.onClear,
    this.height = 32,
  });

  final RadiosEntity? selected;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasValue = selected != null;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF282D33),
        border: Border.all(color: const Color(0xFF353A41)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hasValue ? selected!.alias : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue ? Colors.white : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          if (hasValue && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 16, color: Colors.white54),
              ),
            ),
          GestureDetector(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
