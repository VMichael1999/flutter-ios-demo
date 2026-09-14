import '../repositories/ai_repository.dart';

class ResetConversation {
  const ResetConversation(this._repository);

  final AiRepository _repository;

  void call() => _repository.resetConversation();
}
