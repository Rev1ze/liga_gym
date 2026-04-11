import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nutrition/presentation/providers/nutrition_providers.dart';
import '../../features/workout/presentation/providers/workout_providers.dart';
import 'offline_sync_coordinator.dart';

final appOfflineSyncCoordinatorProvider = Provider<AppOfflineSyncCoordinator>((
  ref,
) {
  return AppOfflineSyncCoordinator(
    nutritionOfflineSyncService: ref.watch(nutritionOfflineSyncServiceProvider),
    workoutOfflineSyncService: ref.watch(workoutOfflineSyncServiceProvider),
  );
});
