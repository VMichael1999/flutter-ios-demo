/// Textos del historial de conversaciones.
abstract final class HistoryStrings {
  static const hint =
      'Toca una conversación para seguirla. Desliza a la izquierda para '
      'borrarla.';
  static const emptyTitle = 'Aún no hay conversaciones';
  static const emptySubtitle =
      'Lo que hables con NOVA, escribiendo o por voz, se guardará aquí.';
  static const deleted = 'Conversación eliminada';
  static const notFound = 'No encontré esa conversación en el historial.';

  static const byVoice = 'Por voz';
  static const byChat = 'Por chat';

  // Títulos cuando la conversación no tiene una pregunta con texto.
  static const photoTitle = 'Foto';
  static const untitled = 'Conversación';
  static const untitledVoice = 'Conversación por voz';
}
