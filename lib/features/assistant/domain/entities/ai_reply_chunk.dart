import 'package:equatable/equatable.dart';

import '../../../places/domain/entities/place.dart';

/// Fragmento de una respuesta de la IA.
sealed class AiReplyChunk extends Equatable {
  const AiReplyChunk();
}

final class AiTextChunk extends AiReplyChunk {
  const AiTextChunk(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Lugares que NOVA encontró al ejecutar una herramienta.
final class AiPlacesChunk extends AiReplyChunk {
  const AiPlacesChunk(this.places);

  final List<Place> places;

  @override
  List<Object?> get props => [places];
}
