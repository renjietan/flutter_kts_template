import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

class CpdsStatusBadge extends StatelessWidget {
  const CpdsStatusBadge({super.key, required this.status});

  final CpdsDeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final text = switch (status) {
      CpdsDeviceStatus.pending => t.cpds.statuses.pending,
      CpdsDeviceStatus.discovered => t.cpds.statuses.discovered,
      CpdsDeviceStatus.authenticated => t.cpds.statuses.authenticated,
      CpdsDeviceStatus.receiving => t.cpds.statuses.receiving,
      CpdsDeviceStatus.waitingParse => t.cpds.statuses.waitingParse,
      CpdsDeviceStatus.completed => t.cpds.statuses.completed,
      CpdsDeviceStatus.failed => t.cpds.statuses.failed,
      CpdsDeviceStatus.ignored => t.cpds.statuses.ignored,
    };
    final Color color;
    switch (status) {
      case CpdsDeviceStatus.discovered:
      case CpdsDeviceStatus.authenticated:
        color = const Color(0xFF0CB5FF);
        break;
      case CpdsDeviceStatus.receiving:
        color = const Color(0xFFF0A43A);
        break;
      case CpdsDeviceStatus.completed:
        color = const Color(0xFF2FC88F);
        break;
      case CpdsDeviceStatus.failed:
        color = const Color(0xFFF15B64);
        break;
      default:
        color = const Color(0xFFB7BCC6);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
