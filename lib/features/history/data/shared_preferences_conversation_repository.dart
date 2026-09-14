import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/conversation.dart';
import '../domain/repositories/conversation_repository.dart';
import 'conversation_codec.dart';

/// Guarda el historial en el dispositivo (Android, iOS y web): un índice con
/// los resúmenes y cada conversación en su propia clave, para listar rápido
/// sin leer todos los mensajes.
class SharedPreferencesConversationRepository
    implements ConversationRepository {
  SharedPreferencesConversationRepository({
    Future<SharedPreferences>? preferences,
    this.maxConversations = 50,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _indexKey = 'nova.history.index';

  /// El historial se ordena por fecha y no por orden de guardado: al deshacer
  /// un borrado, la conversación vuelve a su lugar en vez de saltar arriba.
  static int _newestFirst(ConversationSummary a, ConversationSummary b) =>
      b.updatedAt.compareTo(a.updatedAt);
  static String _conversationKey(String id) => 'nova.history.conversation.$id';

  final Future<SharedPreferences> _preferences;

  /// Las más antiguas se borran al superar este número.
  final int maxConversations;

  final _changes = StreamController<void>.broadcast();

  /// Las escrituras van de una en una para no pisarse el índice.
  Future<void> _writes = Future.value();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<ConversationSummary>> recent() async {
    await _writes;
    return _readIndex(await _preferences);
  }

  @override
  Future<Conversation?> load(String id) async {
    await _writes;
    final raw = (await _preferences).getString(_conversationKey(id));
    if (raw == null) return null;
    try {
      return conversationFromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (error) {
      debugPrint('Conversación $id dañada, se ignora: $error');
      return null;
    }
  }

  @override
  Future<void> save(Conversation conversation) => _write((preferences) async {
    final messages = [
      for (final message in conversation.messages)
        if (!message.isStreaming &&
            (message.text.trim().isNotEmpty ||
                message.hasImage ||
                message.places.isNotEmpty))
          message,
    ];
    if (!messages.any((message) => message.isUser)) return;

    final saved = Conversation(
      id: conversation.id,
      updatedAt: conversation.updatedAt,
      messages: messages,
      source: conversation.source,
    );
    final index =
        _readIndex(preferences)
          ..removeWhere((summary) => summary.id == saved.id)
          ..add(saved.summary)
          ..sort(_newestFirst);

    await preferences.setString(
      _conversationKey(saved.id),
      jsonEncode(conversationToJson(saved)),
    );
    for (final old in index.skip(maxConversations)) {
      await preferences.remove(_conversationKey(old.id));
    }
    await _writeIndex(preferences, index.take(maxConversations));
  });

  @override
  Future<void> delete(String id) => _write((preferences) async {
    final index = _readIndex(preferences)
      ..removeWhere((summary) => summary.id == id);
    await preferences.remove(_conversationKey(id));
    await _writeIndex(preferences, index);
  });

  Future<void> _write(
    Future<void> Function(SharedPreferences preferences) change,
  ) {
    final write = _writes.then((_) async {
      await change(await _preferences);
      _changes.add(null);
    });
    // Un fallo no bloquea las escrituras siguientes.
    _writes = write.catchError((Object error) {
      debugPrint('No se pudo guardar el historial: $error');
    });
    return write;
  }

  List<ConversationSummary> _readIndex(SharedPreferences preferences) {
    final raw = preferences.getString(_indexKey);
    if (raw == null) return [];
    try {
      return [
        for (final item in jsonDecode(raw) as List)
          summaryFromJson((item as Map).cast<String, Object?>()),
      ]..sort(_newestFirst);
    } catch (error) {
      debugPrint('Índice del historial dañado, se reinicia: $error');
      return [];
    }
  }

  Future<void> _writeIndex(
    SharedPreferences preferences,
    Iterable<ConversationSummary> index,
  ) => preferences.setString(
    _indexKey,
    jsonEncode([for (final summary in index) summaryToJson(summary)]),
  );
}
