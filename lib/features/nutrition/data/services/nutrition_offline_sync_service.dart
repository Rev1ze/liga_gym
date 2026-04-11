import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/offline_sync_service.dart';
import '../datasources/nutrition_local_data_source.dart';
import '../datasources/nutrition_remote_data_source.dart';
import '../models/food_entry_model.dart';

class NutritionOfflineSyncService extends OfflineSyncService<FoodEntryModel> {
  const NutritionOfflineSyncService({
    required NutritionLocalDataSource nutritionLocalDataSource,
    required NutritionRemoteDataSource nutritionRemoteDataSource,
  }) : _nutritionLocalDataSource = nutritionLocalDataSource,
       _nutritionRemoteDataSource = nutritionRemoteDataSource;

  final NutritionLocalDataSource _nutritionLocalDataSource;
  final NutritionRemoteDataSource _nutritionRemoteDataSource;

  @override
  Future<void> syncDataWithServer({required String userId}) async {
    final pendingEntries = await _nutritionLocalDataSource
        .loadPendingFoodEntries(userId: userId);

    for (final localEntry in pendingEntries) {
      try {
        final remoteEntry = await _nutritionRemoteDataSource.loadFoodEntryById(
          userId: userId,
          entryId: localEntry.id,
        );
        final resolvedEntry = resolveConflicts(
          localRecord: localEntry,
          remoteRecord: remoteEntry,
        );

        if (_shouldKeepRemoteVersion(
          localEntry: localEntry,
          remoteEntry: remoteEntry,
          resolvedEntry: resolvedEntry,
        )) {
          await _nutritionLocalDataSource.saveFoodEntry(
            resolvedEntry.withSyncStatus(true),
          );
          continue;
        }

        await _nutritionRemoteDataSource.saveFoodEntry(resolvedEntry);
        await _nutritionLocalDataSource.markFoodEntrySynced(resolvedEntry.id);
      } on AppException {
        // Keep the entry locally and retry on the next sync cycle.
      } catch (_) {
        // Background sync should stay non-blocking for the user flow.
      }
    }
  }

  bool _shouldKeepRemoteVersion({
    required FoodEntryModel localEntry,
    required FoodEntryModel? remoteEntry,
    required FoodEntryModel resolvedEntry,
  }) {
    final remote = remoteEntry;
    if (remote == null) {
      return false;
    }

    return identical(resolvedEntry, remote) ||
        remote.lastModifiedAt.isAfter(localEntry.lastModifiedAt);
  }
}
