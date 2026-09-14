import 'package:firebase_ai/firebase_ai.dart';

import '../../../../core/config/app_config.dart';
import 'ai_remote_datasource.dart';

/// Gemini a través de Firebase AI Logic.
///
/// La API key vive en Firebase, nunca en el código de la app.
class FirebaseAiDataSource implements AiRemoteDataSource {
  FirebaseAiDataSource({GenerativeModel? model})
      : _model = model ??
            FirebaseAI.googleAI().generativeModel(
              model: AppConfig.geminiModel,
              systemInstruction: Content.system(AppConfig.systemPrompt),
            );

  final GenerativeModel _model;
  ChatSession? _chat;

  @override
  Stream<String> streamReply(String message) async* {
    final chat = _chat ??= _model.startChat();
    await for (final response in chat.sendMessageStream(Content.text(message))) {
      final text = response.text;
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  @override
  void reset() => _chat = null;
}
