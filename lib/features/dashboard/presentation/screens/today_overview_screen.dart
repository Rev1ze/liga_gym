import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/dashboard_providers.dart';
import '../utils/goal_settings_route_arguments.dart';

class TodayOverviewScreen extends ConsumerWidget {
  const TodayOverviewScreen({super.key});

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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsState = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayOverviewTitle)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.todayOverviewSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 20),
                analyticsState.when(
                  data: (analytics) {
                    final today = analytics.weeklyStats.today;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.dashboardGoalsTitle,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.dashboardGoalsSummary(
                                          analytics.goals.goalType.localize(
                                            l10n,
                                          ),
                                          NumberFormat.decimalPattern().format(
                                            analytics.goals.stepGoal,
                                          ),
                                          analytics.goals.calorieGoal
                                              .toStringAsFixed(0),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _openGoalSettings(
                                    context,
                                    ref,
                                    GoalSettingsSection.progress,
                                  ),
                                  icon: const Icon(Icons.tune_rounded),
                                  label: Text(l10n.dashboardGoalsAction),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _OverviewMetricCard(
                              title: l10n.dashboardAnalyticsSteps,
                              value: NumberFormat.decimalPattern().format(
                                today.steps,
                              ),
                              subtitle: l10n.dashboardAnalyticsStepGoal(
                                NumberFormat.decimalPattern().format(
                                  analytics.goals.stepGoal,
                                ),
                              ),
                              color: const Color(0xFF2563EB),
                              progress: analytics.progress.steps,
                              icon: Icons.directions_walk,
                              onTap: () => _openGoalSettings(
                                context,
                                ref,
                                GoalSettingsSection.steps,
                              ),
                            ),
                            _OverviewMetricCard(
                              title: l10n.dashboardAnalyticsCalories,
                              value: today.calories.toStringAsFixed(0),
                              subtitle: l10n.dashboardAnalyticsCalorieGoal(
                                analytics.goals.calorieGoal.toStringAsFixed(0),
                              ),
                              color: const Color(0xFFF97316),
                              progress: analytics.progress.calories,
                              icon: Icons.local_fire_department,
                              onTap: () => _openGoalSettings(
                                context,
                                ref,
                                GoalSettingsSection.calories,
                              ),
                            ),
                            _OverviewMetricCard(
                              title: l10n.dashboardAnalyticsProgress,
                              value:
                                  '${(analytics.progress.overall * 100).round()}%',
                              subtitle:
                                  analytics.weightAnalytics.currentWeightKg !=
                                      null
                                  ? l10n.dashboardWeightCurrent(
                                      analytics.weightAnalytics.currentWeightKg!
                                          .toStringAsFixed(1),
                                    )
                                  : l10n.dashboardAnalyticsOverallGoal,
                              color: const Color(0xFF0F766E),
                              progress: analytics.progress.overall,
                              icon: Icons.track_changes,
                              onTap: () => _openGoalSettings(
                                context,
                                ref,
                                GoalSettingsSection.progress,
                              ),
                            ),
                          ],
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
                                    _NutritionChip(
                                      label: l10n.foodProteins,
                                      value: analytics.proteins.toStringAsFixed(
                                        1,
                                      ),
                                    ),
                                    _NutritionChip(
                                      label: l10n.foodFats,
                                      value: analytics.fats.toStringAsFixed(1),
                                    ),
                                    _NutritionChip(
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
                  },
                  error: (_, _) => Center(child: Text(l10n.errorUnknown)),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.progress,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final double progress;
  final IconData icon;
  final VoidCallback onTap;

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
                _OverviewProgressRing(
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewProgressRing extends StatelessWidget {
  const _OverviewProgressRing({
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

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({required this.label, required this.value});

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
