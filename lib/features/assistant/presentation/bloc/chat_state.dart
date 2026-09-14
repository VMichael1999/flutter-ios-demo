part of 'chat_bloc.dart';

enum ChatStatus { idle, streaming, failure }

final class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final ChatStatus status;

  /// Solo tiene valor cuando [status] es [ChatStatus.failure].
  final String? errorMessage;

  bool get isStreaming => status == ChatStatus.streaming;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, status, errorMessage];
}
