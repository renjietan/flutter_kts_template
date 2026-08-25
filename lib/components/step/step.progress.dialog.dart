import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/step/step.progress.model.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

class StepProgressDialog extends StatefulWidget {
  const StepProgressDialog({
    super.key,
    required this.controller,
    required this.stepLabels,
    this.onClose,
  });

  final StepProgressController controller;
  final List<String> stepLabels;
  final VoidCallback? onClose;

  @override
  State<StepProgressDialog> createState() => _StepProgressDialogState();
}

class _StepProgressDialogState extends State<StepProgressDialog> {
  static const _accent = Color(0xFF00A2E9);
  static const _dim = Color(0xFF8A94A6);
  static const _line = Color(0xFF353A41);

  final ScrollController _scrollController = ScrollController();
  bool _allowPop = false;

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
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  void _handleClose() {
    setState(() {
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onClose?.call();
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
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepBar(),
              const SizedBox(height: 18),
              _buildDetailBox(),
              if (widget.onClose != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: BaseButton(
                    label: Translations.of(context).common.close,
                    width: 96,
                    height: 32,
                    onPressed: _handleClose,
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
        final labels = widget.stepLabels;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Container(
                      height: 2,
                      color: i <= widget.controller.activeStep
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
    final active = index <= widget.controller.activeStep;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? _accent : Colors.transparent,
              border: Border.all(
                color: active ? _accent : _line,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : _dim,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.stepLabels[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : _dim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF171C22),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(4),
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
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.number != null)
                      Text(
                        '[${line.number}] ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _dim,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        line.text,
                        style: TextStyle(fontSize: 12, color: line.color),
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
