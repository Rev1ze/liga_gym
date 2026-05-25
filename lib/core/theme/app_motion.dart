import 'package:flutter/animation.dart';

abstract final class LigaMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 420);
  static const slow = Duration(milliseconds: 760);
  static const cinematic = Duration(milliseconds: 1100);

  static const easeOut = Cubic(0.16, 1, 0.3, 1);
  static const easeInOut = Cubic(0.65, 0, 0.35, 1);
  static const emphasis = Cubic(0.2, 0.8, 0.2, 1);

  static const spring = SpringDescription(
    mass: 0.85,
    stiffness: 260,
    damping: 22,
  );
  static const softSpring = SpringDescription(
    mass: 1,
    stiffness: 145,
    damping: 18,
  );
}
