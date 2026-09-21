import 'package:flutter/foundation.dart';

/// 单个步骤的状态。
enum StepStatus { pending, running, success, failed }

/// 更新流程的阶段（驱动底部按钮状态机）。
enum UpdatePhase { idle, running, paused, finished }

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
  double _totalProgress = 0;
  String _summary = '';
  int? _terminatedStep;

  int get activeStep => _activeStep;
  UpdatePhase get phase => _phase;
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

  void addDevice(UpdateDevice device) {
    devices.add(device);
    notifyListeners();
  }

  void updateDevice(UpdateDevice device) {
    notifyListeners();
  }
}
