import 'package:flutter/material.dart';

/// 进度详情中的一行日志。
class StepProgressLine {
  final int id;
  final String text;
  final String? number;
  Color color;

  StepProgressLine({
    required this.id,
    required this.text,
    required this.color,
    this.number,
  });
}

/// 驱动 [StepProgressDialog] 的控制器。
///
/// 导出流程通过 [setStep] 更新进度条当前步骤，通过 [addLine] / [setLineColor]
/// 向详情框追加或更新日志。
class StepProgressController extends ChangeNotifier {
  final List<StepProgressLine> _lines = [];
  int _activeStep = 0;
  int _nextId = 0;

  int get activeStep => _activeStep;
  List<StepProgressLine> get lines => List.unmodifiable(_lines);

  void setStep(int step) {
    final next = step < 0 ? 0 : step;
    if (next == _activeStep) return;
    _activeStep = next;
    notifyListeners();
  }

  int addLine(
    String text, {
    Color color = Colors.white,
    String? number,
  }) {
    final id = _nextId++;
    _lines.add(
      StepProgressLine(id: id, text: text, color: color, number: number),
    );
    notifyListeners();
    return id;
  }

  void setLineColor(int id, Color color) {
    final index = _lines.indexWhere((line) => line.id == id);
    if (index < 0 || _lines[index].color == color) return;
    _lines[index].color = color;
    notifyListeners();
  }
}
