import 'package:firebase_ai/firebase_ai.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/ai_reply_chunk.dart';
import '../../domain/entities/chat_attachment.dart';
import '../tools/nova_toolbox.dart';
import 'ai_remote_datasource.dart';

/// Gemini a través de Firebase AI Logic.
///
/// La API key vive en Firebase, nunca en el código de la app. El chat ejecuta
/// automáticamente las funciones de [NovaToolbox] cuando Gemini las pide.
class FirebaseAiDataSource implements AiRemoteDataSource {
  FirebaseAiDataSource({required NovaToolbox toolbox, GenerativeModel? model})
    : _toolbox = toolbox,
      _model =
          model ??
          FirebaseAI.googleAI().generativeModel(
            model: AppConfig.geminiModel,
            systemInstruction: Content.system(AppConfig.systemPrompt),
            tools: toolbox.tools,
          );

  final NovaToolbox _toolbox;
  final GenerativeModel _model;
  ChatSession? _chat;

  @override
  Stream<AiReplyChunk> streamReply(
    String message, {
    ChatAttachment? attachment,
  }) async* {
    final chat = _chat ??= _model.startChat();
    final content =
        attachment == null
            ? Content.text(message)
            : Content.multi([
              InlineDataPart(attachment.mimeType, attachment.bytes),
              TextPart(message),
            ]);

    await for (final response in chat.sendMessageStream(content)) {
      // Las funciones se ejecutan entre respuestas del modelo.
      final places = _toolbox.takeFoundPlaces();
      if (places != null) yield AiPlacesChunk(places);

      final text = response.text;
      if (text != null && text.isNotEmpty) yield AiTextChunk(text);
    }
    final places = _toolbox.takeFoundPlaces();
    if (places != null) yield AiPlacesChunk(places);
  }

  @override
  void reset() => _chat = null;
}
