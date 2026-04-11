import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/step_local_data_source.dart';
import '../../data/models/daily_step_count_model.dart';
import '../../data/repositories/step_repository_impl.dart';
import '../../data/services/step_tracking_service.dart';
import '../controllers/step_screen_controller.dart';
import '../../domain/repositories/step_repository.dart';
import '../../domain/usecases/load_step_counts_use_case.dart';

final firebaseStepUserProvider = Provider(
  (ref) => ref.watch(firebaseAuthProvider).currentUser,
);

final stepLocalDataSourceProvider = Provider<StepLocalDataSource>(
  (ref) => SqfliteStepLocalDataSource(),
);

final stepRepositoryProvider = Provider<StepRepository>(
  (ref) => StepRepositoryImpl(
    stepLocalDataSource: ref.watch(stepLocalDataSourceProvider),
  ),
);

final loadStepCountsUseCaseProvider = Provider(
  (ref) => LoadStepCountsUseCase(ref.watch(stepRepositoryProvider)),
);

final stepTrackingServiceProvider = Provider(
  (ref) => StepTrackingService(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  ),
);

class StepTrackingStatus {
  const StepTrackingStatus({
    required this.isSupported,
    required this.permissionStatus,
    required this.isServiceRunning,
    required this.isTrackingCurrentUser,
  });

  final bool isSupported;
  final PermissionStatus permissionStatus;
  final bool isServiceRunning;
  final bool isTrackingCurrentUser;

  bool get permissionGranted => permissionStatus.isGranted;
  bool get permissionPermanentlyDenied => permissionStatus.isPermanentlyDenied;
}

final stepTrackingStatusProvider = FutureProvider<StepTrackingStatus>((
  ref,
) async {
  if (!isStepTrackingSupportedPlatform) {
    return const StepTrackingStatus(
      isSupported: false,
      permissionStatus: PermissionStatus.denied,
      isServiceRunning: false,
      isTrackingCurrentUser: false,
    );
  }

  final currentUser = ref.watch(firebaseStepUserProvider);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final trackedUserId = sharedPreferences?.getString(
    stepTrackingActiveUserIdKey,
  );
  final permissionStatus = await Permission.activityRecognition.status;
  final isServiceRunning = await ref
      .read(stepTrackingServiceProvider)
      .isRunning();

  return StepTrackingStatus(
    isSupported: true,
    permissionStatus: permissionStatus,
    isServiceRunning: isServiceRunning,
    isTrackingCurrentUser:
        currentUser != null && trackedUserId == currentUser.uid,
  );
});

final todayStepCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(firebaseStepUserProvider);
  if (user == null) {
    return 0;
  }

  return ref
      .watch(stepRepositoryProvider)
      .loadStepsForDate(userId: user.uid, date: DateTime.now());
});

final stepGoalProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  return profile?.dailyStepGoal ?? 10000;
});

final stepGoalCelebrationPendingProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(firebaseStepUserProvider);
  if (user == null) {
    return false;
  }
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  final pendingDate = sharedPreferences?.getString(
    stepGoalCelebrationPendingDateKey(user.uid),
  );
  final todayKey = buildStepDateKey(DateTime.now());
  return pendingDate == todayKey;
});

final stepScreenControllerProvider =
    NotifierProvider<StepScreenController, AsyncValue<void>>(
      StepScreenController.new,
    );
