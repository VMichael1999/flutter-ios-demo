part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// El usuario envía un mensaje, opcionalmente con una imagen.
final class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.text, {this.attachment});

  final String text;
  final ChatAttachment? attachment;

  @override
  List<Object?> get props => [text, attachment];
}

/// El usuario detiene la respuesta en curso.
final class ChatGenerationStopped extends ChatEvent {
  const ChatGenerationStopped();
}

/// El usuario empieza una conversación nueva.
final class ChatCleared extends ChatEvent {
  const ChatCleared();
}

final class _ChatChunkReceived extends ChatEvent {
  const _ChatChunkReceived(this.chunk);

  final AiReplyChunk chunk;

  @override
  List<Object?> get props => [chunk];
}

final class _ChatReplyCompleted extends ChatEvent {
  const _ChatReplyCompleted();
}

final class _ChatReplyFailed extends ChatEvent {
  const _ChatReplyFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
