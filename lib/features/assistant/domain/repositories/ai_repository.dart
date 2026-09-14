import '../entities/ai_reply_chunk.dart';
import '../entities/chat_attachment.dart';

abstract interface class AiRepository {
  /// Envía [message] (y la imagen [attachment], si hay) a la IA y emite la
  /// respuesta por fragmentos.
  ///
  /// Los errores se emiten como `AiFailure`.
  Stream<AiReplyChunk> streamReply(
    String message, {
    ChatAttachment? attachment,
  });

  /// Olvida el historial de la conversación actual.
  void resetConversation();
}
