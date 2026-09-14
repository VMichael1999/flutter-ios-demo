import '../entities/ai_reply_chunk.dart';

abstract interface class AiRepository {
  /// Envía [message] a la IA y emite la respuesta por fragmentos.
  ///
  /// Los errores se emiten como `AiFailure`.
  Stream<AiReplyChunk> streamReply(String message);

  /// Olvida el historial de la conversación actual.
  void resetConversation();
}
