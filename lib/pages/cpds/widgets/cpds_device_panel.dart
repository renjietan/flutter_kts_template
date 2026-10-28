// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_messages.dart';
import 'package:flutter_kts_template/utils/arabic_digits.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/table.theme.dart';
import 'cpds_network_interface_bar.dart';
import 'cpds_progress_bar.dart';
import 'cpds_status_badge.dart';

class CpdsDevicePanel extends StatelessWidget {
  const CpdsDevicePanel({
    super.key,
    required this.state,
    required this.interfaces,
    required this.selectedInterfaceName,
    required this.automaticInterface,
    required this.interfacesLoading,
    required this.canDistribute,
    required this.distributing,
    required this.onRefreshInterfaces,
    required this.onSelectInterface,
    required this.onDistribute,
    required this.onDistributeFutureWarrior,
    this.onSaveFutureWarrior,
    this.onEditVeciInfo,
  });

  final CpdsApplicationState state;
  final List<CpdsNetworkInterface> interfaces;
  final String selectedInterfaceName;
  final bool automaticInterface;
  final bool interfacesLoading;
  final bool canDistribute;
  final bool distributing;
  final VoidCallback onRefreshInterfaces;
  final ValueChanged<String?> onSelectInterface;
  final VoidCallback onDistribute;
  final Future<void> Function(CpdsFutureWarriorDevice device)
  onDistributeFutureWarrior;
  final Future<void> Function(List<CpdsFutureWarriorDevice>, String unitId)?
  onSaveFutureWarrior;
  final ValueChanged<String>? onEditVeciInfo;

  static List<CpdsFutureWarriorDevice> _aggregateFutureWarriorDevices(
    CpdsPackage? package,
    String unitId,
  ) {
    if (package == null) return const [];
    final unit = _findUnit(package.units, unitId);
    if (unit == null) return const [];
    final nodesById = {for (final node in package.nodes) node.id: node};
    final result = <CpdsFutureWarriorDevice>[];
    for (final nodeId in unit.nodeIds) {
      final node = nodesById[nodeId];
      if (node == null || node.nodeType != 1 || node.hasTeds) {
        continue;
      }
      for (final device in node.devices) {
        result.add(
          CpdsFutureWarriorDevice(
            device: device,
            nodeId: nodeId,
            nodeName: node.name,
          ),
        );
      }
    }
    return result;
  }

  static String _findUnitIdForNode(List<CpdsUnit> units, String nodeId) {
    String? found;
    void walk(List<CpdsUnit> list) {
      for (final unit in list) {
        if (unit.nodeIds.contains(nodeId)) {
          found = unit.id;
          return;
        }
        walk(unit.subUnits);
      }
    }

    walk(units);
    return found ?? '';
  }

  static CpdsUnit? _findUnit(List<CpdsUnit> units, String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
      final found = _findUnit(unit.subUnits, unitId);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    CpdsNode? selectedNode;
    for (final node in state.package?.nodes ?? const <CpdsNode>[]) {
      if (node.id == state.selectedNodeId) {
        selectedNode = node;
        break;
      }
    }

    if (state.selectedFutureWarriorUnitId.isNotEmpty) {
      return CpdsFutureWarriorPanel(
        devices: _aggregateFutureWarriorDevices(
          state.package,
          state.selectedFutureWarriorUnitId,
        ),
        unitId: state.selectedFutureWarriorUnitId,
        state: state,
        interfaces: interfaces,
        selectedInterfaceName: selectedInterfaceName,
        automaticInterface: automaticInterface,
        interfacesLoading: interfacesLoading,
        onRefreshInterfaces: onRefreshInterfaces,
        onSelectInterface: onSelectInterface,
        onDistributeFutureWarrior: onDistributeFutureWarrior,
        onSave: onSaveFutureWarrior,
      );
    }

    if (selectedNode?.nodeType == 1 && !(selectedNode?.hasTeds ?? false)) {
      final node = selectedNode!;
      return CpdsFutureWarriorPanel(
        devices: node.devices
            .map(
              (device) => CpdsFutureWarriorDevice(
                device: device,
                nodeId: node.id,
                nodeName: node.name,
              ),
            )
            .toList(),
        unitId: _findUnitIdForNode(state.package?.units ?? const [], node.id),
        state: state,
        interfaces: interfaces,
        selectedInterfaceName: selectedInterfaceName,
        automaticInterface: automaticInterface,
        interfacesLoading: interfacesLoading,
        onRefreshInterfaces: onRefreshInterfaces,
        onSelectInterface: onSelectInterface,
        onDistributeFutureWarrior: onDistributeFutureWarrior,
        onSave: onSaveFutureWarrior,
      );
    }
    final deviceRows = _buildDeviceRows(selectedNode, state.session);
    final groups = _groupDevices(deviceRows);
    final showAlias =
        selectedNode?.nodeType == 2 ||
        (selectedNode?.nodeType == 1 && (selectedNode?.hasTeds ?? false));
    final stageIndex = _stageIndex(state.session);
    final transferring =
        state.session?.activeState == CpdsActiveState.transferring ||
        state.session?.activeState == CpdsActiveState.drainingAfterFailure;

    return Container(
      color: const Color(0xFF0E1114),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48.h,
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 24.h,
                  color: const Color(0xFF00A2E9),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedNode?.name ?? t.cpds.currentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (selectedNode != null)
                        Text(
                          t.cpds.online(
                            online: deviceRows
                                .where(
                                  (row) =>
                                      row.status != CpdsDeviceStatus.pending,
                                )
                                .length,
                            expected: deviceRows.length,
                          ),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Color(0xFFB7BCC6),
                          ),
                        ),
                    ],
                  ),
                ),
                BaseButton(
                  label: t.cpds.refresh,
                  minWidth: 72.w,
                  height: 36.h,
                  isLoading: interfacesLoading,
                  onPressed: state.active || interfacesLoading
                      ? null
                      : onRefreshInterfaces,
                ),
                SizedBox(width: 8.w),
                BaseButton(
                  label: t.cpds.distribute,
                  minWidth: 88.w,
                  height: 36.h,
                  isLoading: distributing,
                  onPressed: distributing || state.active || interfacesLoading
                      ? null
                      : onDistribute,
                ),
              ],
            ),
          ),
          CpdsNetworkInterfaceBar(
            interfaces: interfaces,
            selectedName: selectedInterfaceName,
            automatic: automaticInterface,
            loading: interfacesLoading,
            disabled: state.active,
            onSelected: onSelectInterface,
          ),
          _StageStrip(activeIndex: stageIndex),
          if (transferring) ...[
            Container(
              height: 64.h,
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0x24004098),
                border: Border.all(color: const Color(0x7300A2E9)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.cpds.stages.transfer,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Text(
                        '${state.session?.sentChunks ?? 0}/${state.session?.totalChunks ?? 0}',
                        style: TextStyle(
                          color: Color(0xFFB7BCC6),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7.h),
                  CpdsProgressBar(value: state.session?.sendingProgress ?? 0),
                ],
              ),
            ),
          ],
          // if (selectedNode?.nodeType == 2 && selectedNode?.veciInfo != null)
          //   _VeciInfoBox(
          //     veciInfo: selectedNode!.veciInfo!,
          //     onEdit: onEditVeciInfo == null
          //         ? null
          //         : () => onEditVeciInfo!(selectedNode!.id),
          //   ),
          SizedBox(height: 8.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171C22),
                border: Border.all(color: const Color(0x26FFFFFF)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: selectedNode == null
                  ? Center(
                      child: Text(
                        t.cpds.noSelection,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  : _CpdsDeviceGroupList(
                      key: ValueKey(selectedNode.id),
                      groups: groups,
                      groupTitle: (key) => _groupTitle(context, key),
                      showAlias: showAlias,
                      selectedLeftNode: selectedNode,
                      onVecInfoEdit: onEditVeciInfo,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DeviceRowData> _buildDeviceRows(
    CpdsNode? selectedNode,
    CpdsSessionView? session,
  ) {
    if (selectedNode == null) return const [];
    final byKey = {
      for (final item in session?.devices ?? const <CpdsDeviceStatusView>[])
        item.device.key: item,
    };
    final hideTeds = selectedNode.nodeType == 2;
    return selectedNode.devices
        .where((device) => !hideTeds || device.type != CpdsDeviceType.teds)
        .map((device) {
          final status = byKey[device.key];
          return _DeviceRowData(
            device: device,
            status: status?.status ?? CpdsDeviceStatus.pending,
            esnSuffix: status?.esnSuffix ?? '',
            currentIp: status?.currentIp ?? '',
            progress: status?.progress ?? 0,
            errorCode: status?.errorCode ?? CpdsErrorCode.unspecified,
          );
        })
        .toList();
  }

  int _stageIndex(CpdsSessionView? session) {
    if (session == null) return -1;
    if ((session.activeState == CpdsActiveState.failed ||
            session.activeState == CpdsActiveState.partialSuccess) &&
        !session.devices.any(
          (item) => item.status == CpdsDeviceStatus.completed,
        )) {
      return session.lastStageIndex;
    }
    return switch (session.activeState) {
      CpdsActiveState.discovering ||
      CpdsActiveState.awaitingDiscoveryConfirmation => 0,
      CpdsActiveState.authenticating => 1,
      CpdsActiveState.transferring || CpdsActiveState.drainingAfterFailure => 2,
      CpdsActiveState.waitingParse => 3,
      CpdsActiveState.completed ||
      CpdsActiveState.partialSuccess ||
      CpdsActiveState.failed => 4,
      CpdsActiveState.idle => -1,
    };
  }

  List<_DeviceGroupData> _groupDevices(List<_DeviceRowData> rows) {
    const order = [
      CpdsDeviceType.multiBandRadio,
      CpdsDeviceType.multiBandHandheld,
      CpdsDeviceType.hf,
      CpdsDeviceType.smallHandheld,
      CpdsDeviceType.ccu,
      CpdsDeviceType.vehInter,
      CpdsDeviceType.teds,
      CpdsDeviceType.iec,
    ];
    final groups = <CpdsDeviceType, List<_DeviceRowData>>{};
    for (final row in rows) {
      final key = row.device.type == CpdsDeviceType.ccuAudio
          ? CpdsDeviceType.ccu
          : row.device.type;
      groups.putIfAbsent(key, () => []).add(row);
    }
    final result =
        groups.entries.map((entry) {
          final titleKey = entry.key == CpdsDeviceType.ccu
              ? 'ccuGroup'
              : _deviceTypeKey(entry.key);
          return _DeviceGroupData(titleKey: titleKey, rows: entry.value);
        }).toList()..sort(
          (a, b) =>
              order.indexOf(_typeFromKey(a.titleKey)) -
              order.indexOf(_typeFromKey(b.titleKey)),
        );
    return result;
  }

  String _groupTitle(BuildContext context, String key) {
    final t = Translations.of(context);
    return switch (key) {
      'teds' => t.cpds.deviceTypes.teds,
      'hf' => t.cpds.deviceTypes.hf,
      'multiBandRadio' => t.cpds.deviceTypes.multiBandRadio,
      'multiBandHandheld' => t.cpds.deviceTypes.multiBandHandheld,
      'ccuGroup' => t.cpds.deviceTypes.ccuGroup,
      'vehInter' => t.cpds.deviceTypes.vehInter,
      'iec' => t.cpds.deviceTypes.iec,
      'smallHandheld' => t.cpds.deviceTypes.smallHandheld,
      _ => t.cpds.deviceTypes.unknown,
    };
  }

  String _deviceTypeKey(CpdsDeviceType type) => switch (type) {
    CpdsDeviceType.teds => 'teds',
    CpdsDeviceType.hf => 'hf',
    CpdsDeviceType.multiBandRadio => 'multiBandRadio',
    CpdsDeviceType.multiBandHandheld => 'multiBandHandheld',
    CpdsDeviceType.ccu => 'ccuGroup',
    CpdsDeviceType.vehInter => 'vehInter',
    CpdsDeviceType.iec => 'iec',
    CpdsDeviceType.smallHandheld => 'smallHandheld',
    CpdsDeviceType.ccuAudio => 'ccuGroup',
    CpdsDeviceType.unspecified => 'unknown',
  };

  CpdsDeviceType _typeFromKey(String key) => switch (key) {
    'teds' => CpdsDeviceType.teds,
    'hf' => CpdsDeviceType.hf,
    'multiBandRadio' => CpdsDeviceType.multiBandRadio,
    'multiBandHandheld' => CpdsDeviceType.multiBandHandheld,
    'ccuGroup' => CpdsDeviceType.ccu,
    'vehInter' => CpdsDeviceType.vehInter,
    'iec' => CpdsDeviceType.iec,
    'smallHandheld' => CpdsDeviceType.smallHandheld,
    _ => CpdsDeviceType.unspecified,
  };
}

class _StageStrip extends StatelessWidget {
  const _StageStrip({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final labels = [
      t.cpds.stages.discovery,
      t.cpds.stages.authentication,
      t.cpds.stages.transfer,
      t.cpds.stages.parse,
      t.cpds.stages.complete,
    ];
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14191F),
        border: Border.all(color: const Color(0xFF353A41)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            _StageStep(
              index: index,
              label: labels[index],
              active: index == activeIndex,
              passed: index < activeIndex,
            ),
            if (index != labels.length - 1)
              _StageLine(passed: index < activeIndex),
          ],
        ],
      ),
    );
  }
}

class CpdsFutureWarriorPanel extends StatefulWidget {
  const CpdsFutureWarriorPanel({
    super.key,
    required this.devices,
    required this.unitId,
    required this.state,
    required this.interfaces,
    required this.selectedInterfaceName,
    required this.automaticInterface,
    required this.interfacesLoading,
    required this.onRefreshInterfaces,
    required this.onSelectInterface,
    required this.onDistributeFutureWarrior,
    this.onSave,
  });

  final List<CpdsFutureWarriorDevice> devices;
  final String unitId;
  final CpdsApplicationState state;
  final List<CpdsNetworkInterface> interfaces;
  final String selectedInterfaceName;
  final bool automaticInterface;
  final bool interfacesLoading;
  final VoidCallback onRefreshInterfaces;
  final ValueChanged<String?> onSelectInterface;
  final Future<void> Function(CpdsFutureWarriorDevice device)
  onDistributeFutureWarrior;
  final Future<void> Function(List<CpdsFutureWarriorDevice>, String unitId)?
  onSave;

  @override
  State<CpdsFutureWarriorPanel> createState() => _CpdsFutureWarriorPanelState();
}

class _CpdsFutureWarriorPanelState extends State<CpdsFutureWarriorPanel> {
  final Set<String> _selectedKeys = {};
  final Set<CpdsDeviceType> _collapsedGroups = {};
  bool _saving = false;

  @override
  void didUpdateWidget(covariant CpdsFutureWarriorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unitId != widget.unitId) {
      _selectedKeys.clear();
      _collapsedGroups.clear();
    }
  }

  void _toggleGroup(CpdsDeviceType type) {
    setState(() {
      if (_collapsedGroups.contains(type)) {
        _collapsedGroups.remove(type);
      } else {
        _collapsedGroups.add(type);
      }
    });
  }

  List<CpdsFutureWarriorDevice> get _selectedDevices => widget.devices
      .where((device) => _selectedKeys.contains(device.key))
      .toList();

  Future<void> _handleSave() async {
    if (_selectedKeys.isEmpty) {
      SimplePopup.warn(
        CpdsMessages.tr(context, '请勾选', 'Please select', 'يرجى الاختيار'),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave?.call(_selectedDevices, widget.unitId);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<(CpdsDeviceType, List<CpdsFutureWarriorDevice>)> _groupedDevices() {
    const order = [
      CpdsDeviceType.multiBandRadio,
      CpdsDeviceType.multiBandHandheld,
      CpdsDeviceType.hf,
      CpdsDeviceType.smallHandheld,
      CpdsDeviceType.ccu,
      CpdsDeviceType.vehInter,
      CpdsDeviceType.teds,
      CpdsDeviceType.iec,
    ];
    final groups = <CpdsDeviceType, List<CpdsFutureWarriorDevice>>{};
    for (final fwDevice in widget.devices) {
      final device = fwDevice.device;
      final key = device.type == CpdsDeviceType.ccuAudio
          ? CpdsDeviceType.ccu
          : device.type;
      groups.putIfAbsent(key, () => []).add(fwDevice);
    }
    final result =
        groups.entries.map((entry) => (entry.key, entry.value)).toList()
          ..sort((a, b) => order.indexOf(a.$1) - order.indexOf(b.$1));
    return result;
  }

  bool get _allSelected =>
      widget.devices.isNotEmpty &&
      _selectedKeys.length == widget.devices.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(widget.devices.map((device) => device.key));
      }
    });
  }

  void _clearSelection() {
    setState(_selectedKeys.clear);
  }

  String _groupTitle(BuildContext context, CpdsDeviceType type) {
    final t = Translations.of(context);
    return switch (type) {
      CpdsDeviceType.teds => t.cpds.deviceTypes.teds,
      CpdsDeviceType.hf => t.cpds.deviceTypes.hf,
      CpdsDeviceType.multiBandRadio => t.cpds.deviceTypes.multiBandRadio,
      CpdsDeviceType.multiBandHandheld => t.cpds.deviceTypes.multiBandHandheld,
      CpdsDeviceType.ccu => t.cpds.deviceTypes.ccuGroup,
      CpdsDeviceType.vehInter => t.cpds.deviceTypes.vehInter,
      CpdsDeviceType.iec => t.cpds.deviceTypes.iec,
      CpdsDeviceType.smallHandheld => t.cpds.deviceTypes.smallHandheld,
      CpdsDeviceType.unspecified => t.cpds.deviceTypes.unknown,
      CpdsDeviceType.ccuAudio => t.cpds.deviceTypes.ccuGroup,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final total = widget.devices.length;
    final selectedCount = _selectedKeys.length;
    final groups = _groupedDevices();
    final tableTheme = getThemePreset(ThemePreset.dark);
    final session = widget.state.session;
    final statusByKey = {
      for (final item in session?.devices ?? const <CpdsDeviceStatusView>[])
        item.device.key: item,
    };
    final stageIndex = _stageIndexOf(session);
    final transferring =
        session?.activeState == CpdsActiveState.transferring ||
        session?.activeState == CpdsActiveState.drainingAfterFailure;
    final saveButton = BaseButton(
      label: t.button.radioManager.save,
      minWidth: 80.w,
      height: 36.h,
      isLoading: _saving,
      onPressed: _saving ? null : _handleSave,
      colors: const [
        Color(0xFFE6A23C),
        Color(0xFFE6A23C),
        Color(0xFFE6A23C),
        Color(0xFFE6A23C),
      ],
    );
    final normalToolbar = SizedBox(
      height: 48.h,
      child: Row(
        children: [
          Container(width: 4.w, height: 36.h, color: const Color(0xFF00A2E9)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tree.futureWarrior,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  CpdsMessages.digits(
                    context,
                    CpdsMessages.tr(
                      context,
                      '已勾选 $selectedCount/$total',
                      'Selected $selectedCount/$total',
                      'تم تحديد $selectedCount/$total',
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFFB7BCC6),
                  ),
                ),
              ],
            ),
          ),
          BaseButton(
            label: t.cpds.refresh,
            minWidth: 72.w,
            height: 36.h,
            isLoading: widget.interfacesLoading,
            onPressed: widget.state.active || widget.interfacesLoading
                ? null
                : widget.onRefreshInterfaces,
          ),
          SizedBox(width: 8.w),
          saveButton,
        ],
      ),
    );

    return Container(
      color: const Color(0xFF0E1114),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTablePlusThemeProvider(
            theme: tableTheme,
            child: TableContextualBar(
              selectedCount: selectedCount,
              normalToolbar: normalToolbar,
              selectedCountTemplate: '{count} ${t.checkbox.selected}',
              selectAllWidget: OutlinedButton(
                onPressed: _toggleSelectAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tableTheme.accentColor,
                  side: BorderSide(
                    color: tableTheme.accentColor.withValues(alpha: 0.4),
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
                  _allSelected
                      ? t.checkbox.DeselectAll
                      : t.checkbox.SelectAll(count: total),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: _clearSelection,
                  icon: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: tableTheme.textSecondaryColor,
                  ),
                  label: Text(
                    t.button.radioManager.clear,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: tableTheme.textSecondaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 36.h),
                    side: BorderSide(color: tableTheme.borderColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                saveButton,
              ],
            ),
          ),
          CpdsNetworkInterfaceBar(
            interfaces: widget.interfaces,
            selectedName: widget.selectedInterfaceName,
            automatic: widget.automaticInterface,
            loading: widget.interfacesLoading,
            disabled: widget.state.active,
            onSelected: widget.onSelectInterface,
          ),
          _StageStrip(activeIndex: stageIndex),
          if (transferring) ...[
            Container(
              height: 64.h,
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0x24004098),
                border: Border.all(color: const Color(0x7300A2E9)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.cpds.stages.transfer,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Text(
                        '${session?.sentChunks ?? 0}/${session?.totalChunks ?? 0}',
                        style: TextStyle(
                          color: const Color(0xFFB7BCC6),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7.h),
                  CpdsProgressBar(value: session?.sendingProgress ?? 0),
                ],
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171C22),
                border: Border.all(color: const Color(0x26FFFFFF)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: total == 0
                  ? Center(
                      child: Text(
                        t.cpds.nodesEmpty,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  : ListView(
                      children: groups.expand((group) {
                        final expanded = !_collapsedGroups.contains(group.$1);
                        return [
                          _DeviceGroupHeader(
                            title: _groupTitle(context, group.$1),
                            count: group.$2.length,
                            expanded: expanded,
                            onTap: () => _toggleGroup(group.$1),
                          ),
                          if (expanded)
                            ...group.$2.map((fwDevice) {
                              final selected = _selectedKeys.contains(
                                fwDevice.key,
                              );
                              final statusView =
                                  statusByKey[fwDevice.device.key];
                              return _FutureWarriorDeviceRow(
                                fwDevice: fwDevice,
                                selected: selected,
                                status:
                                    statusView?.status ??
                                    CpdsDeviceStatus.pending,
                                esnSuffix: statusView?.esnSuffix ?? '',
                                currentIp: statusView?.currentIp ?? '',
                                progress: statusView?.progress ?? 0,
                                errorCode:
                                    statusView?.errorCode ??
                                    CpdsErrorCode.unspecified,
                                onDistribute: () {
                                  if (!widget.state.active &&
                                      !widget.interfacesLoading) {
                                    widget.onDistributeFutureWarrior(fwDevice);
                                  }
                                },
                                distributeDisabled:
                                    widget.state.active ||
                                    widget.interfacesLoading,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked) {
                                      _selectedKeys.add(fwDevice.key);
                                    } else {
                                      _selectedKeys.remove(fwDevice.key);
                                    }
                                  });
                                },
                              );
                            }),
                        ];
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  int _stageIndexOf(CpdsSessionView? session) {
    if (session == null) return -1;
    if ((session.activeState == CpdsActiveState.failed ||
            session.activeState == CpdsActiveState.partialSuccess) &&
        !session.devices.any(
          (item) => item.status == CpdsDeviceStatus.completed,
        )) {
      return session.lastStageIndex;
    }
    return switch (session.activeState) {
      CpdsActiveState.discovering ||
      CpdsActiveState.awaitingDiscoveryConfirmation => 0,
      CpdsActiveState.authenticating => 1,
      CpdsActiveState.transferring || CpdsActiveState.drainingAfterFailure => 2,
      CpdsActiveState.waitingParse => 3,
      CpdsActiveState.completed ||
      CpdsActiveState.partialSuccess ||
      CpdsActiveState.failed => 4,
      CpdsActiveState.idle => -1,
    };
  }
}

class _FutureWarriorDeviceRow extends StatelessWidget {
  const _FutureWarriorDeviceRow({
    required this.fwDevice,
    required this.selected,
    required this.status,
    required this.esnSuffix,
    required this.currentIp,
    required this.progress,
    required this.errorCode,
    required this.onDistribute,
    required this.distributeDisabled,
    required this.onChanged,
  });

  final CpdsFutureWarriorDevice fwDevice;
  final bool selected;
  final CpdsDeviceStatus status;
  final String esnSuffix;
  final String currentIp;
  final int progress;
  final CpdsErrorCode errorCode;
  final VoidCallback? onDistribute;
  final bool distributeDisabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final device = fwDevice.device;
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF353A41))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48.w,
                  height: 48.h,
                  child: Checkbox(
                    value: selected,
                    activeColor: const Color(0xFF00A2E9),
                    onChanged: (value) => onChanged(value ?? false),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    device.alias,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
                SizedBox(width: 24.w),
                Text(
                  device.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                SizedBox(width: 12.w),
                CpdsStatusBadge(status: status),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 56.w),
                Expanded(
                  child: Text(
                    '${CpdsMessages.tr(context, '网络节点ID', 'Net Node ID', 'معرف عقدة الشبكة')}: ${fwDevice.nodeId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                SizedBox(width: 56.w),
                Expanded(
                  child: Text(
                    '${CpdsMessages.tr(context, '网络节点名称', 'Net Node Name', 'اسم عقدة الشبكة')}: '
                    '${fwDevice.nodeName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                SizedBox(width: 56.w),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${t.cpds.device.esn}: ${esnSuffix.isEmpty ? '--' : esnSuffix}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${t.cpds.device.ip}: ${currentIp.isEmpty ? '--' : currentIp}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            _distributionIpRow(context, device),
            if (status == CpdsDeviceStatus.receiving) ...[
              SizedBox(height: 8.h),
              CpdsProgressBar(value: progress),
            ],
            if (status == CpdsDeviceStatus.failed) ...[
              SizedBox(height: 6.h),
              Text(
                errorCode.apiName,
                style: TextStyle(
                  color: const Color(0xFFF15B64),
                  fontSize: 11.sp,
                ),
              ),
            ],
            if (onDistribute != null) ...[
              SizedBox(height: 6.h),
              Align(
                alignment: Alignment.centerRight,
                child: BaseButton(
                  label: t.cpds.distribute,
                  minWidth: 76.w,
                  height: 30.h,
                  onPressed: distributeDisabled ? null : onDistribute,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _distributionIpRow(BuildContext context, CpdsDevice device) {
    if (device.type == CpdsDeviceType.ccu) {
      return Row(
        children: [
          SizedBox(width: 56.w),
          Expanded(
            flex: 1,
            child: Text(
              '${CpdsMessages.tr(context, '下发IP(down1)', 'Distribute IP(down1)', 'عنوان IP التوزيع(down1)')}: '
              '${device.distributionIp1.isEmpty ? '--' : device.distributionIp1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 1,
            child: Text(
              '${CpdsMessages.tr(context, '下发IP(down2)', 'Distribute IP(down2)', 'عنوان IP التوزيع(down2)')}: '
              '${device.distributionIp2.isEmpty ? '--' : device.distributionIp2}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
          ),
        ],
      );
    }
    final label = device.type == CpdsDeviceType.teds
        ? CpdsMessages.tr(
            context,
            '子网IP',
            'Subnet IP',
            'عنوان IP للشبكة الفرعية',
          )
        : CpdsMessages.tr(
            context,
            '下发IP(down)',
            'Distribute IP(down)',
            'عنوان IP التوزيع(down)',
          );
    return Row(
      children: [
        SizedBox(width: 56.w),
        Expanded(
          child: Text(
            '$label: ${device.distributionIp1.isEmpty ? '--' : device.distributionIp1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}

class _StageStep extends StatelessWidget {
  const _StageStep({
    required this.index,
    required this.label,
    required this.active,
    required this.passed,
  });

  final int index;
  final String label;
  final bool active;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final circleBorder = active || passed
        ? const Color(0xFF00A2E9)
        : const Color(0xFF42474E);
    final circleFill = active ? const Color(0xFF004098) : Colors.transparent;
    final numberColor = active
        ? Colors.white
        : passed
        ? const Color(0xFF0CB5FF)
        : const Color(0xFF8A94A6);
    final textColor = active
        ? Colors.white
        : passed
        ? const Color(0xFF0CB5FF)
        : const Color(0xFF8A94A6);

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleFill,
              border: Border.all(color: circleBorder),
            ),
            child: Text(
              localizeDigits(context, '${index + 1}'),
              style: TextStyle(fontSize: 11.sp, color: numberColor),
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 1.h,
      color: passed ? const Color(0xFF0CB5FF) : const Color(0xFF42474E),
    );
  }
}

class _DeviceGroupHeader extends StatelessWidget {
  const _DeviceGroupHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF242A31),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.arrow_drop_down
                    : (Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_left
                          : Icons.arrow_right),
                size: 16.w,
                color: Colors.white70,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB7BCC6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CpdsDeviceGroupList extends StatefulWidget {
  const _CpdsDeviceGroupList({
    super.key,
    required this.groups,
    required this.groupTitle,
    required this.showAlias,
    required this.selectedLeftNode,
    this.onVecInfoEdit,
  });

  final List<_DeviceGroupData> groups;
  final String Function(String titleKey) groupTitle;
  final bool showAlias;
  final CpdsNode selectedLeftNode;
  final ValueChanged<String>? onVecInfoEdit;

  @override
  State<_CpdsDeviceGroupList> createState() => _CpdsDeviceGroupListState();
}

class _CpdsDeviceGroupListState extends State<_CpdsDeviceGroupList> {
  final Set<String> _collapsedGroups = {};

  void _toggleGroup(String key) {
    setState(() {
      if (_collapsedGroups.contains(key)) {
        _collapsedGroups.remove(key);
      } else {
        _collapsedGroups.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (widget.selectedLeftNode.nodeType == 2 &&
            widget.selectedLeftNode.veciInfo != null)
          _VecInfoBox(
            veciInfo: widget.selectedLeftNode.veciInfo!,
            onEdit: widget.onVecInfoEdit == null
                ? null
                : () => widget.onVecInfoEdit!(widget.selectedLeftNode.id),
            // expanded: false,
          ),
        ...widget.groups.expand((group) {
          final expanded = !_collapsedGroups.contains(group.titleKey);
          return [
            _DeviceGroupHeader(
              title: widget.groupTitle(group.titleKey),
              count: group.rows.length,
              expanded: expanded,
              onTap: () => _toggleGroup(group.titleKey),
            ),
            if (expanded)
              ...group.rows.map(
                (row) => _DeviceRow(row: row, showAlias: widget.showAlias),
              ),
          ];
        }).toList(),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.row, required this.showAlias});

  final _DeviceRowData row;
  final bool showAlias;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final name = _deviceDisplayName(context, row.device);
    final nodeIdLabel = CpdsMessages.tr(
      context,
      '节点ID',
      'Node ID',
      'معرف العقدة',
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF353A41))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16.w,
                color: Colors.white70,
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
              CpdsStatusBadge(status: row.status),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              SizedBox(width: 16.w),
              _Meta(label: nodeIdLabel, value: row.device.id),
              if (showAlias) ...[
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    '${CpdsMessages.tr(context, '别名', 'Alias', 'الاسم المستعار')}: '
                    '${row.device.alias.isEmpty ? '--' : row.device.alias}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              SizedBox(width: 16.w),
              _Meta(label: t.cpds.device.esn, value: row.esnSuffix),
              SizedBox(width: 16.w),
              _Meta(label: t.cpds.device.ip, value: row.currentIp),
            ],
          ),
          SizedBox(height: 4.h),
          _distributionIpRow(context, row),
          if (row.status == CpdsDeviceStatus.receiving) ...[
            SizedBox(height: 8.h),
            CpdsProgressBar(value: row.progress),
          ],
          if (row.status == CpdsDeviceStatus.failed) ...[
            SizedBox(height: 6.h),
            Text(
              row.errorCode.apiName,
              style: TextStyle(color: Color(0xFFF15B64), fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }

  String _deviceDisplayName(BuildContext context, CpdsDevice device) {
    final t = Translations.of(context);
    final typeKey = switch (device.type) {
      CpdsDeviceType.teds => t.cpds.deviceTypes.teds,
      CpdsDeviceType.hf => t.cpds.deviceTypes.hf,
      CpdsDeviceType.multiBandRadio => t.cpds.deviceTypes.multiBandRadio,
      CpdsDeviceType.multiBandHandheld => t.cpds.deviceTypes.multiBandHandheld,
      CpdsDeviceType.ccu => t.cpds.deviceTypes.ccu,
      CpdsDeviceType.ccuAudio => t.cpds.deviceTypes.ccuAudio,
      CpdsDeviceType.vehInter => t.cpds.deviceTypes.vehInter,
      CpdsDeviceType.iec => t.cpds.deviceTypes.iec,
      CpdsDeviceType.smallHandheld => t.cpds.deviceTypes.smallHandheld,
      CpdsDeviceType.unspecified => t.cpds.deviceTypes.unknown,
    };
    if (device.type == CpdsDeviceType.ccu ||
        device.type == CpdsDeviceType.ccuAudio) {
      return typeKey;
    }
    return device.model.isNotEmpty ? device.model : typeKey;
  }

  Widget _distributionIpRow(BuildContext context, _DeviceRowData row) {
    final t = Translations.of(context);
    final device = row.device;
    if (device.type == CpdsDeviceType.ccu) {
      return Row(
        children: [
          SizedBox(width: 16.w),
          Expanded(
            flex: 1,
            child: _DistributionIpCell(
              label: t.cpds.device.downCurrentIp1,
              value: device.distributionIp1,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 1,
            child: _DistributionIpCell(
              label: t.cpds.device.downCurrentIp2,
              value: device.distributionIp2,
            ),
          ),
        ],
      );
    }
    final label = device.type == CpdsDeviceType.teds
        ? t.cpds.device.subnetIp
        : t.cpds.device.downCurrentIp;
    return Row(
      children: [
        SizedBox(width: 16.w),
        _Meta(label: label, value: device.distributionIp1),
      ],
    );
  }
}

class _VecInfoBox extends StatefulWidget {
  final CpdsVeciInfo veciInfo;
  final VoidCallback? onEdit;

  const _VecInfoBox({super.key, required this.veciInfo, required this.onEdit});

  @override
  State<_VecInfoBox> createState() => _VecInfoBoxState();
}

class _VecInfoBoxState extends State<_VecInfoBox> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final title = CpdsMessages.tr(
      context,
      '车辆信息',
      'Vehicle Information',
      'معلومات المركبة',
    );
    final editLabel = CpdsMessages.tr(context, '编辑', 'Edit', 'تحرير');
    final equipNameLabel = CpdsMessages.tr(
      context,
      '装备名称',
      'Equipment Name',
      'اسم المعدات',
    );
    final ipLabel = CpdsMessages.tr(context, 'IP地址', 'IP Address', 'عنوان IP');
    final plateNoLabel = CpdsMessages.tr(
      context,
      '车牌号',
      'Plate No.',
      'رقم اللوحة',
    );
    final vehicleParamsLabel = CpdsMessages.tr(
      context,
      '车辆基础参数',
      'Vehicle Parameters',
      'معايير المركبة',
    );
    final purposeLabel = CpdsMessages.tr(context, '用途', 'Purpose', 'الغرض');
    final remarkLabel = CpdsMessages.tr(context, '备注', 'Remark', 'ملاحظات');
    return Container(
      margin: EdgeInsets.only(top: 0, bottom: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF171C22),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 5.h, 17.w, 0),
            child: SizedBox(
              width: double.infinity,
              height: 28.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Positioned(
                  //   left: 16.w,
                  //   top: 0,
                  //   bottom: 0,
                  //   child: Center(
                  //     child: GestureDetector(
                  //       onTap: widget.onEdit,
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Icon(
                  //             Icons.edit_outlined,
                  //             size: 15.w,
                  //             color: Color(0xFF00A2E9),
                  //           ),
                  //           SizedBox(width: 4.w),
                  //           Text(
                  //             editLabel,
                  //             style: TextStyle(
                  //               color: Color(0xFF00A2E9),
                  //               fontSize: 12.sp,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Color(0xFF00A2E9),
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.edit_outlined,
                          size: 15.w,
                          color: Color(0xFF00A2E9),
                        ),
                      ],
                    ),
                  ),
                  // Text(
                  //   title,
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 14.sp,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            expanded = !expanded;
                          });
                        },
                        child: AnimatedRotation(
                          turns: expanded ? 0.5 : 0.0, // 0.5 圈 = 180°
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Icon(Icons.keyboard_arrow_down, size: 20.sp),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: expanded
                  ? [
                      Row(
                        children: [
                          SizedBox(width: 16.w),
                          _Meta(
                            label: equipNameLabel,
                            value: widget.veciInfo.equipName,
                          ),
                          SizedBox(width: 16.w),
                          _Meta(label: ipLabel, value: widget.veciInfo.ip),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          SizedBox(width: 16.w),
                          _Meta(
                            label: plateNoLabel,
                            value: widget.veciInfo.plateNo,
                          ),
                          SizedBox(width: 16.w),
                          _Meta(
                            label: vehicleParamsLabel,
                            value: widget.veciInfo.vehicleParams,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          SizedBox(width: 16.w),
                          _Meta(
                            label: purposeLabel,
                            value: widget.veciInfo.purpose,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          SizedBox(width: 16.w),
                          _Meta(
                            label: remarkLabel,
                            value: widget.veciInfo.remark,
                          ),
                        ],
                      ),
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        '$label: ${value.isEmpty ? '--' : value}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white54, fontSize: 12.sp),
      ),
    );
  }
}

class _DistributionIpCell extends StatelessWidget {
  const _DistributionIpCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${value.isEmpty ? '--' : value}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.white54, fontSize: 12.sp),
    );
  }
}

class _DeviceRowData {
  const _DeviceRowData({
    required this.device,
    required this.status,
    this.esnSuffix = '',
    this.currentIp = '',
    this.progress = 0,
    this.errorCode = CpdsErrorCode.unspecified,
  });

  final CpdsDevice device;
  final CpdsDeviceStatus status;
  final String esnSuffix;
  final String currentIp;
  final int progress;
  final CpdsErrorCode errorCode;
}

class _DeviceGroupData {
  const _DeviceGroupData({required this.titleKey, required this.rows});

  final String titleKey;
  final List<_DeviceRowData> rows;
}
