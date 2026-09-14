import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../errors/failures.dart';

/// Lo que se va reconociendo mientras la persona habla.
class SpeechUpdate {
  const SpeechUpdate(this.text, {this.isFinal = false});

  final String text;
  final bool isFinal;
}

/// Convierte la voz en texto con el reconocedor del sistema.
abstract interface class SpeechService {
  /// Escucha una frase. Emite el texto reconocido hasta el momento y termina
  /// cuando la persona deja de hablar o se llama a [stop]. Si no hay permiso
  /// o el reconocedor falla, emite un [SpeechFailure].
  Stream<SpeechUpdate> listen();

  /// Deja de escuchar y entrega lo reconocido hasta ahora.
  Future<void> stop();

  /// Deja de escuchar descartando lo reconocido.
  Future<void> cancel();
}

class SpeechToTextService implements SpeechService {
  SpeechToTextService([SpeechToText? speech])
      : _speech = speech ?? SpeechToText();

  /// Silencio tras el cual se da la frase por terminada.
  static const pauseFor = Duration(seconds: 3);
  static const listenFor = Duration(minutes: 1);

  /// Si el reconocedor no avisa que terminó, se cierra igual tras este tiempo.
  static const _doneFallback = Duration(seconds: 3);

  final SpeechToText _speech;
  StreamController<SpeechUpdate>? _session;
  String? _localeId;

  @override
  Stream<SpeechUpdate> listen() {
    final previous = _session;
    if (previous != null) _complete(previous);

    late final StreamController<SpeechUpdate> session;
    session = StreamController<SpeechUpdate>(
      onListen: () => _start(session),
      onCancel: () async {
        if (identical(_session, session)) {
          _session = null;
          await _speech.cancel();
        }
      },
    );
    _session = session;
    return session.stream;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    final session = _session;
    _session = null;
    if (session != null && !session.isClosed) await session.close();
    await _speech.cancel();
  }

  Future<void> _start(StreamController<SpeechUpdate> session) async {
    if (!await _initialize()) {
      _fail(
        session,
        const SpeechFailure(
          'No puedo usar el micrófono. Revisa que NOVA tenga permiso para '
          'grabar audio.',
        ),
      );
      return;
    }
    if (!identical(_session, session)) return;

    try {
      await _speech.listen(
        onResult: (result) => _onResult(session, result),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          listenMode: ListenMode.dictation,
          pauseFor: pauseFor,
          listenFor: listenFor,
          localeId: _localeId,
        ),
      );
    } catch (error) {
      debugPrint('No se pudo empezar a escuchar: $error');
      _fail(session, const SpeechFailure('No pude empezar a escucharte.'));
    }
  }

  Future<bool> _initialize() async {
    if (_speech.isAvailable) return true;
    try {
      final ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (ready) _localeId ??= await _spanishLocale();
      return ready;
    } catch (error) {
      debugPrint('Reconocimiento de voz no disponible: $error');
      return false;
    }
  }

  /// Prefiere el español del teléfono; si no, cualquier variante de español.
  Future<String?> _spanishLocale() async {
    try {
      final system = await _speech.systemLocale();
      if (system != null && _isSpanish(system.localeId)) {
        return system.localeId;
      }
      final locales = await _speech.locales();
      for (final locale in locales) {
        if (_isSpanish(locale.localeId)) return locale.localeId;
      }
    } catch (error) {
      debugPrint('No se pudo elegir el idioma de voz: $error');
    }
    return null;
  }

  static bool _isSpanish(String localeId) =>
      localeId.toLowerCase().startsWith('es');

  void _onResult(
    StreamController<SpeechUpdate> session,
    SpeechRecognitionResult result,
  ) {
    if (session.isClosed) return;
    session.add(
      SpeechUpdate(result.recognizedWords, isFinal: result.finalResult),
    );
    if (result.finalResult) _complete(session);
  }

  void _onStatus(String status) {
    final session = _session;
    if (session == null) return;
    if (status == SpeechToText.doneStatus) {
      _complete(session);
    } else if (status == SpeechToText.notListeningStatus) {
      Timer(_doneFallback, () => _complete(session));
    }
  }

  void _onError(SpeechRecognitionError error) {
    final session = _session;
    if (session == null || !error.permanent) return;
    switch (error.errorMsg) {
      // No se escuchó nada: la frase termina vacía, no es un fallo.
      case 'error_no_match' || 'error_speech_timeout' || 'no-speech':
        _complete(session);
      // Android usa "error_…"; el navegador, los nombres de Web Speech API.
      case 'error_permission' ||
            'error_insufficient_permissions' ||
            'not-allowed' ||
            'service-not-allowed' ||
            'audio-capture':
        _fail(
          session,
          const SpeechFailure(
            'NOVA necesita permiso para usar el micrófono.',
          ),
        );
      case 'error_network' ||
            'error_network_timeout' ||
            'error_server' ||
            'network':
        _fail(
          session,
          const SpeechFailure(
            'El reconocimiento de voz necesita conexión a internet.',
          ),
        );
      default:
        _fail(session, const SpeechFailure('No pude entenderte bien.'));
    }
  }

  void _complete(StreamController<SpeechUpdate> session) {
    if (identical(_session, session)) _session = null;
    if (!session.isClosed) session.close();
  }

  void _fail(StreamController<SpeechUpdate> session, SpeechFailure failure) {
    if (!session.isClosed) session.addError(failure);
    _complete(session);
  }
}
