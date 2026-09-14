/// Textos de la pantalla de inicio.
abstract final class HomeStrings {
  static const greetingMorning = 'Buenos días';
  static const greetingAfternoon = 'Buenas tardes';
  static const greetingNight = 'Buenas noches';

  /// "¿Qué hacemos *hoy*?": la palabra del medio va resaltada.
  static const headlineStart = '¿Qué hacemos ';
  static const headlineHighlight = 'hoy';
  static const headlineEnd = '?';

  static const promptHint = 'Pregúntale algo a NOVA…';
  static const recent = 'Recientes';
  static const seeAll = 'Ver todo';
  static const shortcuts = 'Atajos';

  static const voiceTitle = 'Voz';
  static const voiceCaption = 'Conversa con NOVA sin escribir';
  static const cameraTitle = 'Cámara';
  static const cameraCaption = 'Toma una foto o elige una';
  static const locationTitle = 'Ubicación';
  static const locationCaption = 'Lugares cerca de ti';
  static const documentTitle = 'Documento';
  static const documentCaption = 'Lee y resume un PDF';
  static const openChat = 'Abrir chat con NOVA';

  /// Borrador del atajo Ubicación: "Busca | cerca de mí".
  static const locationDraftPrefix = 'Busca ';
  static const locationDraftSuffix = ' cerca de mí';
}
