// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/step/step.progress.model.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/arabic_digits.dart';

class StepProgressDialog extends StatefulWidget {
  const StepProgressDialog({super.key, required this.controller, this.onClose});

  final StepProgressController controller;
  final Future<void> Function()? onClose;

  @override
  State<StepProgressDialog> createState() => _StepProgressDialogState();
}

class _StepProgressDialogState extends State<StepProgressDialog> {
  static const _accent = Color(0xFF00A2E9);
  static const _dim = Color(0xFF8A94A6);
  static const _line = Color(0xFF353A41);
  static const _danger = Color(0xFFF15B64);

  final ScrollController _scrollController = ScrollController();
  bool _allowPop = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _handleClose() async {
    if (_closing) return;
    setState(() {
      _closing = true;
    });
    try {
      await widget.onClose?.call();
    } finally {
      if (mounted) {
        setState(() {
          _closing = false;
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      child: AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        title: null,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        content: SizedBox(
          width: 560.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepBar(),
              SizedBox(height: 18.h),
              _buildDetailBox(),
              if (widget.onClose != null) ...[
                SizedBox(height: 16.h),
                Center(
                  child: BaseButton(
                    label: Translations.of(context).common.close,
                    minWidth: 96.w,
                    height: 32.h,
                    isLoading: _closing,
                    onPressed: _closing ? null : _handleClose,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBar() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final labels = widget.controller.stepLabels;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 13.h),
                    child: Container(
                      height: 2.h,
                      color: i == widget.controller.terminatedStep
                          ? _danger
                          : i <= widget.controller.activeStep
                          ? _accent
                          : _line,
                    ),
                  ),
                ),
              _buildStepItem(i),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStepItem(int index) {
    final terminated = index == widget.controller.terminatedStep;
    final active = index <= widget.controller.activeStep;
    final circleBorder = terminated
        ? _danger
        : active
        ? _accent
        : _line;
    final circleFill = terminated
        ? _danger
        : active
        ? _accent
        : Colors.transparent;
    final numberColor = terminated || active ? Colors.white : _dim;
    final labelColor = terminated
        ? _danger
        : active
        ? Colors.white
        : _dim;
    return SizedBox(
      width: 64.w,
      child: Column(
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleFill,
              border: Border.all(color: circleBorder, width: 1.5.w),
            ),
            alignment: Alignment.center,
            child: Text(
              localizeDigits(context, '$index'),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: numberColor,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.controller.stepLabels[index],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: labelColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox() {
    return Container(
      height: 190.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF171C22),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final lines = widget.controller.lines;
          return ListView.builder(
            controller: _scrollController,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.number != null)
                      Text(
                        '[${localizeDigits(context, line.number ?? '')}] ',
                        style: TextStyle(fontSize: 12.sp, color: _dim),
                      ),
                    Expanded(
                      child: Text(
                        line.text,
                        style: TextStyle(fontSize: 12.sp, color: line.color),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
