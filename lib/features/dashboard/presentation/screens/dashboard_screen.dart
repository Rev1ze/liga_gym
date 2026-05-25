import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_action_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../providers/dashboard_providers.dart';
import '../utils/goal_settings_route_arguments.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openTodayOverview(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(AppRoutes.todayOverview);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(currentUserProfileProvider);
  }

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

    return LigaPremiumScaffold(
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
        onOpenTodayOverview: () => _openTodayOverview(context, ref),
        onStartWorkout: () =>
            Navigator.of(context).pushNamed(AppRoutes.startWorkout),
        onOpenWorkouts: () =>
            Navigator.of(context).pushNamed(AppRoutes.workoutList),
        onOpenStepCounter: () => _openStepCounter(context, ref),
        onOpenNutrition: () => _openFoodDiary(context, ref),
        l10n: l10n,
      ),
      child: SafeArea(
        child: authUserState.when(
          data: (authUser) {
            final analytics = analyticsState.asData?.value;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardAnalyticsProvider);
                    ref.invalidate(currentUserProfileProvider);
                  },
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 118),
                    children: [
                      _HeroStatsCard(
                        email: authUser?.email ?? '-',
                        analytics: analytics,
                        l10n: l10n,
                        onOpenToday: () => _openTodayOverview(context, ref),
                      ).premiumEntrance(),
                      const SizedBox(height: 18),
                      _SmartQuickActions(
                        l10n: l10n,
                        onStartWorkout: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.startWorkout),
                        onOpenNutrition: () => _openFoodDiary(context, ref),
                        onOpenSteps: () => _openStepCounter(context, ref),
                        onOpenCoach: () =>
                            Navigator.of(context).pushNamed(AppRoutes.chat),
                      ).premiumEntrance(delayMs: 90),
                      const SizedBox(height: 18),
                      _CommunityCard(l10n: l10n).premiumEntrance(delayMs: 130),
                      const SizedBox(height: 22),
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
                        loading: () => const Column(
                          children: [
                            SkeletonCard(height: 220),
                            SizedBox(height: 16),
                            SkeletonCard(height: 180),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          error: (_, _) => Center(child: Text(l10n.errorUnknown)),
          loading: () => const Center(child: SkeletonCard(height: 220)),
        ),
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.email,
    required this.analytics,
    required this.l10n,
    required this.onOpenToday,
  });

  final String email;
  final DashboardAnalytics? analytics;
  final AppLocalizations l10n;
  final VoidCallback onOpenToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = analytics?.weeklyStats.today;
    final progress = analytics?.progress.overall ?? 0.36;
    final calories = today?.calories ?? 0;
    final steps = today?.steps ?? 0;

    return GlassCard(
      onTap: onOpenToday,
      borderRadius: 34,
      padding: const EdgeInsets.all(24),
      tint: colorScheme.primary.withValues(alpha: 0.3),
      heroTag: 'dashboard-hero',
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: _GlowOrb(color: colorScheme.secondary, size: 168),
          ),
          Positioned(
            left: -68,
            bottom: -78,
            child: _GlowOrb(color: colorScheme.tertiary, size: 182),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dashboardHeadline,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            height: 0.98,
                          ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 108,
                    child: AnimatedProgressRing(
                      progress: progress,
                      color: colorScheme.secondary,
                      strokeWidth: 9,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'live',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LivePill(
                    icon: Icons.local_fire_department_rounded,
                    label: '${calories.toStringAsFixed(0)} kcal',
                    color: colorScheme.secondary,
                  ),
                  _LivePill(
                    icon: Icons.directions_walk_rounded,
                    label: NumberFormat.compact().format(steps),
                    color: colorScheme.tertiary,
                  ),
                  _LivePill(
                    icon: Icons.verified_user_outlined,
                    label: l10n.dashboardSignedInAs(email),
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartQuickActions extends StatelessWidget {
  const _SmartQuickActions({
    required this.l10n,
    required this.onStartWorkout,
    required this.onOpenNutrition,
    required this.onOpenSteps,
    required this.onOpenCoach,
  });

  final AppLocalizations l10n;
  final VoidCallback onStartWorkout;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenCoach;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final itemWidth = isWide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionTile(
              width: itemWidth,
              icon: Icons.play_arrow_rounded,
              label: l10n.dashboardStartWorkout,
              color: colorScheme.secondary,
              onTap: onStartWorkout,
            ),
            _QuickActionTile(
              width: itemWidth,
              icon: Icons.restaurant_menu_rounded,
              label: l10n.dashboardNutritionDiary,
              color: colorScheme.tertiary,
              onTap: onOpenNutrition,
            ),
            _QuickActionTile(
              width: itemWidth,
              icon: Icons.directions_walk_rounded,
              label: l10n.dashboardStepCounter,
              color: colorScheme.primary,
              onTap: onOpenSteps,
            ),
            _QuickActionTile(
              width: itemWidth,
              icon: Icons.auto_awesome_rounded,
              label: l10n.dashboardCommunityChat,
              color: colorScheme.error,
              onTap: onOpenCoach,
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassCard(
        onTap: onTap,
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        tint: color.withValues(alpha: 0.16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.dashboardCommunityTitle,
            subtitle: l10n.dashboardCommunitySubtitle,
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
                icon: const Icon(Icons.forum_rounded),
                label: Text(l10n.dashboardCommunityChat),
              ),
              OutlinedButton.icon(
                key: AppKeys.dashboardLeaderboardButton,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.friends),
                icon: Icon(Icons.group_rounded, color: colorScheme.secondary),
                label: Text(_friendsLabel(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _friendsLabel(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ru'
      ? 'Друзья'
      : 'Friends';
}

String _dashboardErrorMessage(BuildContext context, Object error) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (error is TimeoutException) {
    return languageCode == 'ru'
        ? 'Dashboard не загрузился за 5 секунд. Попробуйте еще раз.'
        : 'Dashboard did not load within 5 seconds. Please try again.';
  }

  return languageCode == 'ru'
      ? 'Dashboard не загрузился. Попробуйте еще раз.'
      : 'Dashboard did not load. Please try again.';
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _DashboardBottomBar extends StatelessWidget {
  const _DashboardBottomBar({
    required this.onOpenTodayOverview,
    required this.onStartWorkout,
    required this.onOpenWorkouts,
    required this.onOpenStepCounter,
    required this.onOpenNutrition,
    required this.l10n,
  });

  final VoidCallback onOpenTodayOverview;
  final VoidCallback onStartWorkout;
  final VoidCallback onOpenWorkouts;
  final VoidCallback onOpenStepCounter;
  final VoidCallback onOpenNutrition;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 430 || size.height < 760;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: SafeArea(
        top: false,
        child: GlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomBarAction(
                key: AppKeys.dashboardTodayOverviewButton,
                onTap: onOpenTodayOverview,
                icon: Icons.dashboard_customize_rounded,
                label: l10n.todayOverviewTitle,
                isCompact: isCompact,
              ),
              _BottomBarAction(
                key: AppKeys.dashboardStartWorkoutButton,
                onTap: onStartWorkout,
                icon: Icons.play_arrow_rounded,
                label: l10n.dashboardStartWorkout,
                isCompact: isCompact,
                isPrimary: true,
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
    this.isPrimary = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isCompact;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Tooltip(
        message: label,
        child: AnimatedPressable(
          onTap: onTap,
          semanticLabel: label,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 2 : 5,
              vertical: isCompact ? 8 : 9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: LigaMotion.fast,
                  width: isPrimary ? 44 : 36,
                  height: isPrimary ? 44 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary
                        ? colorScheme.secondary
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.7,
                          ),
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.32,
                              ),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.black : colorScheme.primary,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
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
    final colorScheme = Theme.of(context).colorScheme;
    final today = analytics.weeklyStats.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 820;
            final width = isWide
                ? (constraints.maxWidth - 24) / 3
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: KineticMetricCard(
                    label: l10n.dashboardAnalyticsSteps,
                    value: NumberFormat.compact().format(today.steps),
                    subtitle: l10n.dashboardAnalyticsStepGoal(
                      NumberFormat.decimalPattern().format(
                        analytics.goals.stepGoal,
                      ),
                    ),
                    icon: Icons.directions_walk_rounded,
                    color: colorScheme.primary,
                    progress: analytics.progress.steps,
                    onTap: () => onOpenGoalSettings(GoalSettingsSection.steps),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KineticMetricCard(
                    label: l10n.dashboardAnalyticsCalories,
                    value: today.calories.toStringAsFixed(0),
                    subtitle: l10n.dashboardAnalyticsCalorieGoal(
                      analytics.goals.calorieGoal.toStringAsFixed(0),
                    ),
                    icon: Icons.local_fire_department_rounded,
                    color: colorScheme.secondary,
                    progress: analytics.progress.calories,
                    onTap: () =>
                        onOpenGoalSettings(GoalSettingsSection.calories),
                  ),
                ),
                SizedBox(
                  width: isWide ? width : constraints.maxWidth,
                  child: KineticMetricCard(
                    label: l10n.dashboardAnalyticsProgress,
                    value: '${(analytics.progress.overall * 100).round()}%',
                    subtitle: l10n.dashboardAnalyticsOverallGoal,
                    icon: Icons.track_changes_rounded,
                    color: colorScheme.tertiary,
                    progress: analytics.progress.overall,
                    onTap: () =>
                        onOpenGoalSettings(GoalSettingsSection.progress),
                  ),
                ),
              ],
            );
          },
        ).premiumEntrance(delayMs: 180),
        const SizedBox(height: 18),
        _AiRecommendationCard(
          analytics: analytics,
          l10n: l10n,
        ).premiumEntrance(delayMs: 230),
        const SizedBox(height: 18),
        GlassCard(
          onTap: onOpenAnalyticsDetails,
          heroTag: 'weekly-chart',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.dashboardAnalyticsWeeklyTitle,
                subtitle: l10n.dashboardAnalyticsWeeklySubtitle,
                action: IconButton(
                  onPressed: onOpenAnalyticsDetails,
                  tooltip: l10n.dashboardAnalyticsOpenDetails,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ),
              const SizedBox(height: 20),
              _WeeklyLineChart(days: analytics.weeklyStats.days),
              const SizedBox(height: 18),
              HeatmapStrip(
                values: analytics.weeklyStats.days
                    .map((day) => day.progress.overall)
                    .toList(growable: false),
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LegendPill(
                    label: l10n.dashboardAnalyticsStepsLegend,
                    color: colorScheme.primary,
                  ),
                  _LegendPill(
                    label: l10n.dashboardAnalyticsCaloriesLegend,
                    color: colorScheme.secondary,
                  ),
                  _WeeklySummaryPill(
                    label: l10n.dashboardAnalyticsWeeklySteps(
                      NumberFormat.decimalPattern().format(
                        analytics.weeklyStats.totalSteps,
                      ),
                    ),
                  ),
                  _WeeklySummaryPill(
                    label: l10n.dashboardAnalyticsWeeklyCalories(
                      analytics.weeklyStats.totalCalories.toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).premiumEntrance(delayMs: 280),
        const SizedBox(height: 18),
        _WeightAnalyticsCard(
          analytics: analytics,
          l10n: l10n,
          onOpenGoals: () => onOpenGoalSettings(GoalSettingsSection.progress),
        ).premiumEntrance(delayMs: 330),
      ],
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  const _AiRecommendationCard({required this.analytics, required this.l10n});

  final DashboardAnalytics analytics;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remainingSteps = math.max(
      0,
      analytics.goals.stepGoal - analytics.weeklyStats.today.steps,
    );
    final calorieRatio = analytics.goals.calorieGoal <= 0
        ? 0.0
        : analytics.weeklyStats.today.calories / analytics.goals.calorieGoal;
    final recommendation = calorieRatio < 0.55
        ? 'AI: add a 22-minute zone-2 session and a protein-forward meal.'
        : 'AI: recovery load is green. Keep tonight light and protect sleep.';

    return GlassCard(
      tint: colorScheme.secondary.withValues(alpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorScheme.secondary, colorScheme.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.18),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liga AI Coach',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$recommendation ${NumberFormat.compact().format(remainingSteps)} steps left.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.dashboardWeightTitle,
            subtitle: weight.hasData
                ? l10n.dashboardWeightSubtitle
                : l10n.dashboardWeightEmptySubtitle,
            action: IconButton(
              onPressed: onOpenGoals,
              icon: const Icon(Icons.tune_rounded),
              tooltip: l10n.dashboardGoalsAction,
            ),
          ),
          const SizedBox(height: 16),
          if (weight.hasData)
            Wrap(
              spacing: 10,
              runSpacing: 10,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.54,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.dashboardWeightEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  const _WeeklyLineChart({required this.days});

  final List<DashboardDaySummary> days;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final colorScheme = Theme.of(context).colorScheme;
    final maxSteps = math.max(1, days.map((day) => day.steps).reduce(math.max));
    final spots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].steps / maxSteps * 100),
    ];

    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(0, days.length - 1).toDouble(),
          minY: 0,
          maxY: 112,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 28,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.E(locale).format(days[index].date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  colorScheme.surface.withValues(alpha: 0.92),
              tooltipBorder: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              getTooltipItems: (items) {
                return items
                    .map((item) {
                      final index = item.x.round().clamp(0, days.length - 1);
                      final day = days[index];
                      return LineTooltipItem(
                        '${NumberFormat.decimalPattern().format(day.steps)} steps\n${day.calories.toStringAsFixed(0)} kcal',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    })
                    .toList(growable: false);
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 4,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: index == days.length - 1 ? 5 : 3,
                    color: colorScheme.secondary,
                    strokeWidth: 3,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.28),
                    colorScheme.secondary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: LigaMotion.slow,
        curve: LigaMotion.easeOut,
      ),
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(label),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.44), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
