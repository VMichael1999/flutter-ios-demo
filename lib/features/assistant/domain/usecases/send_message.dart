import '../entities/ai_reply_chunk.dart';
import '../entities/chat_attachment.dart';
import '../repositories/ai_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final AiRepository _repository;

  Stream<AiReplyChunk> call(String message, {ChatAttachment? attachment}) =>
      _repository.streamReply(message, attachment: attachment);
}
