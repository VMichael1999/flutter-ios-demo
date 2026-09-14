import '../repositories/ai_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final AiRepository _repository;

  Stream<String> call(String message) => _repository.streamReply(message);
}
