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
