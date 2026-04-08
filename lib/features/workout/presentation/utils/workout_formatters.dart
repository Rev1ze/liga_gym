import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout_type.dart';

String formatWorkoutDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

  return '$hours:$minutes:$seconds';
}

String formatWorkoutDistance(double distanceMeters) {
  final distanceKm = distanceMeters / 1000;
  return '${distanceKm.toStringAsFixed(2)} km';
}

String formatWorkoutCalories(double calories) {
  return '${calories.toStringAsFixed(0)} kcal';
}

String formatWorkoutTimestamp(DateTime dateTime) {
  return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
}

String localizeWorkoutType(AppLocalizations l10n, WorkoutType type) {
  return switch (type) {
    WorkoutType.running => l10n.workoutTypeRunning,
    WorkoutType.cycling => l10n.workoutTypeCycling,
    WorkoutType.walking => l10n.workoutTypeWalking,
    WorkoutType.strength => l10n.workoutTypeStrength,
    WorkoutType.cardio => l10n.workoutTypeCardio,
  };
}
