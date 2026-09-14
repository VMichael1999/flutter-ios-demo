import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../errors/failures.dart';
import '../strings/error_strings.dart';

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

  /// Volumen de la voz mientras se escucha, de 0 a 1. Sirve para mostrar que
  /// el micrófono de verdad está captando algo.
  ValueListenable<double> get soundLevel;
}

class SpeechToTextService implements SpeechService {
  SpeechToTextService([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  /// Silencio tras el cual se da la frase por terminada.
  static const pauseFor = Duration(seconds: 3);
  static const listenFor = Duration(minutes: 1);

  /// Si el reconocedor no avisa que terminó, se cierra igual tras este tiempo.
  static const _doneFallback = Duration(seconds: 3);

  /// Si en este tiempo no empieza a escuchar, algo falló sin avisar.
  static const _startTimeout = Duration(seconds: 6);

  /// Máximo para averiguar el idioma antes de escuchar.
  static const _localeTimeout = Duration(seconds: 2);

  final SpeechToText _speech;
  final _soundLevel = ValueNotifier<double>(0);

  StreamController<SpeechUpdate>? _session;
  String? _localeId;
  bool _localeResolved = false;

  /// Cada intento de escuchar tiene un número: los avisos de un intento
  /// anterior (por ejemplo, antes de un reintento) se ignoran.
  int _attempt = 0;
  bool _isListening = false;
  bool _retried = false;
  Timer? _startWatchdog;
  Timer? _prepareWatchdog;

  @override
  ValueListenable<double> get soundLevel => _soundLevel;

  @override
  Stream<SpeechUpdate> listen() {
    final previous = _session;
    if (previous != null) _complete(previous);

    late final StreamController<SpeechUpdate> session;
    session = StreamController<SpeechUpdate>(
      onListen: () => _start(session),
      onCancel: () async {
        if (identical(_session, session)) {
          _finishSession();
          await _speech.cancel();
        }
      },
    );
    _session = session;
    _retried = false;
    return session.stream;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    final session = _session;
    _finishSession();
    if (session != null && !session.isClosed) await session.close();
    await _speech.cancel();
  }

  Future<void> _start(StreamController<SpeechUpdate> session) async {
    // Vigila también la preparación: si algo se cuelga antes de escuchar,
    // la persona recibe un aviso en vez de una pantalla quieta.
    final attempt = _attempt;
    _prepareWatchdog?.cancel();
    _prepareWatchdog = Timer(_startTimeout * 2, () {
      if (identical(_session, session) &&
          attempt == _attempt &&
          !_isListening) {
        debugPrint('Voz: la preparación del reconocedor no terminó');
        _fail(
          session,
          const SpeechFailure(ErrorStrings.speechCouldNotActivate),
        );
      }
    });
    if (!await _initialize()) {
      _fail(session, const SpeechFailure(ErrorStrings.speechNoMicrophone));
      return;
    }
    if (identical(_session, session)) await _listen(session);
  }

  Future<void> _listen(StreamController<SpeechUpdate> session) async {
    final attempt = ++_attempt;
    _isListening = false;
    _startWatchdog?.cancel();
    _startWatchdog = Timer(_startTimeout, () {
      if (attempt != _attempt || _isListening) return;
      debugPrint('Voz: el reconocedor no empezó a escuchar');
      _fail(session, const SpeechFailure(ErrorStrings.speechCouldNotActivate));
      _speech.cancel();
    });

    try {
      debugPrint('Voz: escuchando (idioma: ${_localeId ?? 'del teléfono'})');
      await _speech.listen(
        onResult: (result) => _onResult(session, result),
        onSoundLevelChange: _onSoundLevel,
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
      debugPrint('Voz: no se pudo empezar a escuchar: $error');
      _fail(session, const SpeechFailure(ErrorStrings.speechCouldNotStart));
    }
  }

  Future<bool> _initialize() async {
    if (_speech.isAvailable) return true;
    try {
      final ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );
      debugPrint('Voz: reconocedor disponible: $ready');
      if (ready && !_localeResolved) {
        // En Android 13 el plugin puede no responder nunca al pedir los
        // idiomas: sin este límite NOVA se quedaba en "Te escucho…" sin
        // empezar a escuchar.
        _localeId = await _spanishLocale().timeout(
          _localeTimeout,
          onTimeout: () {
            debugPrint('Voz: sin respuesta de idiomas, se usa el del teléfono');
            return null;
          },
        );
        _localeResolved = true;
      }
      return ready;
    } catch (error) {
      debugPrint('Voz: reconocimiento no disponible: $error');
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
      debugPrint('Voz: no se pudo elegir el idioma: $error');
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
    debugPrint(
      'Voz: oí "${result.recognizedWords}" (final: ${result.finalResult})',
    );
    session.add(
      SpeechUpdate(result.recognizedWords, isFinal: result.finalResult),
    );
    if (result.finalResult) _complete(session);
  }

  void _onSoundLevel(double level) {
    // Android entrega decibelios aproximadamente entre -2 y 10.
    _soundLevel.value = ((level + 2) / 12).clamp(0.0, 1.0);
  }

  void _onStatus(String status) {
    debugPrint('Voz: estado $status');
    final session = _session;
    if (session == null) return;
    final attempt = _attempt;
    if (status == SpeechToText.listeningStatus) {
      _isListening = true;
    } else if (status == SpeechToText.doneStatus) {
      if (_isListening) _complete(session);
    } else if (status == SpeechToText.notListeningStatus) {
      Timer(_doneFallback, () {
        if (attempt == _attempt) _complete(session);
      });
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('Voz: error ${error.errorMsg} (permanente: ${error.permanent})');
    final session = _session;
    if (session == null || !error.permanent) return;
    switch (error.errorMsg) {
      // No se escuchó nada: la frase termina vacía, no es un fallo.
      case 'error_no_match' || 'error_speech_timeout' || 'no-speech':
        _complete(session);
      case 'error_language_unavailable' || 'error_language_not_supported':
        if (!_retried && _localeId != null) {
          // El reconocedor no tiene esa variante de español: se prueba con el
          // idioma que tenga configurado el teléfono.
          _retried = true;
          _localeId = null;
          _retry(session);
        } else {
          _fail(session, const SpeechFailure(ErrorStrings.speechNoSpanish));
        }
      case 'error_client' || 'error_busy' || 'error_server_disconnected'
          when !_retried:
        _retried = true;
        _retry(session);
      // Android usa "error_…"; el navegador, los nombres de Web Speech API.
      case 'error_permission' ||
          'error_insufficient_permissions' ||
          'not-allowed' ||
          'service-not-allowed' ||
          'audio-capture':
        _fail(session, const SpeechFailure(ErrorStrings.speechPermission));
      case 'error_network' ||
          'error_network_timeout' ||
          'error_server' ||
          'network':
        _fail(session, const SpeechFailure(ErrorStrings.speechNeedsInternet));
      default:
        _fail(session, const SpeechFailure(ErrorStrings.speechNotUnderstood));
    }
  }

  void _retry(StreamController<SpeechUpdate> session) {
    debugPrint('Voz: reintentando');
    // Invalida los avisos del intento fallido mientras arranca el nuevo.
    _attempt++;
    Timer(const Duration(milliseconds: 300), () {
      if (identical(_session, session) && !session.isClosed) _listen(session);
    });
  }

  void _complete(StreamController<SpeechUpdate> session) {
    if (identical(_session, session)) _finishSession();
    if (!session.isClosed) session.close();
  }

  void _fail(StreamController<SpeechUpdate> session, SpeechFailure failure) {
    debugPrint('Voz: fallo "${failure.message}"');
    if (!session.isClosed) session.addError(failure);
    _complete(session);
  }

  void _finishSession() {
    _session = null;
    _attempt++;
    _isListening = false;
    _startWatchdog?.cancel();
    _prepareWatchdog?.cancel();
    _soundLevel.value = 0;
  }
}
