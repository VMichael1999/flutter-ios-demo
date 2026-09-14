import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/ai_reply_chunk.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
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
      if (places != null) {
        yield AiPlacesChunk(places, center: _toolbox.lastSearchCenter);
      }

      final text = response.text;
      if (text != null && text.isNotEmpty) yield AiTextChunk(text);
    }
    final places = _toolbox.takeFoundPlaces();
    if (places != null) {
      yield AiPlacesChunk(places, center: _toolbox.lastSearchCenter);
    }
  }

  @override
  void reset() => _chat = null;

  @override
  void restore(List<ChatMessage> history) =>
      _chat = _model.startChat(history: historyToContents(history));
}

/// Convierte los mensajes guardados en el historial que espera Gemini:
/// turnos alternos que empiezan con la persona y terminan con NOVA.
@visibleForTesting
List<Content> historyToContents(List<ChatMessage> messages) {
  final turns = <(String, String)>[];
  for (final message in messages) {
    var text = message.text.trim();
    if (message.isUser && text.isEmpty && message.hasImage) {
      text = '(Envié una imagen)';
    }
    if (text.isEmpty) continue;

    final role = message.isUser ? 'user' : 'model';
    if (turns.isNotEmpty && turns.last.$1 == role) {
      turns.last = (role, '${turns.last.$2}\n$text');
    } else {
      turns.add((role, text));
    }
  }
  while (turns.isNotEmpty && turns.first.$1 == 'model') {
    turns.removeAt(0);
  }
  // Una pregunta sin respuesta (por ejemplo, si falló la red) se descarta.
  if (turns.isNotEmpty && turns.last.$1 == 'user') turns.removeLast();

  return [
    for (final (role, text) in turns) Content(role, [TextPart(text)]),
  ];
}
