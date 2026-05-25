import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';
import 'animated_theme_background.dart';

class LigaPremiumScaffold extends StatelessWidget {
  const LigaPremiumScaffold({
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = true,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: AnimatedThemeBackground(child: child),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.tint,
    this.onTap,
    this.heroTag,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tint;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final baseTint = tint ?? colorScheme.surface;
    final content = RepaintBoundary(
      child: AnimatedContainer(
        duration: LigaMotion.medium,
        curve: LigaMotion.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseTint.withValues(alpha: isDark ? 0.48 : 0.72),
              colorScheme.surface.withValues(alpha: isDark ? 0.2 : 0.86),
            ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: isDark ? 28 : 18,
              offset: const Offset(0, 14),
            ),
            if (isDark)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
          ],
        ),
        child: child,
      ),
    );

    final wrapped = onTap == null
        ? content
        : AnimatedPressable(onTap: onTap, borderRadius: radius, child: content);

    if (heroTag == null) {
      return wrapped;
    }

    return Hero(
      tag: heroTag!,
      flightShuttleBuilder: (_, animation, _, _, toHeroContext) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: LigaMotion.easeOut),
          ),
          child: toHeroContext.widget,
        );
      },
      child: Material(color: Colors.transparent, child: wrapped),
    );
  }
}

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                _setPressed(false);
                HapticFeedback.selectionClick();
              },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.975 : 1,
          duration: LigaMotion.fast,
          curve: LigaMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class KineticMetricCard extends StatelessWidget {
  const KineticMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.progress,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.14),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.24 : 0.12),
                      blurRadius: isDark ? 18 : 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              if (progress != null)
                SizedBox.square(
                  dimension: 42,
                  child: AnimatedProgressRing(
                    progress: progress!,
                    color: color,
                    strokeWidth: 5,
                    child: const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class AnimatedProgressRing extends StatelessWidget {
  const AnimatedProgressRing({
    required this.progress,
    required this.color,
    required this.child,
    this.strokeWidth = 10,
    super.key,
  });

  final double progress;
  final Color color;
  final Widget child;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1).toDouble()),
      duration: LigaMotion.slow,
      curve: LigaMotion.easeOut,
      builder: (context, value, _) {
        return CustomPaint(
          isComplex: true,
          willChange: value < progress,
          painter: _RingPainter(
            progress: value,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
            strokeWidth: strokeWidth,
          ),
          child: Center(child: child),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = backgroundColor;
    final foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.2),
          color,
          Colors.white.withValues(alpha: 0.86),
          color,
        ],
      ).createShader(rect);

    canvas.drawCircle(center, radius, background);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class HeatmapStrip extends StatelessWidget {
  const HeatmapStrip({required this.values, required this.color, super.key});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: values[i].clamp(0, 1).toDouble(),
              ),
              duration: Duration(milliseconds: 420 + i * 70),
              curve: LigaMotion.easeOut,
              builder: (context, value, _) {
                return Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        color.withValues(alpha: 0.14 + value * 0.34),
                        color.withValues(alpha: 0.28 + value * 0.56),
                      ],
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: value * 0.14),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({this.height = 160, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
            ),
          ),
        ).animate().shimmer(duration: const Duration(milliseconds: 1350)),
      ),
    );
  }
}

extension PremiumEntrance on Widget {
  Widget premiumEntrance({int delayMs = 0}) {
    return animate()
        .fadeIn(
          delay: Duration(milliseconds: delayMs),
          duration: LigaMotion.medium,
          curve: LigaMotion.easeOut,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: delayMs),
          duration: LigaMotion.medium,
          curve: LigaMotion.easeOut,
        );
  }
}
