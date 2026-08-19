import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import 'cpds_messages.dart';

class CpdsDiscoveryMismatchDialog extends StatelessWidget {
  const CpdsDiscoveryMismatchDialog({
    super.key,
    required this.session,
    required this.submitting,
    required this.onResolve,
  });

  final CpdsSessionView session;
  final bool submitting;
  final ValueChanged<bool> onResolve;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final rows = session.failures
        .where(
          (failure) =>
              failure.stage == 'DISCOVERY' &&
              failure.params.containsKey('expected') &&
              failure.params.containsKey('actual'),
        )
        .toList();
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        CpdsMessages.discoveryMismatchTitle(context),
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              CpdsMessages.discoveryMismatchPrompt(context),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              Center(
                child: Text(
                  CpdsMessages.noData(context),
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            else
              Table(
                border: TableBorder.all(color: const Color(0xFF353A41)),
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FixedColumnWidth(80),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(80),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFF242A31),
                    ),
                    children: [
                      _HeaderCell(text: _deviceTypeTitle(context)),
                      _HeaderCell(text: _expectedTitle(context)),
                      _HeaderCell(text: _discoveredTitle(context)),
                      _HeaderCell(text: _missingTitle(context)),
                      _HeaderCell(text: _extraTitle(context)),
                    ],
                  ),
                  ...rows.map((failure) {
                    final expected = (failure.params['expected'] as num?)?.toInt() ?? 0;
                    final actual = (failure.params['actual'] as num?)?.toInt() ?? 0;
                    return TableRow(
                      children: [
                        _Cell(
                          text: CpdsMessages.deviceType(
                            context,
                            failure.deviceType,
                          ),
                        ),
                        _Cell(text: '$expected'),
                        _Cell(text: '$actual'),
                        _Cell(
                          text: '${(expected - actual).clamp(0, 999999)}',
                          warning: expected > actual,
                        ),
                        _Cell(
                          text: '${(actual - expected).clamp(0, 999999)}',
                          warning: actual > expected,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => onResolve(false),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: submitting ? null : () => onResolve(true),
          child: Text(t.cpds.distribute),
        ),
      ],
    );
  }

  String _deviceTypeTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '设备类型' : 'Device type';
  String _expectedTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '期望' : 'Expected';
  String _discoveredTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '发现' : 'Discovered';
  String _missingTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '缺失' : 'Missing';
  String _extraTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '额外' : 'Extra';
}

class CpdsResultDialog extends StatelessWidget {
  const CpdsResultDialog({super.key, required this.session, required this.onClose});

  final CpdsSessionView session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final completed = session.devices
        .where((item) => item.status == CpdsDeviceStatus.completed)
        .toList();
    final failed = session.devices
        .where((item) => item.status == CpdsDeviceStatus.failed)
        .toList();
    final missing = session.devices
        .where(
          (item) =>
              item.status == CpdsDeviceStatus.pending && item.esnSuffix.isEmpty,
        )
        .toList();
    final ignored = session.devices
        .where((item) => item.status == CpdsDeviceStatus.ignored)
        .toList();
    final offlineCodes = {
      CpdsErrorCode.authTimeout,
      CpdsErrorCode.transferSilenceTimeout,
      CpdsErrorCode.parseTimeout,
    };
    final offline = session.devices
        .where((item) => offlineCodes.contains(item.errorCode))
        .toList();
    final restartRequired = session.activeState == CpdsActiveState.completed ||
        session.activeState == CpdsActiveState.partialSuccess;

    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        CpdsMessages.resultTitle(context, session.activeState),
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _summaryText(
                  context,
                  completed.length,
                  failed.length,
                  missing.length,
                  ignored.length,
                  offline.length,
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (restartRequired) ...[
                const SizedBox(height: 10),
                Text(
                  CpdsMessages.restartPrompt(context),
                  style: const TextStyle(
                    color: Color(0xFFD9FFF0),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _Section(
                title: _completedTitle(context),
                emptyText: _noCompletedTitle(context),
                children: [
                  ...completed.map(
                    (item) => Text(
                      _deviceLine(context, item.device, item.esnSuffix),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (missing.isNotEmpty)
                _Section(
                  title: _missingTitle(context),
                  children: [
                    ...missing.map(
                      (item) =>
                          Text(
                            _deviceLine(context, item.device, item.esnSuffix),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                    ),
                  ],
                ),
              if (ignored.isNotEmpty)
                _Section(
                  title: _ignoredTitle(context),
                  children: [
                    ...ignored.map(
                      (item) =>
                          Text(
                            _deviceLine(context, item.device, item.esnSuffix),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                    ),
                  ],
                ),
              if (session.failures.isNotEmpty)
                _Section(
                  title: _failedTitle(context),
                  children: [
                    ...session.failures.map(
                      (failure) => _FailureLine(failure: failure),
                    ),
                  ],
                ),
              if (offline.isNotEmpty)
                _Section(
                  title: _offlineTitle(context),
                  children: [
                    ...offline.map(
                      (item) =>
                          Text(
                            _deviceLine(context, item.device, item.esnSuffix),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(onPressed: onClose, child: Text(t.common.confirm)),
      ],
    );
  }

  String _summaryText(
    BuildContext context,
    int success,
    int failed,
    int missing,
    int ignored,
    int offline,
  ) {
    final zh = CpdsMessages.isZh(context);
    if (zh) {
      return '成功 $success，失败 $failed，未发现 $missing，忽略 $ignored，掉线 $offline';
    }
    return '$success completed, $failed failed, $missing undiscovered, '
        '$ignored ignored, $offline offline';
  }

  String _deviceLine(BuildContext context, CpdsDevice device, String esn) {
    final type = CpdsMessages.deviceType(context, device.type);
    final name = device.model.isNotEmpty ? device.model : type;
    final esnText = esn.isEmpty ? '--' : esn;
    return '$name · ESN $esnText · ${device.id}';
  }

  String _completedTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '成功完成' : 'Completed devices';
  String _missingTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '未发现设备' : 'Undiscovered devices';
  String _ignoredTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '已忽略设备' : 'Ignored devices';
  String _failedTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '失败明细' : 'Failure details';
  String _offlineTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '掉线设备' : 'Offline devices';
  String _noCompletedTitle(BuildContext context) =>
      CpdsMessages.isZh(context) ? '无成功设备' : 'No completed devices';
}

class CpdsErrorDialog extends StatelessWidget {
  const CpdsErrorDialog({
    super.key,
    required this.title,
    required this.error,
    required this.onClose,
  });

  final String title;
  final CpdsException error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final message = CpdsMessages.errorCode(
      context,
      error.code,
      params: error.params,
    );
    final systemStage = CpdsMessages.failureStage(context, 'UNKNOWN');
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$systemStage · [${error.code.apiName}] $message',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (error.params.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                CpdsMessages.parameterTitle(context),
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...error.params.entries.map(
                (entry) => Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: onClose, child: Text(t.common.confirm)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.emptyText,
  });

  final String title;
  final List<Widget> children;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        border: Border.all(color: const Color(0xFF353A41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (children.isEmpty && emptyText != null)
            Text(
              emptyText!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _FailureLine extends StatelessWidget {
  const _FailureLine({required this.failure});

  final CpdsFailure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        CpdsMessages.failureItem(
          context,
          failure.stage,
          failure.deviceType,
          failure.esnSuffix,
          failure.deviceId,
          failure.errorCode,
          failure.params,
        ),
        style: const TextStyle(color: Color(0xFFF3C6C9), fontSize: 12),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFFFD9A1) : Colors.white70,
        fontWeight: warning ? FontWeight.w700 : FontWeight.w400,
        fontSize: 12,
      ),
    ),
  );
}
