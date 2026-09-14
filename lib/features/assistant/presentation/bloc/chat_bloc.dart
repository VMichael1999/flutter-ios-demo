import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/strings/strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../history/domain/entities/conversation.dart';
import '../../../history/domain/repositories/conversation_repository.dart';
import '../../domain/entities/ai_reply_chunk.dart';
import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/reset_conversation.dart';
import '../../domain/usecases/restore_conversation.dart';
import '../../domain/usecases/send_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required SendMessage sendMessage,
    required ResetConversation resetConversation,
    RestoreConversation? restoreConversation,
    ConversationRepository? conversations,
    DateTime Function() clock = DateTime.now,
  }) : _sendMessage = sendMessage,
       _resetConversation = resetConversation,
       _restoreConversation = restoreConversation,
       _conversations = conversations,
       _clock = clock,
       super(const ChatState()) {
    on<ChatMessageSent>(_onMessageSent);
    on<ChatGenerationStopped>(_onGenerationStopped);
    on<ChatCleared>(_onCleared);
    on<ChatConversationOpened>(_onConversationOpened);
    on<_ChatChunkReceived>(_onChunkReceived);
    on<_ChatReplyCompleted>(_onReplyCompleted);
    on<_ChatReplyFailed>(_onReplyFailed);
  }

  final SendMessage _sendMessage;
  final ResetConversation _resetConversation;
  final RestoreConversation? _restoreConversation;

  /// Sin repositorio la conversación no se guarda en el historial.
  final ConversationRepository? _conversations;
  final DateTime Function() _clock;

  StreamSubscription<AiReplyChunk>? _replySubscription;
  int _messageCount = 0;

  /// Conversación del historial que se está escribiendo.
  String? _conversationId;

  String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_messageCount++}';

  void _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) {
    final text = event.text.trim();
    final attachment = event.attachment;
    if ((text.isEmpty && attachment == null) || state.isStreaming) return;

    _conversationId ??= _nextId();
    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage.user(id: _nextId(), text: text, attachment: attachment),
          ChatMessage.assistant(id: _nextId(), isStreaming: true),
        ],
        status: ChatStatus.streaming,
      ),
    );

    // Una foto sin texto también es una pregunta válida.
    final prompt = text.isEmpty ? AiPrompts.defaultImagePrompt : text;
    _replySubscription = _sendMessage(prompt, attachment: attachment).listen(
      (chunk) => add(_ChatChunkReceived(chunk)),
      onError:
          (Object error) => add(
            _ChatReplyFailed(
              error is AiFailure ? error.message : ErrorStrings.aiNoReply,
            ),
          ),
      onDone: () => add(const _ChatReplyCompleted()),
      cancelOnError: true,
    );
  }

  void _onChunkReceived(_ChatChunkReceived event, Emitter<ChatState> emit) {
    if (!state.isStreaming) return;
    emit(
      state.copyWith(
        messages: _updateLastAssistant(
          (message) => switch (event.chunk) {
            AiTextChunk(:final text) => message.copyWith(
              text: message.text + text,
            ),
            AiPlacesChunk(:final places, :final center) => message.copyWith(
              places: places,
              searchCenter: center,
            ),
          },
        ),
      ),
    );
  }

  void _onReplyCompleted(_ChatReplyCompleted event, Emitter<ChatState> emit) {
    _replySubscription = null;
    if (state.isStreaming) _finishReply(emit);
  }

  Future<void> _onGenerationStopped(
    ChatGenerationStopped event,
    Emitter<ChatState> emit,
  ) async {
    await _cancelReply();
    if (state.isStreaming) _finishReply(emit);
  }

  void _onReplyFailed(_ChatReplyFailed event, Emitter<ChatState> emit) {
    _replySubscription = null;
    final messages = [...state.messages];
    // Si la IA falló antes de escribir nada, la burbuja vacía no aporta.
    if (messages.isNotEmpty &&
        messages.last.isAssistant &&
        messages.last.text.isEmpty &&
        messages.last.places.isEmpty) {
      messages.removeLast();
    }
    emit(
      ChatState(
        messages: [
          for (final message in messages)
            message.isStreaming
                ? message.copyWith(isStreaming: false)
                : message,
        ],
        status: ChatStatus.failure,
        errorMessage: event.message,
      ),
    );
    _saveConversation();
  }

  /// Empieza una conversación nueva; la anterior queda en el historial.
  Future<void> _onCleared(ChatCleared event, Emitter<ChatState> emit) async {
    await _cancelReply();
    _resetConversation();
    _conversationId = null;
    emit(const ChatState());
  }

  Future<void> _onConversationOpened(
    ChatConversationOpened event,
    Emitter<ChatState> emit,
  ) async {
    final conversation = await _conversations?.load(event.id);
    if (conversation == null) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: HistoryStrings.notFound,
        ),
      );
      return;
    }
    await _cancelReply();
    _conversationId = conversation.id;
    // Gemini retoma el contexto: se puede seguir la conversación donde quedó.
    _restoreConversation?.call(conversation.messages);
    emit(ChatState(messages: conversation.messages));
  }

  void _finishReply(Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        messages: _updateLastAssistant(
          (message) => message.copyWith(isStreaming: false),
        ),
        status: ChatStatus.idle,
      ),
    );
    _saveConversation();
  }

  void _saveConversation() {
    final conversations = _conversations;
    final id = _conversationId;
    if (conversations == null || id == null) return;

    unawaited(
      conversations
          .save(
            Conversation(id: id, updatedAt: _clock(), messages: state.messages),
          )
          .catchError((Object error) {
            debugPrint('No se pudo guardar la conversación: $error');
          }),
    );
  }

  List<ChatMessage> _updateLastAssistant(
    ChatMessage Function(ChatMessage message) update,
  ) {
    final messages = [...state.messages];
    final index = messages.lastIndexWhere((message) => message.isAssistant);
    if (index != -1) messages[index] = update(messages[index]);
    return messages;
  }

  Future<void> _cancelReply() async {
    await _replySubscription?.cancel();
    _replySubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelReply();
    return super.close();
  }
}
