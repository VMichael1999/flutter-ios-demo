/// Error de dominio al comunicarse con la IA.
///
/// [message] está pensado para mostrarse directamente al usuario.
class AiFailure implements Exception {
  const AiFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AiFailure: $message${cause == null ? '' : ' ($cause)'}';
}

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

/// No se pudo obtener la ubicación del dispositivo.
class LocationFailure implements Exception {
  const LocationFailure(
    this.message, {
    this.reason = LocationFailureReason.unavailable,
    this.cause,
  });

  final String message;
  final LocationFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'LocationFailure(${reason.name}): $message';
}

/// Falló la búsqueda de lugares cercanos.
class PlacesFailure implements Exception {
  const PlacesFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'PlacesFailure: $message${cause == null ? '' : ' ($cause)'}';
}
