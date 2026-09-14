/// Configuración global de NOVA.
///
/// Los valores se pueden sobrescribir al compilar con `--dart-define`,
/// por ejemplo: `flutter run --dart-define=NOVA_ENV=qa`.
abstract final class AppConfig {
  static const appName = 'NOVA AI';

  /// Entorno de ejecución: `dev`, `qa` o `prod`.
  static const environment = String.fromEnvironment(
    'NOVA_ENV',
    defaultValue: 'dev',
  );

  /// Modelo de Gemini usado a través de Firebase AI Logic.
  static const geminiModel = String.fromEnvironment(
    'NOVA_GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );

  static const systemPrompt =
      'Eres NOVA, un asistente móvil inteligente creado con Flutter. '
      'Responde en el idioma del usuario, de forma clara, breve y amable. '
      'Si te piden algo que todavía no puedes ejecutar (recordatorios, mapas, '
      'cámara o documentos), explica que esa capacidad llegará en próximas '
      'versiones de NOVA.';
}

/// Origen de las respuestas de la IA.
enum AiMode {
  /// Gemini a través de Firebase AI Logic.
  firebase,

  /// Respuestas simuladas mientras Firebase no está configurado.
  demo,
}
