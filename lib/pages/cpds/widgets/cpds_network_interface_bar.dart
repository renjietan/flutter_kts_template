// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CpdsNetworkInterfaceBar extends StatelessWidget {
  const CpdsNetworkInterfaceBar({
    super.key,
    required this.interfaces,
    required this.selectedName,
    required this.automatic,
    required this.loading,
    required this.disabled,
    required this.onSelected,
    this.showLabel = true,
  });

  final List<CpdsNetworkInterface> interfaces;
  final String selectedName;
  final bool automatic;
  final bool loading;
  final bool disabled;
  final ValueChanged<String?> onSelected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      height: 36.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          if (showLabel) ...[
            Text(
              t.cpds.networkInterfaceLabel,
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedName.isEmpty ? null : selectedName,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF282D33),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 2.h,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: const BorderSide(color: Color(0xFF00A2E9)),
                ),
                hintText: t.cpds.networkInterfacePlaceholder,
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13.sp),
              ),
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(t.cpds.networkInterfacePlaceholder),
                ),
                ...interfaces.map(
                  (item) => DropdownMenuItem<String>(
                    value: item.name,
                    enabled: item.linkUp,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.cpds.networkInterfaceOption(
                              name: item.name,
                              ip: item.ipv4,
                              type: item.wired
                                  ? t.cpds.networkInterfaceWired
                                  : t.cpds.networkInterfaceWireless,
                            ),
                          ),
                        ),
                        if (!item.linkUp) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.wifi_off,
                            size: 14.w,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            t.cpds.networkInterfaceNoLink,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: disabled || loading ? null : onSelected,
            ),
          ),
          if (automatic && selectedName.isNotEmpty) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0x2400A2E9),
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                t.cpds.automatic,
                style: TextStyle(
                  color: const Color(0xFF0CB5FF),
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
