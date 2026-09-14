import 'package:flutter/foundation.dart';

import '../strings/app_strings.dart';

/// Configuración global de NOVA.
///
/// Los valores vienen de `.env` al compilar con
/// `flutter run --dart-define-from-file=.env` (ver `.env.example`). Cada uno
/// tiene un valor por defecto para que los tests y la CI funcionen sin `.env`.
abstract final class AppConfig {
  static const appName = AppStrings.appName;

  /// Identificador de la app en Android e iOS.
  static const appPackageName = 'com.vmichael1999.novaai';

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

  // Servicios externos. No son secretos: están en `.env` para poder cambiarlos
  // (por ejemplo, otro proveedor de mapas) sin tocar el código.

  /// Servidores de Overpass (OpenStreetMap), separados por comas y en orden
  /// de preferencia.
  static const _overpassEndpoints = String.fromEnvironment(
    'NOVA_OVERPASS_ENDPOINTS',
    defaultValue:
        'https://overpass-api.de/api/interpreter,'
        'https://overpass.kumi.systems/api/interpreter,'
        'https://maps.mail.ru/osm/tools/overpass/api/interpreter,'
        'https://overpass.private.coffee/api/interpreter',
  );

  static final overpassEndpoints = [
    for (final url in _overpassEndpoints.split(','))
      if (url.trim().isNotEmpty) Uri.parse(url.trim()),
  ];

  /// Plantilla de los mapas base; el mapa completa `{z}/{x}/{y}`.
  static const mapTileUrl = String.fromEnvironment(
    'NOVA_MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Ruta en Google Maps; la app le añade el destino.
  static const directionsUrl = String.fromEnvironment(
    'NOVA_DIRECTIONS_URL',
    defaultValue: 'https://www.google.com/maps/dir/',
  );

  /// Página del proyecto: el contacto que piden las políticas de uso de
  /// OpenStreetMap y Overpass.
  static const projectUrl = String.fromEnvironment(
    'NOVA_PROJECT_URL',
    defaultValue: 'https://github.com/VMichael1999/flutter-ios-demo',
  );

  /// Radio máximo para "lugares cerca de mí".
  static const nearbyRadiusMeters = 5000;

  /// Cantidad de lugares más cercanos que se devuelven.
  static const nearbyResultLimit = 5;
}

/// Origen de las respuestas de la IA.
enum AiMode {
  /// Gemini a través de Firebase AI Logic.
  firebase,

  /// Respuestas simuladas mientras Firebase no está configurado.
  demo,
}
