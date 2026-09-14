import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  const ChatMessage.user({required String id, required String text})
      : this(id: id, role: ChatRole.user, text: text);

  const ChatMessage.assistant({
    required String id,
    String text = '',
    bool isStreaming = false,
  }) : this(
          id: id,
          role: ChatRole.assistant,
          text: text,
          isStreaming: isStreaming,
        );

  final String id;
  final ChatRole role;
  final String text;

  /// `true` mientras la IA sigue generando este mensaje.
  final bool isStreaming;

  bool get isUser => role == ChatRole.user;

  bool get isAssistant => role == ChatRole.assistant;

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, role, text, isStreaming];
}
