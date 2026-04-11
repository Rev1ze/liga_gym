import '../entities/chat_message.dart';
import '../repositories/social_repository.dart';

class ListenMessagesUseCase {
  const ListenMessagesUseCase(this._repository);

  final SocialRepository _repository;

  Stream<List<ChatMessage>> call({int limit = 50}) {
    return _repository.listenMessages(limit: limit);
  }
}
