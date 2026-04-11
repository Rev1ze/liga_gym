import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../providers/dashboard_providers.dart';
import '../utils/analytics_range_query.dart';

class DashboardAnalyticsDetailsScreen extends ConsumerStatefulWidget {
  const DashboardAnalyticsDetailsScreen({super.key});

  @override
  ConsumerState<DashboardAnalyticsDetailsScreen> createState() =>
      _DashboardAnalyticsDetailsScreenState();
}

class _DashboardAnalyticsDetailsScreenState
    extends ConsumerState<DashboardAnalyticsDetailsScreen> {
  late DateTimeRange _selectedRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedRange = DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsState = ref.watch(
      dashboardRangeAnalyticsProvider(
        AnalyticsRangeQuery(from: _selectedRange.start, to: _selectedRange.end),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardAnalyticsRangeTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRetry,
            onPressed: () {
              ref.invalidate(
                dashboardRangeAnalyticsProvider(
                  AnalyticsRangeQuery(
                    from: _selectedRange.start,
                    to: _selectedRange.end,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardAnalyticsRangeSubtitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickStartDate,
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(
                                '${l10n.dashboardAnalyticsFrom}: ${formatLocalizedDate(_selectedRange.start, Localizations.localeOf(context))}',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickEndDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                '${l10n.dashboardAnalyticsTo}: ${formatLocalizedDate(_selectedRange.end, Localizations.localeOf(context))}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.dashboardAnalyticsMaxRangeHint,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                analyticsState.when(
                  data: (analytics) => _AnalyticsDetailsContent(
                    analytics: analytics,
                    isExporting: _isExporting,
                    onExportPdf: () => _savePdf(analytics),
                  ),
                  error: (_, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.errorUnknown),
                    ),
                  ),
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

  Future<void> _pickStartDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: _selectedRange.start,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: _selectedRange.end,
    );

    if (picked == null || !mounted) {
      return;
    }

    final normalized = DateUtils.dateOnly(picked);
    final maxEnd = normalized.add(const Duration(days: 30));
    setState(() {
      _selectedRange = DateTimeRange(
        start: normalized,
        end: _selectedRange.end.isAfter(maxEnd) ? maxEnd : _selectedRange.end,
      );
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final maxAllowedEnd = _selectedRange.start.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: _selectedRange.end,
      firstDate: _selectedRange.start,
      lastDate: maxAllowedEnd.isBefore(now) ? maxAllowedEnd : now,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedRange = DateTimeRange(
        start: _selectedRange.start,
        end: DateUtils.dateOnly(picked),
      );
    });
  }

  Future<void> _savePdf(DashboardRangeAnalytics analytics) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() {
      _isExporting = true;
    });

    try {
      final regularFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/arial.ttf'),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/arialbd.ttf'),
      );
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd.MM.yyyy');
      final rows = analytics.stats.days
          .map(
            (day) => <String>[
              dateFormat.format(day.date),
              day.steps.toString(),
              day.calories.toStringAsFixed(0),
              '${(day.progress.overall * 100).round()}%',
            ],
          )
          .toList(growable: false);

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              l10n.dashboardAnalyticsPdfTitle,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              '${l10n.dashboardAnalyticsPdfRangeLabel}: ${dateFormat.format(analytics.from)} - ${dateFormat.format(analytics.to)}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.dashboardAnalyticsPdfSummaryTitle,
              style: pw.TextStyle(font: boldFont),
            ),
            pw.SizedBox(height: 8),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsWeeklySteps(
                NumberFormat.decimalPattern().format(
                  analytics.stats.totalSteps,
                ),
              ),
            ),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsWeeklyCalories(
                analytics.stats.totalCalories.toStringAsFixed(0),
              ),
            ),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsAverageSteps(
                analytics.averageDailySteps.toStringAsFixed(0),
              ),
            ),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsAverageCalories(
                analytics.averageDailyCalories.toStringAsFixed(0),
              ),
            ),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsWorkoutCalories(
                analytics.totalWorkoutCalories.toStringAsFixed(0),
              ),
            ),
            pw.Bullet(
              style: pw.TextStyle(font: regularFont),
              text: l10n.dashboardAnalyticsWorkoutsCount(
                analytics.totalWorkouts.toString(),
              ),
            ),
            if (analytics.weightAnalytics.currentWeightKg != null)
              pw.Bullet(
                style: pw.TextStyle(font: regularFont),
                text: l10n.dashboardWeightCurrent(
                  analytics.weightAnalytics.currentWeightKg!.toStringAsFixed(1),
                ),
              ),
            if (analytics.weightAnalytics.totalChangeKg != null)
              pw.Bullet(
                style: pw.TextStyle(font: regularFont),
                text: l10n.dashboardAnalyticsWeightChange(
                  analytics.weightAnalytics.totalChangeKg!.toStringAsFixed(1),
                ),
              ),
            pw.SizedBox(height: 20),
            pw.Text(
              l10n.dashboardAnalyticsResultsByDay,
              style: pw.TextStyle(font: boldFont),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: regularFont),
              headers: <String>[
                l10n.commonDate,
                l10n.dashboardAnalyticsSteps,
                l10n.dashboardAnalyticsCalories,
                l10n.dashboardAnalyticsProgress,
              ],
              data: rows,
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'liga_gym_analytics_${DateFormat('yyyyMMdd').format(analytics.from)}_${DateFormat('yyyyMMdd').format(analytics.to)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save(), flush: true);

      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text: l10n.dashboardAnalyticsPdfTitle,
          subject: l10n.dashboardAnalyticsPdfTitle,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.dashboardAnalyticsPdfSaved(file.path))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

class _AnalyticsDetailsContent extends StatelessWidget {
  const _AnalyticsDetailsContent({
    required this.analytics,
    required this.isExporting,
    required this.onExportPdf,
  });

  final DashboardRangeAnalytics analytics;
  final bool isExporting;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _DetailsMetricCard(
              title: l10n.dashboardAnalyticsWeeklySteps(
                NumberFormat.decimalPattern().format(
                  analytics.stats.totalSteps,
                ),
              ),
              subtitle: l10n.dashboardAnalyticsAverageSteps(
                analytics.averageDailySteps.toStringAsFixed(0),
              ),
              icon: Icons.directions_walk_rounded,
              color: const Color(0xFF2563EB),
            ),
            _DetailsMetricCard(
              title: l10n.dashboardAnalyticsWeeklyCalories(
                analytics.stats.totalCalories.toStringAsFixed(0),
              ),
              subtitle: l10n.dashboardAnalyticsAverageCalories(
                analytics.averageDailyCalories.toStringAsFixed(0),
              ),
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF97316),
            ),
            _DetailsMetricCard(
              title: l10n.dashboardAnalyticsWorkoutsCount(
                analytics.totalWorkouts.toString(),
              ),
              subtitle: l10n.dashboardAnalyticsWorkoutCalories(
                analytics.totalWorkoutCalories.toStringAsFixed(0),
              ),
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF0F766E),
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
                  l10n.dashboardWeightTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (analytics.weightAnalytics.hasData)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (analytics.weightAnalytics.periodStartWeightKg != null)
                        _ResultPill(
                          label: l10n.dashboardWeekStartWeight(
                            analytics.weightAnalytics.periodStartWeightKg!
                                .toStringAsFixed(1),
                          ),
                        ),
                      if (analytics.weightAnalytics.periodEndWeightKg != null)
                        _ResultPill(
                          label: l10n.dashboardWeekEndWeight(
                            analytics.weightAnalytics.periodEndWeightKg!
                                .toStringAsFixed(1),
                          ),
                        ),
                      if (analytics.weightAnalytics.currentWeightKg != null)
                        _ResultPill(
                          label: l10n.dashboardWeightCurrent(
                            analytics.weightAnalytics.currentWeightKg!
                                .toStringAsFixed(1),
                          ),
                        ),
                      if (analytics.weightAnalytics.targetWeightKg != null)
                        _ResultPill(
                          label: l10n.dashboardWeightTarget(
                            analytics.weightAnalytics.targetWeightKg!
                                .toStringAsFixed(1),
                          ),
                        ),
                      if (analytics.weightAnalytics.totalChangeKg != null)
                        _ResultPill(
                          label: l10n.dashboardAnalyticsWeightChange(
                            analytics.weightAnalytics.totalChangeKg!
                                .toStringAsFixed(1),
                          ),
                        ),
                      if (analytics.weightAnalytics.remainingToGoalKg != null)
                        _ResultPill(
                          label: l10n.dashboardWeightRemaining(
                            analytics.weightAnalytics.remainingToGoalKg!
                                .abs()
                                .toStringAsFixed(1),
                          ),
                        ),
                    ],
                  )
                else
                  Text(l10n.dashboardAnalyticsNoWeightData),
              ],
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
                  l10n.dashboardAnalyticsResultsByDay,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Column(
                  children: analytics.stats.days
                      .map((day) => _AnalyticsDayTile(day: day))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: isExporting ? null : onExportPdf,
          icon: isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.dashboardAnalyticsExportPdf),
        ),
      ],
    );
  }
}

class _DetailsMetricCard extends StatelessWidget {
  const _DetailsMetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 950
        ? 320.0
        : (width - 80).clamp(260.0, 520.0).toDouble();

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.label});

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

class _AnalyticsDayTile extends StatelessWidget {
  const _AnalyticsDayTile({required this.day});

  final DashboardDaySummary day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(formatLocalizedDate(day.date, locale))),
              Expanded(
                child: Text(
                  '${l10n.dashboardAnalyticsSteps}: ${day.steps}',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '${l10n.dashboardAnalyticsCalories}: ${day.calories.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '${(day.progress.overall * 100).round()}%',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
