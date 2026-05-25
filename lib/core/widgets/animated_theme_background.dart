import 'package:flutter/material.dart';

class AnimatedThemeBackground extends StatelessWidget {
  const AnimatedThemeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.05),
            Theme.of(context).scaffoldBackgroundColor,
            colorScheme.secondary.withValues(alpha: isDark ? 0.11 : 0.06),
            colorScheme.tertiary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
          stops: const [0, 0.44, 0.78, 1],
        ),
      ),
      child: child,
    );
  }
}
