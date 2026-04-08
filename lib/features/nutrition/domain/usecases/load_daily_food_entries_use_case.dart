import '../entities/daily_food_diary.dart';
import '../repositories/nutrition_repository.dart';

class LoadDailyFoodEntriesUseCase {
  const LoadDailyFoodEntriesUseCase(this._nutritionRepository);

  final NutritionRepository _nutritionRepository;

  Future<DailyFoodDiary> call({
    required String userId,
    required DateTime date,
  }) {
    return _nutritionRepository.loadDailyFoodEntries(
      userId: userId,
      date: date,
    );
  }
}
