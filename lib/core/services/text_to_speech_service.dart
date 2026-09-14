import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lee texto en voz alta con la voz del sistema.
abstract interface class TextToSpeechService {
  /// Lee [text] y termina cuando acaba de hablar o se llama a [stop].
  Future<void> speak(String text);

  Future<void> stop();
}

class FlutterTtsService implements TextToSpeechService {
  FlutterTtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  /// Variantes de español en orden de preferencia.
  static const _languages = ['es-US', 'es-MX', 'es-ES'];

  final FlutterTts _tts;
  Future<void>? _configured;

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await (_configured ??= _configure());
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> _configure() async {
    await _tts.awaitSpeakCompletion(true);
    try {
      for (final language in _languages) {
        if (await _tts.isLanguageAvailable(language) == true) {
          await _tts.setLanguage(language);
          break;
        }
      }
    } catch (error) {
      debugPrint('No se pudo elegir la voz en español: $error');
    }
    try {
      // En Android e iOS 0.5 es la velocidad normal; en web es 1.
      await _tts.setSpeechRate(kIsWeb ? 1 : 0.5);
    } catch (error) {
      debugPrint('No se pudo ajustar la velocidad de la voz: $error');
    }
  }
}
