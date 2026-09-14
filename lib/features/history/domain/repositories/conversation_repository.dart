import '../entities/conversation.dart';

/// Historial de conversaciones guardado en el dispositivo.
abstract interface class ConversationRepository {
  /// De la más reciente a la más antigua.
  Future<List<ConversationSummary>> recent();

  /// La conversación completa, o `null` si ya no existe.
  Future<Conversation?> load(String id);

  /// Guarda o actualiza la conversación y la pone primera en la lista.
  /// Una conversación sin mensajes de la persona no se guarda.
  Future<void> save(Conversation conversation);

  Future<void> delete(String id);

  /// Avisa cada vez que cambia el historial.
  Stream<void> get changes;
}
