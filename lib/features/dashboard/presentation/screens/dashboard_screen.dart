import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../providers/dashboard_providers.dart';
import '../utils/goal_settings_route_arguments.dart';
import '../../../auth/presentation/controllers/auth_action_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openProfile(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> _openAnalyticsDetails(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await Navigator.of(context).pushNamed(AppRoutes.dashboardAnalyticsDetails);
    ref.invalidate(dashboardAnalyticsProvider);
  }

  Future<void> _openGoalSettings(
    BuildContext context,
    WidgetRef ref,
    GoalSettingsSection section,
  ) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.goalSettings,
      arguments: GoalSettingsRouteArguments(section: section),
    );
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> _openFoodDiary(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(AppRoutes.foodDiary);
    ref.invalidate(dashboardAnalyticsProvider);
  }

  Future<void> _openStepCounter(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(AppRoutes.stepCounter);
    ref.invalidate(dashboardAnalyticsProvider);
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(authActionControllerProvider.notifier).signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authUserState = ref.watch(authStateChangesProvider);
    final analyticsState = ref.watch(dashboardAnalyticsProvider);
    final isLoading = ref.watch(authActionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            tooltip: l10n.dashboardProfile,
            onPressed: () => _openProfile(context, ref),
            icon: const Icon(Icons.tune_rounded),
          ),
          TextButton(
            key: AppKeys.signOutButton,
            onPressed: isLoading ? null : () => _handleSignOut(context, ref),
            child: Text(l10n.dashboardSignOut),
          ),
        ],
      ),
      bottomNavigationBar: _DashboardBottomBar(
        onStartWorkout: () =>
            Navigator.of(context).pushNamed(AppRoutes.startWorkout),
        onOpenWorkouts: () =>
            Navigator.of(context).pushNamed(AppRoutes.workoutList),
        onOpenStepCounter: () => _openStepCounter(context, ref),
        onOpenNutrition: () => _openFoodDiary(context, ref),
        l10n: l10n,
      ),
      body: SafeArea(
        child: authUserState.when(
          data: (authUser) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _WelcomeCard(email: authUser?.email ?? '-', l10n: l10n),
                    const SizedBox(height: 20),
                    _CommunityCard(l10n: l10n),
                    const SizedBox(height: 20),
                    analyticsState.when(
                      data: (analytics) => _AnalyticsContent(
                        analytics: analytics,
                        l10n: l10n,
                        onOpenGoalSettings: (section) =>
                            _openGoalSettings(context, ref, section),
                        onOpenAnalyticsDetails: () =>
                            _openAnalyticsDetails(context, ref),
                      ),
                      error: (error, _) => _DashboardErrorCard(
                        message: _dashboardErrorMessage(context, error),
                        retryLabel: l10n.commonRetry,
                        onRetry: () =>
                            ref.invalidate(dashboardAnalyticsProvider),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (_, _) => Center(child: Text(l10n.errorUnknown)),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardCommunityTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardCommunitySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: AppKeys.dashboardChatButton,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.chat),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(l10n.dashboardCommunityChat),
                ),
                OutlinedButton.icon(
                  key: AppKeys.dashboardLeaderboardButton,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.leaderboard),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(l10n.dashboardCommunityLeaderboard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _dashboardErrorMessage(BuildContext context, Object error) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (error is TimeoutException) {
    return languageCode == 'ru'
        ? 'Не прогрузилось за 5 секунд. Попробуйте ещё раз.'
        : 'Dashboard did not load within 5 seconds. Please try again.';
  }

  return languageCode == 'ru'
      ? 'Не прогрузилось. Попробуйте ещё раз.'
      : 'Dashboard did not load. Please try again.';
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.email, required this.l10n});

  final String email;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardHeadline,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  l10n.dashboardSignedInAs(email),
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _DashboardBottomBar extends StatelessWidget {
  const _DashboardBottomBar({
    required this.onStartWorkout,
    required this.onOpenWorkouts,
    required this.onOpenStepCounter,
    required this.onOpenNutrition,
    required this.l10n,
  });

  final VoidCallback onStartWorkout;
  final VoidCallback onOpenWorkouts;
  final VoidCallback onOpenStepCounter;
  final VoidCallback onOpenNutrition;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 430 || size.height < 760;

    return BottomAppBar(
      elevation: 8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomBarAction(
              key: AppKeys.dashboardStartWorkoutButton,
              onTap: onStartWorkout,
              icon: Icons.play_arrow_rounded,
              label: l10n.dashboardStartWorkout,
              isCompact: isCompact,
            ),
            _BottomBarAction(
              key: AppKeys.dashboardWorkoutHistoryButton,
              onTap: onOpenWorkouts,
              icon: Icons.history_rounded,
              label: l10n.dashboardWorkoutHistory,
              isCompact: isCompact,
            ),
            _BottomBarAction(
              key: AppKeys.dashboardStepCounterButton,
              onTap: onOpenStepCounter,
              icon: Icons.directions_walk_rounded,
              label: l10n.dashboardStepCounter,
              isCompact: isCompact,
            ),
            _BottomBarAction(
              key: AppKeys.dashboardNutritionDiaryButton,
              onTap: onOpenNutrition,
              icon: Icons.restaurant_menu_rounded,
              label: l10n.dashboardNutritionDiary,
              isCompact: isCompact,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarAction extends StatelessWidget {
  const _BottomBarAction({
    required super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isCompact,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4 : 8,
              vertical: isCompact ? 8 : 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colorScheme.primary),
                if (!isCompact) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.analytics,
    required this.l10n,
    required this.onOpenGoalSettings,
    required this.onOpenAnalyticsDetails,
  });

  final DashboardAnalytics analytics;
  final AppLocalizations l10n;
  final ValueChanged<GoalSettingsSection> onOpenGoalSettings;
  final VoidCallback onOpenAnalyticsDetails;

  @override
  Widget build(BuildContext context) {
    final today = analytics.weeklyStats.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dashboardAnalyticsOverview,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              title: l10n.dashboardAnalyticsSteps,
              value: NumberFormat.decimalPattern().format(today.steps),
              subtitle: l10n.dashboardAnalyticsStepGoal(
                NumberFormat.decimalPattern().format(analytics.goals.stepGoal),
              ),
              color: const Color(0xFF2563EB),
              progress: analytics.progress.steps,
              icon: Icons.directions_walk,
              onTap: () => onOpenGoalSettings(GoalSettingsSection.steps),
            ),
            _MetricCard(
              title: l10n.dashboardAnalyticsCalories,
              value: today.calories.toStringAsFixed(0),
              subtitle: l10n.dashboardAnalyticsCalorieGoal(
                analytics.goals.calorieGoal.toStringAsFixed(0),
              ),
              color: const Color(0xFFF97316),
              progress: analytics.progress.calories,
              icon: Icons.local_fire_department,
              onTap: () => onOpenGoalSettings(GoalSettingsSection.calories),
            ),
            _MetricCard(
              title: l10n.dashboardAnalyticsProgress,
              value: '${(analytics.progress.overall * 100).round()}%',
              subtitle: l10n.dashboardAnalyticsOverallGoal,
              color: const Color(0xFF0F766E),
              progress: analytics.progress.overall,
              icon: Icons.track_changes,
              onTap: () => onOpenGoalSettings(GoalSettingsSection.progress),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _WeightAnalyticsCard(
          analytics: analytics,
          l10n: l10n,
          onOpenGoals: () => onOpenGoalSettings(GoalSettingsSection.progress),
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onOpenAnalyticsDetails,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dashboardAnalyticsWeeklyTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.dashboardAnalyticsWeeklySubtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onOpenAnalyticsDetails,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(l10n.dashboardAnalyticsOpenDetails),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _WeeklyChart(days: analytics.weeklyStats.days),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _LegendPill(
                        label: l10n.dashboardAnalyticsStepsLegend,
                        color: const Color(0xFF2563EB),
                      ),
                      _LegendPill(
                        label: l10n.dashboardAnalyticsCaloriesLegend,
                        color: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _WeeklySummaryPill(
                        label: l10n.dashboardAnalyticsWeeklySteps(
                          NumberFormat.decimalPattern().format(
                            analytics.weeklyStats.totalSteps,
                          ),
                        ),
                      ),
                      _WeeklySummaryPill(
                        label: l10n.dashboardAnalyticsWeeklyCalories(
                          analytics.weeklyStats.totalCalories.toStringAsFixed(
                            0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardNutritionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MacroChip(
                      label: l10n.foodProteins,
                      value: analytics.proteins.toStringAsFixed(1),
                    ),
                    _MacroChip(
                      label: l10n.foodFats,
                      value: analytics.fats.toStringAsFixed(1),
                    ),
                    _MacroChip(
                      label: l10n.foodCarbs,
                      value: analytics.carbs.toStringAsFixed(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeightAnalyticsCard extends StatelessWidget {
  const _WeightAnalyticsCard({
    required this.analytics,
    required this.l10n,
    required this.onOpenGoals,
  });

  final DashboardAnalytics analytics;
  final AppLocalizations l10n;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final weight = analytics.weightAnalytics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardWeightTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              weight.hasData
                  ? l10n.dashboardWeightSubtitle
                  : l10n.dashboardWeightEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            if (weight.hasData)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (weight.currentWeightKg != null)
                    _WeeklySummaryPill(
                      label: l10n.dashboardWeightCurrent(
                        weight.currentWeightKg!.toStringAsFixed(1),
                      ),
                    ),
                  if (weight.targetWeightKg != null)
                    _WeeklySummaryPill(
                      label: l10n.dashboardWeightTarget(
                        weight.targetWeightKg!.toStringAsFixed(1),
                      ),
                    ),
                  if (weight.totalChangeKg != null)
                    _WeeklySummaryPill(
                      label: l10n.dashboardWeightLost(
                        weight.totalChangeKg!.toStringAsFixed(1),
                      ),
                    ),
                  if (weight.weeklyChangeKg != null)
                    _WeeklySummaryPill(
                      label: l10n.dashboardWeightWeekly(
                        weight.weeklyChangeKg!.toStringAsFixed(1),
                      ),
                    ),
                  if (weight.remainingToGoalKg != null)
                    _WeeklySummaryPill(
                      label: l10n.dashboardWeightRemaining(
                        weight.remainingToGoalKg!.abs().toStringAsFixed(1),
                      ),
                    ),
                ],
              )
            else
              Text(
                l10n.dashboardWeightEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onOpenGoals,
                icon: const Icon(Icons.tune_rounded),
                label: Text(l10n.dashboardGoalsAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.progress,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final double progress;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 950
        ? 320.0
        : width > 700
        ? 280.0
        : (width - 80).clamp(260.0, 520.0).toDouble();

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _ProgressRing(
                  progress: progress,
                  color: color,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.child,
  });

  final double progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: color.withValues(alpha: 0.14),
            ),
          ),
          SizedBox(
            width: 74,
            height: 74,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  color: color,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days});

  final List<DashboardDaySummary> days;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maxSteps = days.fold<int>(
      1,
      (current, day) => day.steps > current ? day.steps : current,
    );
    final maxCalories = days.fold<double>(
      1,
      (current, day) => day.calories > current ? day.calories : current,
    );

    return SizedBox(
      height: 236,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 420.0;
          final tileWidth = chartWidth < 420 ? 52.0 : chartWidth / 7.8;
          final contentWidth =
              (tileWidth * days.length) + ((days.length - 1) * 8);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: chartWidth),
              child: SizedBox(
                width: contentWidth < chartWidth ? chartWidth : contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List<Widget>.generate(days.length, (index) {
                    final day = days[index];
                    final isLast = index == days.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 8),
                      child: _WeeklyChartDay(
                        width: tileWidth,
                        day: day,
                        maxSteps: maxSteps,
                        maxCalories: maxCalories,
                        locale: locale,
                      ),
                    );
                  }, growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyChartDay extends StatelessWidget {
  const _WeeklyChartDay({
    required this.width,
    required this.day,
    required this.maxSteps,
    required this.maxCalories,
    required this.locale,
  });

  final double width;
  final DashboardDaySummary day;
  final int maxSteps;
  final double maxCalories;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? colorScheme.primary.withValues(alpha: 0.28)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Text(
            DateFormat.E(locale).format(day.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              color: isToday ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AnimatedBar(
                      heightFactor: day.steps / maxSteps,
                      color: const Color(0xFF2563EB),
                    ),
                    _AnimatedBar(
                      heightFactor: day.calories / maxCalories,
                      color: const Color(0xFFF97316),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            day.steps > 999
                ? '${(day.steps / 1000).toStringAsFixed(1)}k'
                : '${day.steps}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.heightFactor, required this.color});

  final double heightFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: heightFactor.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 10,
          height: 150 * value + 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryPill extends StatelessWidget {
  const _WeeklySummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(label),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}
