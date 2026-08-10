import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.model.dart';

class SimpleNumberStep extends StatefulWidget {
  final List<SimpleNumberStepModel> steps;
  final double lineWidth;
  final int activeStep;
  const SimpleNumberStep({
    super.key,
    required this.steps,
    this.lineWidth = 30,
    required this.activeStep,
  });

  @override
  State<SimpleNumberStep> createState() => _SimpleNumberStepState();
}

class _SimpleNumberStepState extends State<SimpleNumberStep> {
  @override
  Widget build(BuildContext context) {
    return Row(
      // scrollDirection: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildSteps(),
    );
  }

  List<Widget> _buildSteps() {
    int count = 1;
    List<Widget> res = widget.steps.fold([], (cur, pre) {
      if (cur.isNotEmpty) {
        cur.add(_buildStepLine());
      }
      cur.add(
        _buildStepItem(
          cur.length + 1,
          pre.label,
          isActive: widget.activeStep >= count,
        ),
      );
      count++;
      return cur;
    });
    return res;
  }

  Widget _buildStepItem(int index, String label, {isActive = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.redAccent : Colors.white38,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            "$index",
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.redAccent : Colors.white38,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Center(
      child: Container(
        width: widget.lineWidth,
        height: 1,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
