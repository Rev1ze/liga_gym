import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_type.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';
import '../utils/workout_route_share.dart';
import '../widgets/workout_route_map.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  WorkoutType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
    });
  }

  List<Workout> _filteredWorkouts(List<Workout> workouts) {
    return workouts
        .where((workout) {
          final workoutDate = DateUtils.dateOnly(workout.startedAt);
          final matchesStart =
              _startDate == null || !workoutDate.isBefore(_startDate!);
          final matchesEnd =
              _endDate == null || !workoutDate.isAfter(_endDate!);
          final matchesType =
              _selectedType == null || workout.type == _selectedType;

          return matchesStart && matchesEnd && matchesType;
        })
        .toList(growable: false);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(now),
      initialDateRange: _startDate == null || _endDate == null
          ? null
          : DateTimeRange(start: _startDate!, end: _endDate!),
    );
    if (pickedRange == null) {
      return;
    }

    setState(() {
      _startDate = DateUtils.dateOnly(pickedRange.start);
      _endDate = DateUtils.dateOnly(pickedRange.end);
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = _WorkoutHistoryCopy(l10n);
    final state = ref.watch(workoutListControllerProvider);
    final workouts = _filteredWorkouts(state.workouts);
    final summary = _WorkoutHistorySummary.fromWorkouts(workouts);

    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(workoutListControllerProvider.notifier)
              .loadUserWorkouts(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _HistoryFiltersCard(
                copy: copy,
                l10n: l10n,
                startDate: _startDate,
                endDate: _endDate,
                selectedType: _selectedType,
                onPickRange: _pickRange,
                onTypeChanged: (type) => setState(() => _selectedType = type),
                onClear: _clearFilters,
              ),
              const SizedBox(height: 16),
              _HistorySummaryCard(copy: copy, summary: summary),
              const SizedBox(height: 16),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (workouts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(copy.empty),
                  ),
                )
              else
                ...workouts.map(
                  (workout) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutHistoryListTile(
                      l10n: l10n,
                      workout: workout,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryFiltersCard extends StatelessWidget {
  const _HistoryFiltersCard({
    required this.copy,
    required this.l10n,
    required this.startDate,
    required this.endDate,
    required this.selectedType,
    required this.onPickRange,
    required this.onTypeChanged,
    required this.onClear,
  });

  final _WorkoutHistoryCopy copy;
  final AppLocalizations l10n;
  final DateTime? startDate;
  final DateTime? endDate;
  final WorkoutType? selectedType;
  final VoidCallback onPickRange;
  final ValueChanged<WorkoutType?> onTypeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final rangeLabel = startDate == null || endDate == null
        ? copy.periodButton
        : '${DateFormat('dd.MM.yyyy').format(startDate!)} - ${DateFormat('dd.MM.yyyy').format(endDate!)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.filtersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPickRange,
              icon: const Icon(Icons.date_range_rounded),
              label: Text(rangeLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WorkoutType?>(
              initialValue: selectedType,
              decoration: InputDecoration(labelText: l10n.workoutFilterType),
              items: [
                DropdownMenuItem<WorkoutType?>(
                  value: null,
                  child: Text(l10n.workoutFilterAllTypes),
                ),
                ...WorkoutType.values.map(
                  (type) => DropdownMenuItem<WorkoutType?>(
                    value: type,
                    child: Text(localizeWorkoutType(l10n, type)),
                  ),
                ),
              ],
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: Text(l10n.workoutFilterClear),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({required this.copy, required this.summary});

  final _WorkoutHistoryCopy copy;
  final _WorkoutHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryTile(label: copy.workouts, value: '${summary.count}'),
            _SummaryTile(
              label: copy.calories,
              value: formatWorkoutCalories(summary.calories),
            ),
            _SummaryTile(
              label: copy.duration,
              value: formatWorkoutDuration(summary.duration),
            ),
            _SummaryTile(
              label: copy.distance,
              value: formatWorkoutDistance(summary.distanceMeters),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _WorkoutHistoryListTile extends StatelessWidget {
  const _WorkoutHistoryListTile({required this.l10n, required this.workout});

  final AppLocalizations l10n;
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final hasRoute = workout.route.isNotEmpty;

    return Card(
      child: ListTile(
        onTap: () => _showWorkoutRouteDetails(context, workout, l10n),
        leading: Icon(
          hasRoute ? Icons.map_rounded : Icons.fitness_center_rounded,
        ),
        title: Text(localizeWorkoutType(l10n, workout.type)),
        subtitle: Text(
          [
            formatWorkoutTimestamp(workout.startedAt),
            hasRoute ? l10n.workoutRouteView : l10n.workoutRouteMissing,
          ].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatWorkoutCalories(workout.calories)),
            Text(formatWorkoutDistance(workout.distanceMeters)),
          ],
        ),
      ),
    );
  }

  void _showWorkoutRouteDetails(
    BuildContext context,
    Workout workout,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          _WorkoutRouteDetailsSheet(workout: workout, l10n: l10n),
    );
  }
}

class _WorkoutRouteDetailsSheet extends StatelessWidget {
  const _WorkoutRouteDetailsSheet({required this.workout, required this.l10n});

  final Workout workout;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizeWorkoutType(l10n, workout.type),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(formatWorkoutTimestamp(workout.startedAt)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _RouteDetailMetric(
                  label: l10n.workoutMetricDuration,
                  value: formatWorkoutDuration(workout.duration),
                ),
                _RouteDetailMetric(
                  label: l10n.workoutMetricDistance,
                  value: formatWorkoutDistance(workout.distanceMeters),
                ),
                _RouteDetailMetric(
                  label: l10n.workoutMetricCalories,
                  value: formatWorkoutCalories(workout.calories),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WorkoutRouteMap(
              route: workout.route,
              emptyMessage: l10n.workoutRouteMissing,
              fullscreenTooltip: l10n.workoutRouteFullscreen,
              fullscreenTitle: l10n.workoutRouteMapTitle,
              height: 280,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: workout.route.isEmpty
                  ? null
                  : () => shareWorkoutRoute(
                      context: context,
                      workout: workout,
                      missingRouteMessage: l10n.workoutRouteMissing,
                      subject: l10n.workoutRouteShareSubject,
                      routeTitle: l10n.workoutRouteMapTitle,
                    ),
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l10n.workoutRouteShare),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteDetailMetric extends StatelessWidget {
  const _RouteDetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _WorkoutHistorySummary {
  const _WorkoutHistorySummary({
    required this.count,
    required this.calories,
    required this.duration,
    required this.distanceMeters,
  });

  final int count;
  final double calories;
  final Duration duration;
  final double distanceMeters;

  factory _WorkoutHistorySummary.fromWorkouts(List<Workout> workouts) {
    return _WorkoutHistorySummary(
      count: workouts.length,
      calories: workouts.fold<double>(
        0,
        (total, workout) => total + workout.calories,
      ),
      duration: workouts.fold<Duration>(
        Duration.zero,
        (total, workout) => total + workout.duration,
      ),
      distanceMeters: workouts.fold<double>(
        0,
        (total, workout) => total + workout.distanceMeters,
      ),
    );
  }
}

class _WorkoutHistoryCopy {
  _WorkoutHistoryCopy(AppLocalizations l10n)
    : _isRu = l10n.localeName.startsWith('ru');

  final bool _isRu;

  String get title => _isRu ? 'Все тренировки' : 'All workouts';
  String get filtersTitle => _isRu ? 'Фильтры' : 'Filters';
  String get periodButton => _isRu ? 'Выбрать период' : 'Select period';
  String get empty => _isRu
      ? 'За выбранный период тренировок нет.'
      : 'No workouts for the selected period.';
  String get workouts => _isRu ? 'Тренировки' : 'Workouts';
  String get calories => _isRu ? 'Калории' : 'Calories';
  String get duration => _isRu ? 'Время' : 'Time';
  String get distance => _isRu ? 'Расстояние' : 'Distance';
}
