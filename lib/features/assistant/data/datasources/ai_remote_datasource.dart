import '../../domain/entities/ai_reply_chunk.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';

abstract interface class AiRemoteDataSource {
  /// Emite la respuesta del modelo por fragmentos.
  Stream<AiReplyChunk> streamReply(
    String message, {
    ChatAttachment? attachment,
  });

  /// Descarta la sesión de chat y su historial.
  void reset();

  /// Empieza una sesión nueva que ya conoce [history].
  void restore(List<ChatMessage> history);
}
