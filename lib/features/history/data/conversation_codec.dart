import '../../../core/utils/geo.dart';
import '../../assistant/domain/entities/chat_message.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/entities/place_category.dart';
import '../domain/entities/conversation.dart';

// Conversión a JSON del historial. Las imágenes no se guardan (ocuparían
// demasiado); solo queda constancia de que el mensaje tenía una.

Map<String, Object?> conversationToJson(Conversation conversation) => {
  'id': conversation.id,
  'updatedAt': conversation.updatedAt.toIso8601String(),
  'source': conversation.source.name,
  'messages': [
    for (final message in conversation.messages) _messageToJson(message),
  ],
};

Conversation conversationFromJson(Map<String, Object?> json) => Conversation(
  id: json['id']! as String,
  updatedAt: DateTime.parse(json['updatedAt']! as String),
  source: _sourceFrom(json['source']),
  messages: [
    for (final message in json['messages'] as List? ?? const [])
      _messageFromJson(_asMap(message)),
  ],
);

Map<String, Object?> summaryToJson(ConversationSummary summary) => {
  'id': summary.id,
  'title': summary.title,
  'preview': summary.preview,
  'updatedAt': summary.updatedAt.toIso8601String(),
  'source': summary.source.name,
};

ConversationSummary summaryFromJson(Map<String, Object?> json) =>
    ConversationSummary(
      id: json['id']! as String,
      title: json['title'] as String? ?? 'Conversación',
      preview: json['preview'] as String? ?? '',
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      source: _sourceFrom(json['source']),
    );

Map<String, Object?> _messageToJson(ChatMessage message) => {
  'id': message.id,
  'role': message.role.name,
  'text': message.text,
  if (message.hasImage) 'hadImage': true,
  if (message.places.isNotEmpty)
    'places': [for (final place in message.places) _placeToJson(place)],
};

ChatMessage _messageFromJson(Map<String, Object?> json) => ChatMessage(
  id: json['id']! as String,
  role: ChatRole.values.asNameMap()[json['role']] ?? ChatRole.assistant,
  text: json['text'] as String? ?? '',
  hadImage: json['hadImage'] == true,
  places: [
    for (final place in json['places'] as List? ?? const [])
      if (_placeFromJson(_asMap(place)) case final parsed?) parsed,
  ],
);

Map<String, Object?> _placeToJson(Place place) => {
  'id': place.id,
  'name': place.name,
  'category': place.category.name,
  'lat': place.location.latitude,
  'lon': place.location.longitude,
  'distance': place.distanceMeters,
  if (place.address != null) 'address': place.address,
};

Place? _placeFromJson(Map<String, Object?> json) {
  final category = PlaceCategory.fromName(json['category'] as String?);
  if (category == null) return null;
  return Place(
    id: json['id']! as String,
    name: json['name']! as String,
    category: category,
    location: GeoPoint(
      (json['lat']! as num).toDouble(),
      (json['lon']! as num).toDouble(),
    ),
    distanceMeters: (json['distance']! as num).toDouble(),
    address: json['address'] as String?,
  );
}

ConversationSource _sourceFrom(Object? name) =>
    ConversationSource.values.asNameMap()[name] ?? ConversationSource.chat;

Map<String, Object?> _asMap(Object? value) =>
    (value! as Map).cast<String, Object?>();
