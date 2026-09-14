import 'package:equatable/equatable.dart';

import '../../../../core/utils/geo.dart';
import '../../../places/domain/entities/place.dart';
import 'chat_attachment.dart';

enum ChatRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
    this.places = const [],
    this.searchCenter,
    this.attachment,
    this.hadImage = false,
  });

  const ChatMessage.user({
    required String id,
    required String text,
    ChatAttachment? attachment,
  }) : this(id: id, role: ChatRole.user, text: text, attachment: attachment);

  const ChatMessage.assistant({
    required String id,
    String text = '',
    bool isStreaming = false,
    List<Place> places = const [],
    GeoPoint? searchCenter,
  }) : this(
         id: id,
         role: ChatRole.assistant,
         text: text,
         isStreaming: isStreaming,
         places: places,
         searchCenter: searchCenter,
       );

  final String id;
  final ChatRole role;
  final String text;

  /// `true` mientras la IA sigue generando este mensaje.
  final bool isStreaming;

  /// Lugares encontrados por NOVA para esta respuesta.
  final List<Place> places;

  /// Ubicación del usuario cuando se buscaron los [places].
  final GeoPoint? searchCenter;

  /// Imagen que el usuario envió con el mensaje.
  final ChatAttachment? attachment;

  /// El mensaje llevaba una imagen que no se guarda en el historial.
  final bool hadImage;

  bool get isUser => role == ChatRole.user;

  bool get isAssistant => role == ChatRole.assistant;

  bool get hasImage => attachment != null || hadImage;

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<Place>? places,
    GeoPoint? searchCenter,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      places: places ?? this.places,
      searchCenter: searchCenter ?? this.searchCenter,
      attachment: attachment,
      hadImage: hadImage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    text,
    isStreaming,
    places,
    searchCenter,
    attachment,
    hadImage,
  ];
}
