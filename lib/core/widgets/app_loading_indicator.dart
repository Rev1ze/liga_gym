import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    this.size = 52,
    this.strokeWidth = 5,
    this.label,
    super.key,
  });

  final double size;
  final double strokeWidth;
  final String? label;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _PulseLoaderPainter(
                  progress: _controller.value,
                  primary: colorScheme.primary,
                  secondary: colorScheme.secondary,
                  tertiary: colorScheme.tertiary,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(widget.label!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _PulseLoaderPainter extends CustomPainter {
  const _PulseLoaderPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.strokeWidth,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.15);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [primary, secondary, tertiary, primary],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 1.35,
      false,
      arcPaint,
    );

    final dotAngle = progress * math.pi * 2;
    final dotOffset = Offset(math.cos(dotAngle), math.sin(dotAngle)) * radius;
    canvas.drawCircle(
      center + dotOffset,
      strokeWidth * 0.72,
      Paint()..color = secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseLoaderPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        primary != oldDelegate.primary ||
        secondary != oldDelegate.secondary ||
        tertiary != oldDelegate.tertiary ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
