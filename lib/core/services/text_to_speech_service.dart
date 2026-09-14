import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lee texto en voz alta con la voz del sistema.
abstract interface class TextToSpeechService {
  /// Lee [text] y termina cuando acaba de hablar o se llama a [stop].
  /// Lanza una excepción si la voz del sistema no pudo leerlo.
  Future<void> speak(String text);

  Future<void> stop();
}

class FlutterTtsService implements TextToSpeechService {
  FlutterTtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts
      ..setStartHandler(() => debugPrint('Voz: empezó a leer'))
      ..setCompletionHandler(() => debugPrint('Voz: terminó de leer'))
      ..setErrorHandler((message) => debugPrint('Voz: error al leer $message'));
  }

  /// Variantes de español en orden de preferencia.
  static const _languages = ['es-US', 'es-MX', 'es-ES'];

  /// Motor de Google: casi siempre trae voces en español.
  static const _googleEngine = 'com.google.android.tts';

  final FlutterTts _tts;
  Future<void>? _configured;

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await (_configured ??= _configure());
    final result = await _tts.speak(text);
    debugPrint('Voz: lectura en voz alta → $result');
    // En Android e iOS 1 significa que la voz aceptó el texto.
    if (!kIsWeb && result != 1) {
      throw Exception(
        'La voz del teléfono no pudo leer la respuesta ($result)',
      );
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> _configure() async {
    await _tts.awaitSpeakCompletion(true);
    final hasSpanish = await _chooseSpanish();
    if (!hasSpanish &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      // Algunos motores de fábrica no traen español: se prueba el de Google.
      try {
        final engines = await _tts.getEngines;
        if (engines is List && engines.contains(_googleEngine)) {
          await _tts.setEngine(_googleEngine);
          debugPrint('Voz: se usa el motor de Google');
          await _chooseSpanish();
        }
      } catch (error) {
        debugPrint('Voz: no se pudo cambiar de motor: $error');
      }
    }
    try {
      await _tts.setVolume(1);
      // En Android e iOS 0.5 es la velocidad normal; en web es 1.
      await _tts.setSpeechRate(kIsWeb ? 1 : 0.5);
    } catch (error) {
      debugPrint('Voz: no se pudo ajustar volumen o velocidad: $error');
    }
  }

  Future<bool> _chooseSpanish() async {
    try {
      for (final language in _languages) {
        if (await _tts.isLanguageAvailable(language) == true) {
          await _tts.setLanguage(language);
          debugPrint('Voz: lee en $language');
          return true;
        }
      }
      debugPrint('Voz: este motor no tiene voz en español');
    } catch (error) {
      debugPrint('Voz: no se pudo elegir la voz en español: $error');
    }
    return false;
  }
}
