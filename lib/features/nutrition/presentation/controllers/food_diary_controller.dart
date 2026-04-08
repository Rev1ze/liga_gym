import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_food_diary.dart';
import '../providers/nutrition_providers.dart';

@immutable
class FoodDiaryState {
  const FoodDiaryState({
    required this.selectedDate,
    required this.diary,
    this.isLoading = false,
  });

  final DateTime selectedDate;
  final bool isLoading;
  final DailyFoodDiary diary;

  FoodDiaryState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    DailyFoodDiary? diary,
  }) {
    return FoodDiaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      diary: diary ?? this.diary,
    );
  }
}

class FoodDiaryController extends Notifier<FoodDiaryState> {
  @override
  FoodDiaryState build() {
    final today = DateUtils.dateOnly(DateTime.now());
    return FoodDiaryState(
      selectedDate: today,
      diary: DailyFoodDiary(date: today, entries: const []),
    );
  }

  Future<void> loadDailyFoodEntries([DateTime? date]) async {
    final user = ref.read(firebaseNutritionUserProvider);
    final targetDate = DateUtils.dateOnly(date ?? state.selectedDate);

    if (user == null) {
      state = state.copyWith(
        selectedDate: targetDate,
        diary: DailyFoodDiary(date: targetDate, entries: const []),
      );
      return;
    }

    state = state.copyWith(isLoading: true, selectedDate: targetDate);
    try {
      final diary = await ref
          .read(loadDailyFoodEntriesUseCaseProvider)
          .call(userId: user.uid, date: targetDate);

      state = state.copyWith(isLoading: false, diary: diary);
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
