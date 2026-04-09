import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/daily_food_diary.dart';
import '../providers/nutrition_providers.dart';

@immutable
class FoodDiaryState {
  const FoodDiaryState({
    required this.selectedDate,
    required this.diary,
    this.isLoading = false,
    this.errorCode,
  });

  final DateTime selectedDate;
  final bool isLoading;
  final DailyFoodDiary diary;
  final AppErrorCode? errorCode;

  FoodDiaryState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    DailyFoodDiary? diary,
    Object? errorCode = _sentinel,
  }) {
    return FoodDiaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      diary: diary ?? this.diary,
      errorCode: errorCode == _sentinel
          ? this.errorCode
          : errorCode as AppErrorCode?,
    );
  }
}

const Object _sentinel = Object();

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
        errorCode: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      selectedDate: targetDate,
      errorCode: null,
    );
    try {
      final diary = await ref
          .read(loadDailyFoodEntriesUseCaseProvider)
          .call(userId: user.uid, date: targetDate);

      state = state.copyWith(isLoading: false, diary: diary, errorCode: null);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorCode: error.code);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorCode: AppErrorCode.unknown);
    }
  }
}
