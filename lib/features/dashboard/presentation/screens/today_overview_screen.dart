import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../providers/dashboard_providers.dart';
import '../utils/goal_settings_route_arguments.dart';

class TodayOverviewScreen extends ConsumerStatefulWidget {
  const TodayOverviewScreen({super.key});

  @override
  ConsumerState<TodayOverviewScreen> createState() =>
      _TodayOverviewScreenState();
}

class _TodayOverviewScreenState extends ConsumerState<TodayOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
    });
  }

  Future<void> _openGoalSettings(
    BuildContext context,
    GoalSettingsSection section,
  ) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.goalSettings,
      arguments: GoalSettingsRouteArguments(section: section),
    );
    ref.invalidate(dashboardAnalyticsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsState = ref.watch(dashboardAnalyticsProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(l10n.todayOverviewTitle)),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  l10n.todayOverviewSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ).premiumEntrance(),
                const SizedBox(height: 14),
                analyticsState.when(
                  data: (analytics) {
                    final today = analytics.weeklyStats.today;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: SectionHeader(
                                  title: l10n.dashboardGoalsTitle,
                                  subtitle: l10n.dashboardGoalsSummary(
                                    analytics.goals.goalType.localize(l10n),
                                    NumberFormat.decimalPattern().format(
                                      analytics.goals.stepGoal,
                                    ),
                                    analytics.goals.calorieGoal.toStringAsFixed(
                                      0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () => _openGoalSettings(
                                  context,
                                  GoalSettingsSection.progress,
                                ),
                                icon: const Icon(Icons.tune_rounded),
                                label: Text(l10n.dashboardGoalsAction),
                              ),
                            ],
                          ),
                        ).premiumEntrance(delayMs: 80),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
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
                              color: Theme.of(context).colorScheme.primary,
                              progress: analytics.progress.steps,
                              icon: Icons.directions_walk_rounded,
                              onTap: () => _openGoalSettings(
                                context,
                                GoalSettingsSection.steps,
                              ),
                            ),
                            _OverviewMetricCard(
                              title: l10n.dashboardAnalyticsCalories,
                              value: today.calories.toStringAsFixed(0),
                              subtitle: l10n.dashboardAnalyticsCalorieGoal(
                                analytics.goals.calorieGoal.toStringAsFixed(0),
                              ),
                              color: Theme.of(context).colorScheme.secondary,
                              progress: analytics.progress.calories,
                              icon: Icons.local_fire_department_rounded,
                              onTap: () => _openGoalSettings(
                                context,
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
                              color: Theme.of(context).colorScheme.tertiary,
                              progress: analytics.progress.overall,
                              icon: Icons.track_changes_rounded,
                              onTap: () => _openGoalSettings(
                                context,
                                GoalSettingsSection.progress,
                              ),
                            ),
                          ],
                        ).premiumEntrance(delayMs: 140),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: l10n.dashboardNutritionTitle,
                                subtitle: 'Macro balance for today',
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 10),
                              HeatmapStrip(
                                values: [
                                  (analytics.proteins / 140)
                                      .clamp(0, 1)
                                      .toDouble(),
                                  (analytics.fats / 80).clamp(0, 1).toDouble(),
                                  (analytics.carbs / 260)
                                      .clamp(0, 1)
                                      .toDouble(),
                                ],
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ).premiumEntrance(delayMs: 260),
                      ],
                    );
                  },
                  error: (_, _) => Center(child: Text(l10n.errorUnknown)),
                  loading: () => const SkeletonCard(height: 220),
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
        : (width - 52).clamp(260.0, 520.0).toDouble();

    return SizedBox(
      width: cardWidth,
      child: KineticMetricCard(
        label: title,
        value: value,
        subtitle: subtitle,
        icon: icon,
        color: color,
        progress: progress,
        onTap: onTap,
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
    return Chip(
      avatar: const Icon(Icons.bolt_rounded, size: 16),
      label: Text('$label: $value'),
    );
  }
}
