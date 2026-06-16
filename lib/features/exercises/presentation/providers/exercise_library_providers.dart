import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/custom_exercise.dart';

final exerciseLibraryProvider =
    NotifierProvider<ExerciseLibraryController, List<CustomExercise>>(
      ExerciseLibraryController.new,
    );

class ExerciseLibraryController extends Notifier<List<CustomExercise>> {
  @override
  List<CustomExercise> build() {
    final userId = ref.watch(currentFirebaseUserProvider)?.uid ?? 'guest';
    final sharedPreferences = ref.watch(sharedPreferencesProvider);
    final payload = sharedPreferences?.getString(_storageKey(userId));
    if (payload == null || payload.isEmpty) {
      return const <CustomExercise>[];
    }

    try {
      final decoded = jsonDecode(payload) as List<dynamic>;
      final exercises = decoded
          .map(
            (item) =>
                CustomExercise.fromJson(Map<String, Object?>.from(item as Map)),
          )
          .where((exercise) => exercise.title.trim().isNotEmpty)
          .toList(growable: false);

      return exercises..sort(_sortExercises);
    } catch (_) {
      return const <CustomExercise>[];
    }
  }

  Future<void> saveExercise(CustomExercise exercise) async {
    final next = [...state.where((item) => item.id != exercise.id), exercise]
      ..sort(_sortExercises);
    state = next;
    await _persist(next);
  }

  Future<void> deleteExercise(String exerciseId) async {
    final next = state
        .where((exercise) => exercise.id != exerciseId)
        .toList(growable: false);
    state = next;
    await _persist(next);
  }

  Future<void> toggleFavorite(CustomExercise exercise) {
    return saveExercise(exercise.copyWith(isFavorite: !exercise.isFavorite));
  }

  Future<void> _persist(List<CustomExercise> exercises) async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    if (sharedPreferences == null) {
      return;
    }

    final userId = ref.read(currentFirebaseUserProvider)?.uid ?? 'guest';
    final payload = jsonEncode(
      exercises.map((exercise) => exercise.toJson()).toList(growable: false),
    );
    await sharedPreferences.setString(_storageKey(userId), payload);
  }

  int _sortExercises(CustomExercise left, CustomExercise right) {
    if (left.isFavorite != right.isFavorite) {
      return left.isFavorite ? -1 : 1;
    }

    return right.createdAt.compareTo(left.createdAt);
  }

  String _storageKey(String userId) {
    return 'exercise_library_$userId';
  }
}
