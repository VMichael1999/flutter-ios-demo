import '../../domain/entities/ai_reply_chunk.dart';
import 'ai_remote_datasource.dart';

/// Respuestas simuladas para usar NOVA sin Firebase configurado.
class FakeAiDataSource implements AiRemoteDataSource {
  FakeAiDataSource({this.chunkDelay = const Duration(milliseconds: 40)});

  final Duration chunkDelay;

  @override
  Stream<AiReplyChunk> streamReply(String message) async* {
    final reply = 'Estoy en modo demo porque Firebase todavía no está '
        'configurado. Recibí tu mensaje: "$message". Cuando conectemos '
        'Firebase AI Logic, te responderé con Gemini en tiempo real.';

    for (final word in reply.split(' ')) {
      await Future<void>.delayed(chunkDelay);
      yield AiTextChunk('$word ');
    }
  }

  @override
  void reset() {}
}
