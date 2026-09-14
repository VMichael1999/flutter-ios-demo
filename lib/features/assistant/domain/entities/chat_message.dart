import 'package:equatable/equatable.dart';

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
  }) : this(
         id: id,
         role: ChatRole.assistant,
         text: text,
         isStreaming: isStreaming,
         places: places,
       );

  final String id;
  final ChatRole role;
  final String text;

  /// `true` mientras la IA sigue generando este mensaje.
  final bool isStreaming;

  /// Lugares encontrados por NOVA para esta respuesta.
  final List<Place> places;

  /// Imagen que el usuario envió con el mensaje.
  final ChatAttachment? attachment;

  /// El mensaje llevaba una imagen que no se guarda en el historial.
  final bool hadImage;

  bool get isUser => role == ChatRole.user;

  bool get isAssistant => role == ChatRole.assistant;

  bool get hasImage => attachment != null || hadImage;

  ChatMessage copyWith({String? text, bool? isStreaming, List<Place>? places}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      places: places ?? this.places,
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
    attachment,
    hadImage,
  ];
}
