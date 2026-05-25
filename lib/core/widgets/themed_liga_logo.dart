import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ThemedLigaLogo extends StatelessWidget {
  const ThemedLigaLogo({
    this.width,
    this.height,
    this.repeat = true,
    super.key,
  });

  final double? width;
  final double? height;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Lottie.asset(
      'assets/lottie/liga_gym_logo.json',
      width: width,
      height: height,
      repeat: repeat,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(const [
            '**',
            'Ring Stroke',
          ], value: colorScheme.primary),
          ValueDelegate.color(const [
            '**',
            'Barbell Fill',
          ], value: colorScheme.secondary),
        ],
      ),
    );
  }
}
