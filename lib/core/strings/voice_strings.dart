/// Textos del modo voz.
abstract final class VoiceStrings {
  static const title = 'Habla con NOVA';

  static const idle = 'Toca el micrófono y habla';
  static const listening = 'Te escucho… habla ahora';
  static const thinking = 'Pensando…';
  static const speaking = 'Hablando · toca para interrumpir';

  static const speak = 'Hablar';
  static const finishSpeaking = 'Terminar de hablar';
  static const interrupt = 'Interrumpir';

  static const genericFailure = 'Algo salió mal. Inténtalo otra vez.';
  static const heardNothing =
      'No te escuché. Toca el micrófono y vuelve a intentarlo.';
  static const readAloudFailed =
      'No pude leer la respuesta en voz alta. Revisa el volumen del teléfono; '
      'la respuesta está escrita abajo.';
}
