import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/step_providers.dart';

class StepScreenController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> enableTracking() async {
    final user = ref.read(firebaseStepUserProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(stepTrackingServiceProvider)
          .ensureTracking(userId: user.uid);
      ref.invalidate(stepTrackingStatusProvider);
      ref.invalidate(todayStepCountProvider);
    });
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  void refresh() {
    ref.invalidate(stepTrackingStatusProvider);
    ref.invalidate(todayStepCountProvider);
  }
}
