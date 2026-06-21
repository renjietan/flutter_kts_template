import 'dart:math' as math;

import 'package:flutter/material.dart';

class BaseButton extends StatefulWidget {
  final String label;

  final VoidCallback? onPressed;

  final List<Color> colors;

  final Duration gradientDuration;

  /// 抖动
  final bool enablePulse;

  final double borderRadius;

  final double? width;

  final double height;

  final TextStyle? textStyle;

  final IconData? icon;

  final bool isLoading;

  final bool? loadingColor;

  const BaseButton({
    super.key,
    required this.label,
    this.onPressed,
    this.colors = const [
      Color(0xFF00A2E9),
      Color(0xFF00A2E9),
      Color(0xFF00A2E9),
      Color(0xFF00A2E9),
    ],
    this.gradientDuration = const Duration(seconds: 3),
    this.enablePulse = true,
    this.borderRadius = 5,
    this.width = 100,
    this.height = 34,
    this.textStyle = const TextStyle(fontSize: 12, color: Colors.white),
    this.icon,
    this.isLoading = false,
    this.loadingColor,
  });

  @override
  State<BaseButton> createState() => _BaseButtonState();
}

class _BaseButtonState extends State<BaseButton> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  Offset _tapPosition = Offset.zero;
  Color loadingColor = Colors.white;
  @override
  void initState() {
    super.initState();
    if (widget.loadingColor == null) {
      loadingColor = widget.colors[0].withValues(alpha: 0.1);
    }
    _gradientController = AnimationController(
      vsync: this,
      duration: widget.gradientDuration,
    )..repeat();
    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseScale = Tween<double>(
      begin: 0.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _tapPosition = details.localPosition);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    _scaleController.reverse();
    if (widget.enablePulse) {
      _pulseController.forward(from: 0);
    }
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _gradientAnimation,
        _scaleAnimation,
        _pulseScale,
        _pulseOpacity,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // [Colors.grey.shade400, Colors.grey.shade500]
                    _AnimatedGradientBackground(
                      colors: isDisabled ? widget.colors : widget.colors,
                      progress: _gradientAnimation.value,
                    ),
                    if (widget.enablePulse && _pulseController.isAnimating)
                      Positioned(
                        left: _tapPosition.dx - widget.height * 2,
                        top: _tapPosition.dy - widget.height * 2,
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: widget.height * 2,
                              height: widget.height * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  widget.label,
                                  style:
                                      widget.textStyle ??
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  final List<Color> colors;
  final double progress;

  const _AnimatedGradientBackground({
    required this.colors,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientPainter(colors: colors, progress: progress),
      child: const SizedBox.expand(),
    );
  }
}

class _GradientPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;

  _GradientPainter({required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * 2 * math.pi;
    final dx = math.cos(angle);
    final dy = math.sin(angle);

    final center = Offset(size.width / 2, size.height / 2);
    final begin = Alignment(dx, dy);
    final end = Alignment(-dx, -dy);

    final gradient = LinearGradient(begin: begin, end: end, colors: colors);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(0)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientPainter old) =>
      old.progress != progress || old.colors != colors;
}
