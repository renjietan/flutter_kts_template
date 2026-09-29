import 'package:flutter/foundation.dart';

/// 单个步骤的状态。
enum StepStatus { pending, running, success, failed }

/// 更新流程的阶段（驱动底部按钮状态机）。
///
/// [authFailed] 表示认证 3 次窗口后仍无有效设备，进入可恢复失败态：
/// 保留 UDP 供【重新认证】，底部显示【取消】+【重新认证】。
///
/// [versionFailed] 表示版本校验 3 次窗口后仍无设备回复，进入可恢复失败态：
/// 保留 UDP 供【重新版本校验】，底部显示【取消】+【重新版本校验】。
///
/// [validFailed] 表示校验阶段有设备不是 `valid_ok`，进入可恢复失败态：
/// 底部显示【取消】+【重新校验】。
///
/// [writeFailed] 表示写入阶段有设备不是 `write_ok`，进入可恢复失败态：
/// 底部显示【取消】+【重新写入】。
enum UpdatePhase {
  idle,
  running,
  paused,
  finished,
  authFailed,
  versionFailed,
  validFailed,
  writeFailed,
}

/// 传输步骤（activeStep == 3）的子状态，驱动【开始/暂停/继续】按钮。
enum TransferStage { notStarted, sending, paused, finished }

/// 更新步骤。
class UpdateStep {
  UpdateStep(this.label);

  final String label;
  StepStatus status = StepStatus.pending;
}

/// 设备明细行。
class UpdateDevice {
  UpdateDevice({required this.ip, required this.type, String? rawIp})
    : rawIp = rawIp ?? ip;

  /// 展示用 IP（重复时带「（重复）」后缀）。
  String ip;

  /// 原始 IP，用于后续版本校验匹配。
  final String rawIp;
  String type;
  String currentVersion = '';
  String newVersion = '';
  String status = '';
  double progress = 0;
  int transferredBytes = 0;
  int totalBytes = 0;
  String result = '';
}

/// 更新步骤弹窗的状态控制器。
class UpdateStepController extends ChangeNotifier {
  UpdateStepController({required this.version, required this.fileName});

  static const List<String> stepLabels = [
    '发现',
    '认证',
    '版本校验',
    '传输',
    '校验',
    '写入',
    '回执',
  ];

  final String version;
  final String fileName;
  final List<UpdateStep> steps = stepLabels
      .map((label) => UpdateStep(label))
      .toList();
  final List<UpdateDevice> devices = [];

  int _activeStep = 0;
  UpdatePhase _phase = UpdatePhase.idle;
  TransferStage _transferStage = TransferStage.notStarted;
  double _totalProgress = 0;
  String _summary = '';
  int? _terminatedStep;

  int get activeStep => _activeStep;
  UpdatePhase get phase => _phase;
  TransferStage get transferStage => _transferStage;
  double get totalProgress => _totalProgress;
  String get summary => _summary;
  int? get terminatedStep => _terminatedStep;

  void setActiveStep(int step) {
    _activeStep = step;
    notifyListeners();
  }

  void setStepStatus(int step, StepStatus status) {
    steps[step].status = status;
    notifyListeners();
  }

  void setPhase(UpdatePhase phase) {
    _phase = phase;
    notifyListeners();
  }

  void setTransferStage(TransferStage stage) {
    _transferStage = stage;
    notifyListeners();
  }

  void setTotalProgress(double progress) {
    _totalProgress = progress;
    notifyListeners();
  }

  void setSummary(String summary) {
    _summary = summary;
    notifyListeners();
  }

  /// 标记某步骤失败，并将步骤条切到失败态。
  void markFailed(int step) {
    steps[step].status = StepStatus.failed;
    _terminatedStep = step;
    notifyListeners();
  }

  /// 清空设备明细表（重新认证前调用）。
  void clearDevices() {
    devices.clear();
    notifyListeners();
  }

  /// 将某步骤从失败恢复为进行中（重新认证前调用）。
  void clearFailure(int step) {
    if (steps[step].status == StepStatus.failed) {
      steps[step].status = StepStatus.running;
    }
    if (_terminatedStep == step) {
      _terminatedStep = null;
    }
    notifyListeners();
  }

  /// 全量复位：清空设备、步骤状态、阶段与传输子状态。
  void reset() {
    devices.clear();
    for (final step in steps) {
      step.status = StepStatus.pending;
    }
    _activeStep = 0;
    _phase = UpdatePhase.idle;
    _transferStage = TransferStage.notStarted;
    _totalProgress = 0;
    _summary = '';
    _terminatedStep = null;
    notifyListeners();
  }

  void addDevice(UpdateDevice device) {
    devices.add(device);
    notifyListeners();
  }

  void updateDevice(UpdateDevice device) {
    notifyListeners();
  }
}
