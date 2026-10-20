import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../theme/table.theme.dart';

class RadioManagerPager extends StatefulWidget {
  final DataTablePlusTheme theme;
  final ThemePreset themePreset;

  const RadioManagerPager({
    super.key,
    required this.theme,
    required this.themePreset,
  });

  @override
  State<RadioManagerPager> createState() => _RadioManagerPagerState();
}

class _RadioManagerPagerState extends State<RadioManagerPager>
    with AutomaticKeepAliveClientMixin, RadioManagerMixin {
  @override
  bool get wantKeepAlive => true;

  AppLocale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = TranslationProvider.of(context).locale;
    if (_lastLocale != null && _lastLocale != locale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SmartDialog.dismiss();
        aliasTextEditController.clear();
        locationTextEditController.clear();
        snTextEditController.clear();
      });
    }
    _lastLocale = locale;
  }

  DataTablePlusTheme get _transparentTableTheme => DataTablePlusTheme(
    backgroundColor: Colors.transparent,
    headerBackgroundColor: Colors.transparent,
    borderColor: const Color(0xFF353A41),
    borderLightColor: const Color(0xFF282D33),
    textPrimaryColor: widget.theme.textPrimaryColor,
    textSecondaryColor: widget.theme.textSecondaryColor,
    textMutedColor: widget.theme.textMutedColor,
    accentColor: widget.theme.accentColor,
    accentLightColor: widget.theme.accentLightColor,
    successColor: widget.theme.successColor,
    successLightColor: widget.theme.successLightColor,
    warningColor: widget.theme.warningColor,
    warningLightColor: widget.theme.warningLightColor,
    dangerColor: widget.theme.dangerColor,
    dangerLightColor: widget.theme.dangerLightColor,
    cellPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0),
    headerPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0),
    cellTextStyle: widget.theme.cellTextStyle,
    headerTextStyle: widget.theme.headerTextStyle,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        // color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // TableContextualBar
          DataTablePlusThemeProvider(
            theme: widget.theme,
            child: TableContextualBar(
              selectedCount: selectedIds.length,
              normalToolbar: buildToolbar(context),
              selectedCountTemplate: '{count} ${t.checkbox.selected}',
              selectAllWidget: OutlinedButton(
                onPressed: toggleSelectAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.theme.accentColor,
                  side: BorderSide(
                    color: widget.theme.accentColor.withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  minimumSize: Size(0, 36.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  allSelected
                      ? t.checkbox.DeselectAll
                      : t.checkbox.SelectAll(count: data.length),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: clearSelection,
                  icon: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: widget.theme.textSecondaryColor,
                  ),
                  label: Text(
                    t.button.radioManager.clear,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: widget.theme.textSecondaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 36.h),
                    side: BorderSide(color: widget.theme.borderColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                FilledButton.icon(
                  onPressed: () {
                    patchDelete();
                  },
                  icon: Icon(Icons.delete_outline, size: 16.sp),
                  label: Text(
                    '${t.button.radioManager.delete} (${selectedIds.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    minimumSize: Size(0, 36.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1.h, thickness: 1, color: Color(0xFF353A41)),
          Expanded(
            child: SingleChildScrollView(
              child: DataTablePlusThemeProvider(
                theme: _transparentTableTheme,
                child: DataTablePlus<RadiosEntity>(
                  items: data,
                  idGetter: (item) => item.id.toString(),
                  selectedIds: selectedIds,
                  allSelected: allSelected,
                  showCheckboxes: showCheckboxes,
                  onSelectionChanged: toggleSelection,
                  onSelectAllChanged: toggleSelectAll,
                  columns: buildColumns(context),
                  // 设置未null时,不显示操作列
                  actionBuilder: buildActionCell,
                  actionLabel: t.tableColumn.base.actions,
                  emptyWidget: buildEmptyWidget(context),
                  // 在列头下方显示[字段描述]
                  // showColumnInfo: showColumnInfo,
                  // 显示字段描述, showColumnInfo 设置为 false 时,此处无效
                  // onToggleColumnInfo: () =>
                  //     setState(() => showColumnInfo = !showColumnInfo),
                ),
              ),
            ),
          ),
          // 分页
          DataTablePlusThemeProvider(
            theme: _transparentTableTheme,
            child: TablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              pageSize: pageSize,
              pageSizeOptions: const [10, 20, 50, 100],
              // pageSizeTemplate: "{count}",
              onPageSizeChanged: (size) => setState(() {
                pageSize = size;
                currentPage = 1;
                SimplePopup.loading();
                getList();
              }),
              onPageChanged: (page) {
                setState(() => currentPage = page);
                SimplePopup.loading();
                getList();
              },
              // itemRangeTemplate: 'Showing {start}-{end} of {total} data',
              itemRangeTemplate: "",
            ),
          ),
        ],
      ),
    );
  }
}
