import '../../../../core/errors/app_exception.dart';
import '../repositories/social_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final SocialRepository _repository;

  Future<void> call({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const SocialException(AppErrorCode.emptyChatMessage);
    }

    return _repository.sendMessage(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      message: trimmedMessage,
    );
  }
}
