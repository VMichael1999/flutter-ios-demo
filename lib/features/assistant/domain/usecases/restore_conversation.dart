import '../entities/chat_message.dart';
import '../repositories/ai_repository.dart';

class RestoreConversation {
  const RestoreConversation(this._repository);

  final AiRepository _repository;

  void call(List<ChatMessage> history) =>
      _repository.restoreConversation(history);
}
