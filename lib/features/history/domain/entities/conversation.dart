import 'package:equatable/equatable.dart';

import '../../../assistant/domain/entities/chat_message.dart';

/// De dónde salió la conversación: el chat escrito o el modo voz.
enum ConversationSource { chat, voice }

/// Lo necesario para listar una conversación sin cargar sus mensajes.
class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    this.source = ConversationSource.chat,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final ConversationSource source;

  @override
  List<Object?> get props => [id, title, preview, updatedAt, source];
}

/// Una conversación guardada en el historial.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.updatedAt,
    required this.messages,
    this.source = ConversationSource.chat,
  });

  final String id;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final ConversationSource source;

  /// El primer mensaje de la persona resume de qué trata la conversación.
  String get title {
    for (final message in messages) {
      if (!message.isUser) continue;
      final text = _oneLine(message.text);
      if (text.isNotEmpty) return _shorten(text, 48);
      if (message.hasImage) return 'Foto';
    }
    return source == ConversationSource.voice
        ? 'Conversación por voz'
        : 'Conversación';
  }

  /// El último mensaje con texto, en una línea y sin formato.
  String get preview {
    for (final message in messages.reversed) {
      final text = _oneLine(message.text);
      if (text.isNotEmpty) return _shorten(text, 90);
    }
    return '';
  }

  ConversationSummary get summary => ConversationSummary(
    id: id,
    title: title,
    preview: preview,
    updatedAt: updatedAt,
    source: source,
  );

  static String _oneLine(String text) =>
      text
          .replaceAll(RegExp(r'[*_`#>]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static String _shorten(String text, int maxLength) =>
      text.length <= maxLength
          ? text
          : '${text.substring(0, maxLength - 1).trimRight()}…';

  @override
  List<Object?> get props => [id, updatedAt, messages, source];
}
