import '../../features/nutrition/data/services/nutrition_offline_sync_service.dart';
import '../../features/workout/data/services/workout_offline_sync_service.dart';

class AppOfflineSyncCoordinator {
  const AppOfflineSyncCoordinator({
    required NutritionOfflineSyncService nutritionOfflineSyncService,
    required WorkoutOfflineSyncService workoutOfflineSyncService,
  }) : _nutritionOfflineSyncService = nutritionOfflineSyncService,
       _workoutOfflineSyncService = workoutOfflineSyncService;

  final NutritionOfflineSyncService _nutritionOfflineSyncService;
  final WorkoutOfflineSyncService _workoutOfflineSyncService;

  Future<void> syncDataWithServer({required String userId}) async {
    await _nutritionOfflineSyncService.syncDataWithServer(userId: userId);
    await _workoutOfflineSyncService.syncDataWithServer(userId: userId);
  }
}
