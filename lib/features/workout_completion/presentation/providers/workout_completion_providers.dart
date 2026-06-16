import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/utils/date_key.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

String workoutCompletionId(String id) => 'workout:$id';

String exerciseCompletionId(String id) => 'exercise:$id';

@immutable
class WorkoutCompletionState {
  const WorkoutCompletionState({
    required this.date,
    required this.userId,
    this.completedIds = const <String>{},
  });

  final DateTime date;
  final String? userId;
  final Set<String> completedIds;

  bool isCompleted(String id) => completedIds.contains(id);

  int countCompleted(Iterable<String> ids) {
    return ids.where(completedIds.contains).length;
  }

  WorkoutCompletionState copyWith({Set<String>? completedIds}) {
    return WorkoutCompletionState(
      date: date,
      userId: userId,
      completedIds: completedIds ?? this.completedIds,
    );
  }
}

final workoutCompletionControllerProvider =
    NotifierProvider.family<
      WorkoutCompletionController,
      WorkoutCompletionState,
      DateTime
    >(WorkoutCompletionController.new);

class WorkoutCompletionController extends Notifier<WorkoutCompletionState> {
  WorkoutCompletionController(this._date);

  final DateTime _date;

  @override
  WorkoutCompletionState build() {
    final date = DateUtils.dateOnly(_date);
    final userId = ref.watch(currentFirebaseUserProvider)?.uid;
    if (userId == null) {
      return WorkoutCompletionState(date: date, userId: null);
    }

    return WorkoutCompletionState(
      date: date,
      userId: userId,
      completedIds: _loadCompletedIds(userId, date),
    );
  }

  Future<void> toggle(String completionId) async {
    final nextIds = {...state.completedIds};
    if (!nextIds.add(completionId)) {
      nextIds.remove(completionId);
    }
    state = state.copyWith(completedIds: nextIds);
    await _save();
  }

  Future<void> setCompleted(String completionId, bool completed) async {
    final nextIds = {...state.completedIds};
    if (completed) {
      nextIds.add(completionId);
    } else {
      nextIds.remove(completionId);
    }
    state = state.copyWith(completedIds: nextIds);
    await _save();
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = state.userId;
    if (prefs == null || userId == null) {
      return;
    }

    await prefs.setString(
      _key(userId, state.date),
      jsonEncode(state.completedIds.toList()..sort()),
    );
  }

  Set<String> _loadCompletedIds(String userId, DateTime date) {
    final prefs = ref.read(sharedPreferencesProvider);
    final payload = prefs?.getString(_key(userId, date));
    if (payload == null || payload.isEmpty) {
      return const <String>{};
    }

    try {
      final decoded = jsonDecode(payload) as List<dynamic>;
      return decoded.whereType<String>().toSet();
    } on Object {
      return const <String>{};
    }
  }

  String _key(String userId, DateTime date) {
    return 'workout_completion_${userId}_${LocalDateKey.fromDate(date)}';
  }
}
