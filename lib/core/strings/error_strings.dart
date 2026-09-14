/// Mensajes de error que ve la persona, agrupados por origen.
abstract final class ErrorStrings {
  // IA.
  static const aiNoAccess =
      'NOVA no tiene acceso a la IA en este momento. Revisa la configuración '
      'de Firebase.';
  static const aiUnavailable =
      'NOVA no pudo responder. Revisa tu conexión e inténtalo de nuevo.';
  static const aiNoReply = 'No pude generar una respuesta.';

  // Voz.
  static const speechGeneric = 'No pude escucharte.';
  static const speechNoMicrophone =
      'No puedo usar el micrófono. Revisa que NOVA tenga permiso para grabar '
      'audio.';
  static const speechCouldNotActivate =
      'No pude activar el reconocimiento de voz. Inténtalo otra vez.';
  static const speechCouldNotStart = 'No pude empezar a escucharte.';
  static const speechNoSpanish =
      'Tu teléfono no tiene el reconocimiento de voz en español. Descárgalo '
      'en Ajustes › Google › Voz › Reconocimiento sin conexión.';
  static const speechPermission =
      'NOVA necesita permiso para usar el micrófono.';
  static const speechNeedsInternet =
      'El reconocimiento de voz necesita conexión a internet.';
  static const speechNotUnderstood = 'No pude entenderte bien.';

  // Ubicación.
  static const locationDisabled =
      'La ubicación del dispositivo está desactivada. Actívala e inténtalo de '
      'nuevo.';
  static const locationDenied = 'No diste permiso para usar tu ubicación.';
  static const locationBlocked =
      'El permiso de ubicación está bloqueado. Actívalo en los ajustes.';
  static const locationUnavailable = 'No se pudo obtener tu ubicación.';

  // Lugares.
  static const placesUnavailable =
      'No se pudo consultar el servicio de lugares. Inténtalo de nuevo en '
      'unos minutos.';
}
