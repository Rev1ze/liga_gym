import 'package:flutter/material.dart';

class AnimatedThemeBackground extends StatelessWidget {
  const AnimatedThemeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: isDark ? 0.11 : 0.035),
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.secondary.withValues(alpha: isDark ? 0.08 : 0.04),
              colorScheme.tertiary.withValues(alpha: isDark ? 0.07 : 0.035),
            ],
            stops: const [0, 0.5, 0.82, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}
