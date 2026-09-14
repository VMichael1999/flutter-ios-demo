import '../../domain/entities/ai_reply_chunk.dart';

abstract interface class AiRemoteDataSource {
  /// Emite la respuesta del modelo por fragmentos.
  Stream<AiReplyChunk> streamReply(String message);

  /// Descarta la sesión de chat y su historial.
  void reset();
}
