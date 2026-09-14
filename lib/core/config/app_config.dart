import 'package:flutter/foundation.dart';

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

  /// Usa los proveedores de depuración de App Check (localhost, emuladores y
  /// simuladores). Sus tokens deben registrarse en la consola de Firebase.
  static const appCheckDebug = bool.fromEnvironment(
    'NOVA_APP_CHECK_DEBUG',
    defaultValue: kDebugMode,
  );

  /// Clave de sitio de reCAPTCHA Enterprise para App Check en web.
  static const recaptchaSiteKey = String.fromEnvironment(
    'NOVA_RECAPTCHA_SITE_KEY',
  );

  /// Radio máximo para "lugares cerca de mí".
  static const nearbyRadiusMeters = 5000;

  /// Cantidad de lugares más cercanos que se devuelven.
  static const nearbyResultLimit = 5;

  /// Servidores de Overpass (OpenStreetMap), en orden de preferencia.
  static final overpassEndpoints = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.private.coffee/api/interpreter'),
    Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
  ];

  static const systemPrompt =
      'Eres NOVA, un asistente móvil inteligente creado con Flutter. '
      'Responde en el idioma del usuario, de forma clara, breve y amable. '
      'Cuando el usuario pida lugares cercanos (restaurantes, cafeterías, '
      'farmacias, bancos, etc.) usa la función buscarLugaresCercanos: se usa '
      'su ubicación actual y un radio máximo de 5 km. Nunca inventes lugares; '
      'menciona solo los que devuelve la función, del más cercano al más '
      'lejano y con su distancia. Si la función devuelve un error, explícalo y '
      'di cómo resolverlo. Si te piden algo que todavía no puedes ejecutar '
      '(recordatorios, cámara o documentos), explica que esa capacidad llegará '
      'en próximas versiones de NOVA.';
}

/// Origen de las respuestas de la IA.
enum AiMode {
  /// Gemini a través de Firebase AI Logic.
  firebase,

  /// Respuestas simuladas mientras Firebase no está configurado.
  demo,
}
