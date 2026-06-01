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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coach/domain/entities/coach_request.dart';
import '../../../coach/domain/entities/coach_trainer.dart';
import '../../../coach/presentation/providers/coach_providers.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authUserState = ref.watch(authStateChangesProvider);
    final analyticsState = ref.watch(dashboardAnalyticsProvider);
    final profileState = ref.watch(currentUserProfileProvider);

    profileState.whenData((profile) {
      if (profile?.isTrainer != true) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.coachDashboard, (route) => false);
      });
    });

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            tooltip: l10n.dashboardProfile,
            onPressed: () => _openProfile(context, ref),
            icon: const Icon(Icons.person_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _DashboardBottomBar(
        onOpenTodayOverview: () => _openTodayOverview(context, ref),
        onOpenWorkouts: () =>
            Navigator.of(context).pushNamed(AppRoutes.workoutList),
        onOpenFriends: () => Navigator.of(context).pushNamed(AppRoutes.friends),
        onOpenAiCoach: () => Navigator.of(context).pushNamed(AppRoutes.aiCoach),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _HeroStatsCard(
                        email: authUser?.email ?? '-',
                        analytics: analytics,
                        l10n: l10n,
                        onOpenToday: () => _openTodayOverview(context, ref),
                      ).premiumEntrance(),
                      const SizedBox(height: 12),
                      _SmartQuickActions(
                        l10n: l10n,
                        onStartWorkout: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.startWorkout),
                        onOpenNutrition: () => _openFoodDiary(context, ref),
                        onOpenSteps: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.stepCounter),
                        onOpenAnalytics: () =>
                            _openAnalyticsDetails(context, ref),
                      ).premiumEntrance(delayMs: 90),
                      const SizedBox(height: 14),
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

// ignore: unused_element
class _StudentCoachCard extends ConsumerWidget {
  const _StudentCoachCard();

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    CoachRequest request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    try {
      await ref
          .read(coachRepositoryProvider)
          .acceptCoachRequest(
            requestId: request.id,
            studentId: request.studentId,
          );
      ref.invalidate(incomingCoachRequestsProvider);
      ref.invalidate(linkedCoachTrainersProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRu ? 'Тренер добавлен.' : 'Coach added.')),
      );
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    }
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    CoachRequest request,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref
          .read(coachRepositoryProvider)
          .declineCoachRequest(
            requestId: request.id,
            studentId: request.studentId,
          );
      ref.invalidate(incomingCoachRequestsProvider);
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsState = ref.watch(incomingCoachRequestsProvider);
    final trainersState = ref.watch(linkedCoachTrainersProvider);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final requests = requestsState.asData?.value ?? const <CoachRequest>[];
    final trainers = trainersState.asData?.value ?? const <CoachTrainer>[];
    final isLoading = requestsState.isLoading || trainersState.isLoading;

    if (requests.isEmpty && trainers.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    if (isLoading && requests.isEmpty && trainers.isEmpty) {
      return const SkeletonCard(height: 128);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isRu ? 'Мои тренеры' : 'My coaches',
            subtitle: isRu
                ? 'Принимайте запросы и смотрите, кто уже подключен к профилю.'
                : 'Accept coach requests and see who is connected.',
          ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isRu ? 'Запросы от тренеров' : 'Coach requests',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final request in requests) ...[
              _CoachRequestTile(
                request: request,
                isRu: isRu,
                onAccept: () => _accept(context, ref, request),
                onDecline: () => _decline(context, ref, request),
              ),
              if (request != requests.last) const Divider(height: 18),
            ],
          ],
          if (trainers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isRu ? 'Подключенные тренеры' : 'Connected coaches',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final trainer in trainers) ...[
              _CoachTrainerTile(trainer: trainer),
              if (trainer != trainers.last) const Divider(height: 18),
            ],
          ],
        ],
      ),
    );
  }
}

class _CoachRequestTile extends StatelessWidget {
  const _CoachRequestTile({
    required this.request,
    required this.isRu,
    required this.onAccept,
    required this.onDecline,
  });

  final CoachRequest request;
  final bool isRu;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.workspace_premium_rounded),
      title: Text(request.trainerName),
      subtitle: Text(
        request.trainerEmail.isEmpty
            ? (isRu
                  ? 'Хочет стать вашим тренером'
                  : 'Wants to become your coach')
            : request.trainerEmail,
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: isRu ? 'Отклонить' : 'Decline',
            onPressed: onDecline,
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton.filled(
            tooltip: isRu ? 'Принять' : 'Accept',
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}

class _CoachTrainerTile extends StatelessWidget {
  const _CoachTrainerTile({required this.trainer});

  final CoachTrainer trainer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.fitness_center_rounded),
      title: Text(trainer.name),
      subtitle: trainer.email.isEmpty ? null : Text(trainer.email),
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
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      tint: colorScheme.primary.withValues(alpha: 0.22),
      heroTag: 'dashboard-hero',
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 10,
            child: _HeroAccentTrace(color: colorScheme.secondary),
          ),
          Positioned(
            right: 46,
            bottom: 6,
            child: _HeroAccentTrace(color: colorScheme.tertiary, reverse: true),
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
                            height: 1.02,
                          ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 86,
                    child: AnimatedProgressRing(
                      progress: progress,
                      color: colorScheme.secondary,
                      strokeWidth: 7,
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
              const SizedBox(height: 8),
              Text(
                l10n.dashboardSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
    required this.onOpenAnalytics,
  });

  final AppLocalizations l10n;
  final VoidCallback onStartWorkout;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final itemWidth = isWide
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
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
              label: l10n.dashboardAnalyticsOpenDetails,
              color: colorScheme.error,
              onTap: onOpenAnalytics,
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
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        tint: color.withValues(alpha: 0.12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
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
    required this.onOpenWorkouts,
    required this.onOpenFriends,
    required this.onOpenAiCoach,
    required this.l10n,
  });

  final VoidCallback onOpenTodayOverview;
  final VoidCallback onOpenWorkouts;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenAiCoach;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 430 || size.height < 760;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SafeArea(
        top: false,
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                key: AppKeys.dashboardWorkoutHistoryButton,
                onTap: onOpenWorkouts,
                icon: Icons.history_rounded,
                label: l10n.dashboardWorkoutHistory,
                isCompact: isCompact,
                isPrimary: true,
              ),
              _BottomBarAction(
                key: AppKeys.dashboardLeaderboardButton,
                onTap: onOpenFriends,
                icon: Icons.group_rounded,
                label: _friendsLabel(context),
                isCompact: isCompact,
              ),
              _BottomBarAction(
                key: AppKeys.dashboardAiCoachButton,
                onTap: onOpenAiCoach,
                icon: Icons.auto_awesome_rounded,
                label: 'Liga AI',
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 1 : 4,
              vertical: isCompact ? 6 : 7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: LigaMotion.fast,
                  width: isPrimary ? 40 : 32,
                  height: isPrimary ? 40 : 32,
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
                              blurRadius: 10,
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
                  const SizedBox(height: 4),
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
        const SizedBox(height: 12),
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
              const SizedBox(height: 14),
              _WeeklyLineChart(days: analytics.weeklyStats.days),
              const SizedBox(height: 12),
              HeatmapStrip(
                values: analytics.weeklyStats.days
                    .map((day) => day.progress.overall)
                    .toList(growable: false),
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        _WeightAnalyticsCard(
          analytics: analytics,
          l10n: l10n,
          onOpenGoals: () => onOpenGoalSettings(GoalSettingsSection.progress),
        ).premiumEntrance(delayMs: 330),
      ],
    );
  }
}

// ignore: unused_element
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [colorScheme.secondary, colorScheme.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.18),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
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
          const SizedBox(height: 12),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.54,
                ),
                borderRadius: BorderRadius.circular(14),
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
      height: 190,
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
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: index == days.length - 1 ? 4 : 2.5,
                    color: colorScheme.secondary,
                    strokeWidth: 2,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _HeroAccentTrace extends StatelessWidget {
  const _HeroAccentTrace({required this.color, this.reverse = false});

  final Color color;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: reverse ? -0.22 : 0.22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.36),
                color.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox(width: 138, height: 6),
        ),
      ),
    );
  }
}
