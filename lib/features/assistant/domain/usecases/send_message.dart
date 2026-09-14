import '../entities/ai_reply_chunk.dart';
import '../repositories/ai_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final AiRepository _repository;

  Stream<AiReplyChunk> call(String message) => _repository.streamReply(message);
}
