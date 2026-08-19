import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

class CpdsNetworkInterfaceBar extends StatelessWidget {
  const CpdsNetworkInterfaceBar({
    super.key,
    required this.interfaces,
    required this.selectedName,
    required this.automatic,
    required this.loading,
    required this.disabled,
    required this.canDistribute,
    required this.onSelected,
    required this.onRefresh,
    required this.onDistribute,
  });

  final List<CpdsNetworkInterface> interfaces;
  final String selectedName;
  final bool automatic;
  final bool loading;
  final bool disabled;
  final bool canDistribute;
  final ValueChanged<String?> onSelected;
  final VoidCallback onRefresh;
  final VoidCallback onDistribute;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            t.cpds.networkInterfaceLabel,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedName.isEmpty ? null : selectedName,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF282D33),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0x33FFFFFF),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF00A2E9)),
                ),
                hintText: t.cpds.networkInterfacePlaceholder,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(t.cpds.networkInterfacePlaceholder),
                ),
                ...interfaces.map(
                  (item) => DropdownMenuItem<String>(
                    value: item.name,
                    child: Text(
                      t.cpds.networkInterfaceOption(
                        name: item.name,
                        ip: item.ipv4,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: disabled || loading ? null : onSelected,
            ),
          ),
          if (automatic && selectedName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x2400A2E9),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                t.cpds.automatic,
                style: const TextStyle(
                  color: Color(0xFF0CB5FF),
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          BaseButton(
            label: t.cpds.refresh,
            width: 72,
            height: 32,
            isLoading: loading,
            onPressed: disabled || loading ? null : onRefresh,
          ),
          const SizedBox(width: 8),
          BaseButton(
            label: t.cpds.distribute,
            width: 88,
            height: 32,
            onPressed:
                disabled || loading || selectedName.isEmpty || !canDistribute
                ? null
                : onDistribute,
          ),
        ],
      ),
    );
  }
}
