import '../../../../core/errors/app_exception.dart';
import '../entities/food_entry_draft.dart';
import '../repositories/nutrition_repository.dart';

class AddFoodEntryUseCase {
  const AddFoodEntryUseCase(this._nutritionRepository);

  final NutritionRepository _nutritionRepository;

  Future<void> call({
    required String userId,
    required FoodEntryDraft draft,
  }) async {
    // Блокируем сохранение пустых или некорректных порций до обращения к хранилищу.
    if (draft.grams <= 0) {
      throw const ValidationException(AppErrorCode.invalidFoodWeight);
    }

    await _nutritionRepository.addFoodEntry(userId: userId, draft: draft);
  }
}
