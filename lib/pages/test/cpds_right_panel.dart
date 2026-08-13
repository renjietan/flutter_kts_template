import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.item.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.model.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

enum CpdsDeviceStatus {
  notStarted,
  discovered,
  receiving,
  waitingParse,
  completed,
  failed,
}

class CpdsDeviceItem {
  const CpdsDeviceItem({
    required this.typeLabel,
    this.model,
    this.esnSuffix = '',
    this.ip = '',
    this.status = CpdsDeviceStatus.notStarted,
    this.progress,
    this.statusText,
  });

  final String typeLabel;
  final String? model;
  final String esnSuffix;
  final String ip;
  final CpdsDeviceStatus status;

  /// 仅 Transfer 阶段非空，用于显示接收进度条及百分比。
  final double? progress;

  /// 已本地化的状态/错误文案；为空时按 [status] 使用默认文案。
  final String? statusText;
}

class CpdsDeviceGroup {
  const CpdsDeviceGroup({required this.title, required this.items});

  final String title;
  final List<CpdsDeviceItem> items;
}

class CpdsRightPanel extends StatelessWidget {
  const CpdsRightPanel({
    super.key,
    required this.nodeName,
    required this.visible,
    required this.selectedNetworkIndex,
    required this.networkOptions,
    required this.activeStep,
    required this.steps,
    required this.deviceGroups,
    required this.onlineCount,
    required this.onNetworkChanged,
    required this.onRefresh,
    required this.onIssue,
  });

  final String nodeName;
  final bool visible;
  final int selectedNetworkIndex;
  final List<SimpleDarkDropdownItem<int>> networkOptions;
  final int activeStep;
  final List<SimpleNumberStepModel> steps;
  final List<CpdsDeviceGroup> deviceGroups;
  final int onlineCount;
  final ValueChanged<int?> onNetworkChanged;
  final VoidCallback onRefresh;
  final VoidCallback onIssue;

  static const Color _pageBackground = Color(0xFF0E1114);
  static const Color _contentBackground = Color(0xFF171C22);
  static const Color _inputBackground = Color(0xFF282D33);
  static const Color _accent = Color(0xFF00A2E9);
  static const Color _grey = Color(0xFF8A94A6);
  static const Color _separator = Color(0xFF353A41);

  int get _expectedCount =>
      deviceGroups.fold<int>(0, (sum, group) => sum + group.items.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBackground,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildNetworkControls(context),
          const SizedBox(height: 12),
          _buildStageBar(context),
          const SizedBox(height: 12),
          Expanded(
            child: Visibility(
              visible: visible,
              child: _buildDeviceList(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(width: 5, color: _accent)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Expanded(
              child: TextTitle(
                text: nodeName,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '已上线 $onlineCount/$_expectedCount',
              style: const TextStyle(
                color: _grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkControls(BuildContext context) {
    final t = Translations.of(context);
    final width = MediaQuery.of(context).size.width;
    final dropdownWidth = width < 460 ? 160.0 : 220.0;

    final label = Text(
      t.pager.injectParams.networkCard,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    );

    final dropdown = SimpleDarkDropdown<int>(
      width: dropdownWidth,
      height: 36,
      hintText: t.TextField.select,
      prefixIcon: Icons.network_check,
      value: selectedNetworkIndex,
      items: networkOptions,
      onChanged: onNetworkChanged,
    );

    final refreshButton = Container(
      width: 74,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _accent, width: 2),
      ),
      child: Center(
        child: BaseButton(
          label: t.button.paramsInject.refresh,
          width: 70,
          height: 30,
          colors: const [
            Color(0xFF0A1D35),
            Color(0xFF0A1D35),
            Color(0xFF0A1D35),
            Color(0xFF0A1D35),
          ],
          onPressed: onRefresh,
        ),
      ),
    );

    final issueButton = BaseButton(
      label: t.button.paramsInject.issue,
      width: 74,
      height: 36,
      onPressed: selectedNetworkIndex < 0 ? null : onIssue,
    );

    if (width < 560) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [label, const SizedBox(width: 8), dropdown]),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              refreshButton,
              const SizedBox(width: 8),
              issueButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        label,
        const SizedBox(width: 8),
        dropdown,
        const Spacer(),
        refreshButton,
        const SizedBox(width: 12),
        issueButton,
      ],
    );
  }

  Widget _buildStageBar(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _contentBackground,
        border: Border.all(color: _accent.withValues(alpha: 0.54)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SimpleNumberStep(
            steps: steps,
            lineWidth: 16,
            activeStep: activeStep,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    if (deviceGroups.isEmpty) {
      return Center(
        child: Text(
          Translations.of(context).common.noData,
          style: const TextStyle(color: _grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      itemCount: deviceGroups.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGroup(context, deviceGroups[index]),
        );
      },
    );
  }

  Widget _buildGroup(BuildContext context, CpdsDeviceGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            group.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _contentBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _separator, width: 1),
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _separator),
                _buildDeviceCard(context, group.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, CpdsDeviceItem item) {
    final statusColor = _statusColor(item.status);
    final statusText = item.statusText ?? _statusLabel(item.status);
    final progress = item.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.model != null && item.model!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.model!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _grey, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMeta('ESN', item.esnSuffix),
              const SizedBox(width: 20),
              _buildMeta('IP', item.ip),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: _inputBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF39C12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFFF39C12),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeta(String label, String value) {
    return Expanded(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: _grey, fontSize: 11),
            ),
            TextSpan(
              text: value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _statusColor(CpdsDeviceStatus status) {
    switch (status) {
      case CpdsDeviceStatus.notStarted:
        return const Color(0xFF6B7280);
      case CpdsDeviceStatus.discovered:
        return _accent;
      case CpdsDeviceStatus.receiving:
        return const Color(0xFFF39C12);
      case CpdsDeviceStatus.waitingParse:
        return const Color(0xFF9AA4B0);
      case CpdsDeviceStatus.completed:
        return const Color(0xFF2ECC71);
      case CpdsDeviceStatus.failed:
        return const Color(0xFFE74C3C);
    }
  }

  String _statusLabel(CpdsDeviceStatus status) {
    switch (status) {
      case CpdsDeviceStatus.notStarted:
        return '未开始';
      case CpdsDeviceStatus.discovered:
        return '已发现';
      case CpdsDeviceStatus.receiving:
        return '接收中';
      case CpdsDeviceStatus.waitingParse:
        return '等待解析';
      case CpdsDeviceStatus.completed:
        return '已完成';
      case CpdsDeviceStatus.failed:
        return '失败';
    }
  }
}
