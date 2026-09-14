abstract interface class AiRemoteDataSource {
  /// Emite la respuesta del modelo por fragmentos de texto.
  Stream<String> streamReply(String message);

  /// Descarta la sesión de chat y su historial.
  void reset();
}
