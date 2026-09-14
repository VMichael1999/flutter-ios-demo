import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/text_to_speech_service.dart';
import '../../../assistant/domain/entities/ai_reply_chunk.dart';
import '../../../assistant/domain/usecases/send_message.dart';
import '../../domain/speakable_text.dart';

part 'voice_state.dart';

/// Conversación por voz: escucha, pregunta a NOVA y lee la respuesta.
///
/// Con [continuous] NOVA vuelve a escuchar al terminar de hablar, como en una
/// llamada. Si la persona no dice nada, la conversación se pausa sola.
class VoiceConversationCubit extends Cubit<VoiceState> {
  VoiceConversationCubit({
    required SpeechService speech,
    required TextToSpeechService textToSpeech,
    required SendMessage sendMessage,
    this.continuous = true,
  })  : _speech = speech,
        _textToSpeech = textToSpeech,
        _sendMessage = sendMessage,
        super(const VoiceState());

  final SpeechService _speech;
  final TextToSpeechService _textToSpeech;
  final SendMessage _sendMessage;
  final bool continuous;

  StreamSubscription<SpeechUpdate>? _listening;
  StreamSubscription<AiReplyChunk>? _reply;

  /// Cambia en cada turno para ignorar lo que llegue de un turno interrumpido.
  int _turn = 0;

  /// Botón principal: empieza a escuchar, termina la frase o interrumpe.
  Future<void> toggle() async {
    switch (state.status) {
      case VoiceStatus.idle || VoiceStatus.failure:
        await startListening();
      case VoiceStatus.listening:
        await _speech.stop();
      case VoiceStatus.thinking || VoiceStatus.speaking:
        await interrupt();
    }
  }

  Future<void> startListening() async {
    await _stopEverything();
    final turn = ++_turn;
    _emit(const VoiceState(status: VoiceStatus.listening));

    var heard = '';
    _listening = _speech.listen().listen(
      (update) {
        if (turn != _turn) return;
        heard = update.text;
        _emit(state.copyWith(transcript: heard));
      },
      onError: (Object error) {
        if (turn != _turn) return;
        _listening = null;
        _emit(
          VoiceState(
            status: VoiceStatus.failure,
            errorMessage: error is SpeechFailure
                ? error.message
                : 'No pude escucharte.',
          ),
        );
      },
      onDone: () {
        if (turn != _turn) return;
        _listening = null;
        final question = heard.trim();
        if (question.isEmpty) {
          _emit(
            const VoiceState(
              status: VoiceStatus.failure,
              errorMessage: 'No te escuché. Toca el micrófono y vuelve a '
                  'intentarlo.',
            ),
          );
        } else {
          _ask(question, turn);
        }
      },
      cancelOnError: true,
    );
  }

  /// Detiene lo que esté pasando y deja la conversación en pausa.
  Future<void> interrupt() async {
    _turn++;
    await _stopEverything();
    _emit(state.copyWith(status: VoiceStatus.idle));
  }

  void _ask(String question, int turn) {
    _emit(VoiceState(status: VoiceStatus.thinking, transcript: question));
    final reply = StringBuffer();

    _reply = _sendMessage(question).listen(
      (chunk) {
        if (turn != _turn) return;
        if (chunk case AiTextChunk(:final text)) {
          reply.write(text);
          _emit(state.copyWith(reply: reply.toString()));
        }
      },
      onError: (Object error) {
        if (turn != _turn) return;
        _reply = null;
        _emit(
          state.copyWith(
            status: VoiceStatus.failure,
            errorMessage: error is AiFailure
                ? error.message
                : 'No pude generar una respuesta.',
          ),
        );
      },
      onDone: () {
        if (turn != _turn) return;
        _reply = null;
        _speak(reply.toString(), turn);
      },
      cancelOnError: true,
    );
  }

  Future<void> _speak(String reply, int turn) async {
    final spoken = speakableText(reply);
    if (spoken.isEmpty) {
      _emit(state.copyWith(status: VoiceStatus.idle));
      return;
    }

    _emit(state.copyWith(status: VoiceStatus.speaking));
    try {
      await _textToSpeech.speak(spoken);
    } catch (error) {
      debugPrint('No se pudo leer la respuesta: $error');
      if (turn == _turn) _emit(state.copyWith(status: VoiceStatus.idle));
      return;
    }

    if (turn != _turn || isClosed) return;
    if (continuous) {
      await startListening();
    } else {
      _emit(state.copyWith(status: VoiceStatus.idle));
    }
  }

  Future<void> _stopEverything() async {
    final wasSpeaking = state.status == VoiceStatus.speaking;
    await _listening?.cancel();
    _listening = null;
    await _reply?.cancel();
    _reply = null;
    if (wasSpeaking) await _textToSpeech.stop();
  }

  void _emit(VoiceState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    _turn++;
    await _listening?.cancel();
    await _reply?.cancel();
    try {
      await _textToSpeech.stop();
    } catch (error) {
      debugPrint('No se pudo detener la voz: $error');
    }
    return super.close();
  }
}
