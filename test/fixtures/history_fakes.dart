import 'dart:async';

import 'package:nova_ai/features/history/domain/entities/conversation.dart';
import 'package:nova_ai/features/history/domain/repositories/conversation_repository.dart';

/// Historial en memoria para tests.
class InMemoryConversationRepository implements ConversationRepository {
  InMemoryConversationRepository([Iterable<Conversation> initial = const []]) {
    for (final conversation in initial) {
      saved[conversation.id] = conversation;
    }
  }

  final saved = <String, Conversation>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<ConversationSummary>> recent() async {
    final conversations =
        saved.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return [for (final conversation in conversations) conversation.summary];
  }

  @override
  Future<Conversation?> load(String id) async => saved[id];

  @override
  Future<void> save(Conversation conversation) async {
    if (!conversation.messages.any((message) => message.isUser)) return;
    saved[conversation.id] = conversation;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    saved.remove(id);
    _changes.add(null);
  }
}
