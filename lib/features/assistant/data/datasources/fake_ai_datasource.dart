import '../../../../core/strings/ai_prompts.dart';
import '../../domain/entities/ai_reply_chunk.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import 'ai_remote_datasource.dart';

/// Respuestas simuladas para usar NOVA sin Firebase configurado.
class FakeAiDataSource implements AiRemoteDataSource {
  FakeAiDataSource({this.chunkDelay = const Duration(milliseconds: 40)});

  final Duration chunkDelay;

  @override
  Stream<AiReplyChunk> streamReply(
    String message, {
    ChatAttachment? attachment,
  }) async* {
    final reply = AiPrompts.demoReply(
      message: message,
      withImage: attachment != null,
    );
    for (final word in reply.split(' ')) {
      await Future<void>.delayed(chunkDelay);
      yield AiTextChunk('$word ');
    }
  }

  @override
  void reset() {}

  @override
  void restore(List<ChatMessage> history) {}
}
