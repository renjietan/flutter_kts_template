import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

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
    required this.onRefreshInterfaces,
    required this.onSelectInterface,
    required this.onDistribute,
  });

  final CpdsApplicationState state;
  final List<CpdsNetworkInterface> interfaces;
  final String selectedInterfaceName;
  final bool automaticInterface;
  final bool interfacesLoading;
  final bool canDistribute;
  final VoidCallback onRefreshInterfaces;
  final ValueChanged<String?> onSelectInterface;
  final VoidCallback onDistribute;

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
    final deviceRows = _buildDeviceRows(selectedNode, state.session);
    final groups = _groupDevices(deviceRows);
    final stageIndex = _stageIndex(state.session);
    final transferring =
        state.session?.activeState == CpdsActiveState.transferring ||
        state.session?.activeState == CpdsActiveState.drainingAfterFailure;

    return Container(
      color: const Color(0xFF0E1114),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  color: const Color(0xFF00A2E9),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedNode?.name ?? t.cpds.currentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (selectedNode != null)
                        Text(
                          t.cpds.online(
                            online: deviceRows
                                .where((row) => row.status != CpdsDeviceStatus.pending)
                                .length,
                            expected: deviceRows.length,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB7BCC6),
                          ),
                        ),
                    ],
                  ),
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
            canDistribute: canDistribute,
            onSelected: onSelectInterface,
            onRefresh: onRefreshInterfaces,
            onDistribute: onDistribute,
          ),
          _StageStrip(activeIndex: stageIndex),
          if (transferring) ...[
            Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${state.session?.sentChunks ?? 0}/${state.session?.totalChunks ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFFB7BCC6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  CpdsProgressBar(
                    value: state.session?.sendingProgress ?? 0,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171C22),
                border: Border.all(color: const Color(0x26FFFFFF)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selectedNode == null
                  ? Center(
                      child: Text(
                        t.cpds.noSelection,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        ...groups.expand(
                          (group) => [
                            _DeviceGroupHeader(
                              title: _groupTitle(context, group.titleKey),
                              count: group.rows.length,
                            ),
                            ...group.rows.map(
                              (row) => _DeviceRow(row: row),
                            ),
                          ],
                        ),
                      ],
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
    return selectedNode.devices
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
    return switch (session.activeState) {
      CpdsActiveState.discovering ||
      CpdsActiveState.awaitingDiscoveryConfirmation => 0,
      CpdsActiveState.authenticating => 1,
      CpdsActiveState.transferring ||
      CpdsActiveState.drainingAfterFailure => 2,
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
      CpdsDeviceType.server,
      CpdsDeviceType.iec,
    ];
    final groups = <CpdsDeviceType, List<_DeviceRowData>>{};
    for (final row in rows) {
      final key = row.device.type == CpdsDeviceType.ccuAudio
          ? CpdsDeviceType.ccu
          : row.device.type;
      groups.putIfAbsent(key, () => []).add(row);
    }
    final result = groups.entries.map((entry) {
      final titleKey = entry.key == CpdsDeviceType.ccu
          ? 'ccuGroup'
          : _deviceTypeKey(entry.key);
      return _DeviceGroupData(titleKey: titleKey, rows: entry.value);
    }).toList()
      ..sort(
        (a, b) =>
            order.indexOf(_typeFromKey(a.titleKey)) -
            order.indexOf(_typeFromKey(b.titleKey)),
      );
    return result;
  }

  String _groupTitle(BuildContext context, String key) {
    final t = Translations.of(context);
    return switch (key) {
      'server' => t.cpds.deviceTypes.server,
      'hf' => t.cpds.deviceTypes.hf,
      'multiBandRadio' => t.cpds.deviceTypes.multiBandRadio,
      'multiBandHandheld' => t.cpds.deviceTypes.multiBandHandheld,
      'ccuGroup' => t.cpds.deviceTypes.ccuGroup,
      'iec' => t.cpds.deviceTypes.iec,
      'smallHandheld' => t.cpds.deviceTypes.smallHandheld,
      _ => t.cpds.deviceTypes.unknown,
    };
  }

  String _deviceTypeKey(CpdsDeviceType type) => switch (type) {
    CpdsDeviceType.server => 'server',
    CpdsDeviceType.hf => 'hf',
    CpdsDeviceType.multiBandRadio => 'multiBandRadio',
    CpdsDeviceType.multiBandHandheld => 'multiBandHandheld',
    CpdsDeviceType.ccu => 'ccuGroup',
    CpdsDeviceType.iec => 'iec',
    CpdsDeviceType.smallHandheld => 'smallHandheld',
    CpdsDeviceType.ccuAudio => 'ccuGroup',
    CpdsDeviceType.unspecified => 'unknown',
  };

  CpdsDeviceType _typeFromKey(String key) => switch (key) {
    'server' => CpdsDeviceType.server,
    'hf' => CpdsDeviceType.hf,
    'multiBandRadio' => CpdsDeviceType.multiBandRadio,
    'multiBandHandheld' => CpdsDeviceType.multiBandHandheld,
    'ccuGroup' => CpdsDeviceType.ccu,
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleFill,
              border: Border.all(color: circleBorder),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 11, color: numberColor),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: textColor),
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
      width: 24,
      height: 1,
      color: passed ? const Color(0xFF0CB5FF) : const Color(0xFF42474E),
    );
  }
}

class _DeviceGroupHeader extends StatelessWidget {
  const _DeviceGroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF242A31),
      child: Row(
        children: [
          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(fontSize: 12, color: Color(0xFFB7BCC6)),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.row});

  final _DeviceRowData row;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final name = _deviceDisplayName(context, row.device);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF353A41))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              CpdsStatusBadge(status: row.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Meta(label: t.cpds.device.esn, value: row.esnSuffix),
              const SizedBox(width: 16),
              _Meta(label: t.cpds.device.ip, value: row.currentIp),
            ],
          ),
          if (row.status == CpdsDeviceStatus.receiving) ...[
            const SizedBox(height: 8),
            CpdsProgressBar(value: row.progress),
          ],
          if (row.status == CpdsDeviceStatus.failed) ...[
            const SizedBox(height: 6),
            Text(
              row.errorCode.apiName,
              style: const TextStyle(
                color: Color(0xFFF15B64),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _deviceDisplayName(BuildContext context, CpdsDevice device) {
    final t = Translations.of(context);
    final typeKey = switch (device.type) {
      CpdsDeviceType.server => t.cpds.deviceTypes.server,
      CpdsDeviceType.hf => t.cpds.deviceTypes.hf,
      CpdsDeviceType.multiBandRadio => t.cpds.deviceTypes.multiBandRadio,
      CpdsDeviceType.multiBandHandheld => t.cpds.deviceTypes.multiBandHandheld,
      CpdsDeviceType.ccu => t.cpds.deviceTypes.ccu,
      CpdsDeviceType.ccuAudio => t.cpds.deviceTypes.ccuAudio,
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
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
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
