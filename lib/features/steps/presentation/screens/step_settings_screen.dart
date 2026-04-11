import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/step_providers.dart';
import '../../../dashboard/presentation/utils/goal_settings_route_arguments.dart';

class StepSettingsScreen extends ConsumerWidget {
  const StepSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trackingStatusState = ref.watch(stepTrackingStatusProvider);
    final actionState = ref.watch(stepScreenControllerProvider);
    final isBusy = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stepCounterSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            trackingStatusState.when(
              data: (status) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.stepCounterStatusTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusHint(l10n, status),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.errorUnknown),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stepCounterActionsTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: AppKeys.stepScreenEnableButton,
                      onPressed: isBusy
                          ? null
                          : () async {
                              await ref
                                  .read(stepScreenControllerProvider.notifier)
                                  .enableTracking();
                            },
                      icon: const Icon(Icons.directions_walk_rounded),
                      label: Text(l10n.stepCounterEnable),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: AppKeys.stepScreenOpenSettingsButton,
                      onPressed: isBusy
                          ? null
                          : () async {
                              await ref
                                  .read(stepScreenControllerProvider.notifier)
                                  .openSettings();
                            },
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(l10n.stepCounterOpenSettings),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.goalSettings,
                        arguments: const GoalSettingsRouteArguments(
                          section: GoalSettingsSection.steps,
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(l10n.stepCounterGoalSettingsAction),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusHint(AppLocalizations l10n, StepTrackingStatus status) {
    if (!status.isSupported) {
      return l10n.stepCounterUnsupportedHint;
    }
    if (status.permissionPermanentlyDenied) {
      return l10n.stepCounterSettingsHint;
    }
    if (!status.permissionGranted) {
      return l10n.stepCounterPermissionHint;
    }
    if (!status.isServiceRunning || !status.isTrackingCurrentUser) {
      return l10n.stepCounterEnableHint;
    }
    return l10n.stepCounterRunningHint;
  }
}
