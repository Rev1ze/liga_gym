import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/step_tracking_service.dart';
import '../providers/step_providers.dart';

class StepCounterScreen extends ConsumerStatefulWidget {
  const StepCounterScreen({super.key});

  @override
  ConsumerState<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends ConsumerState<StepCounterScreen> {
  StreamSubscription<Map<String, dynamic>?>? _stepUpdateSubscription;

  @override
  void initState() {
    super.initState();
    if (isStepTrackingSupportedPlatform) {
      _stepUpdateSubscription = FlutterBackgroundService()
          .on(stepTrackingUpdateEvent)
          .listen((_) {
            ref.invalidate(todayStepCountProvider);
            ref.invalidate(stepTrackingStatusProvider);
          });
    }
  }

  @override
  void dispose() {
    _stepUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayStepsState = ref.watch(todayStepCountProvider);
    final trackingStatusState = ref.watch(stepTrackingStatusProvider);
    final actionState = ref.watch(stepScreenControllerProvider);
    final isBusy = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stepCounterTitle),
        actions: [
          IconButton(
            key: AppKeys.stepScreenRefreshButton,
            onPressed: () {
              ref.read(stepScreenControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stepCounterToday,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    todayStepsState.when(
                      data: (steps) => Text(
                        NumberFormat.decimalPattern().format(steps),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => Text(l10n.errorUnknown),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.stepCounterTodayHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            trackingStatusState.when(
              data: (status) => _StatusCard(status: status),
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
                    if (actionState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.errorUnknown,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.status});

  final StepTrackingStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
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
            _StatusRow(
              label: l10n.stepCounterStatusPlatform,
              value: status.isSupported
                  ? l10n.stepCounterStatusSupported
                  : l10n.stepCounterStatusUnsupported,
            ),
            _StatusRow(
              label: l10n.stepCounterStatusPermission,
              value: _permissionLabel(l10n, status),
            ),
            _StatusRow(
              label: l10n.stepCounterStatusService,
              value: status.isServiceRunning
                  ? l10n.stepCounterStatusRunning
                  : l10n.stepCounterStatusStopped,
            ),
            _StatusRow(
              label: l10n.stepCounterStatusAccount,
              value: status.isTrackingCurrentUser
                  ? l10n.stepCounterStatusLinked
                  : l10n.stepCounterStatusNotLinked,
            ),
            const SizedBox(height: 12),
            Text(
              _statusHint(l10n, status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionLabel(AppLocalizations l10n, StepTrackingStatus status) {
    if (status.permissionGranted) {
      return l10n.stepCounterStatusGranted;
    }
    if (status.permissionPermanentlyDenied) {
      return l10n.stepCounterStatusPermanentlyDenied;
    }
    return l10n.stepCounterStatusDenied;
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
