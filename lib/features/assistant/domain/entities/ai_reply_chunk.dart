import 'package:equatable/equatable.dart';

import '../../../../core/utils/geo.dart';
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
  const AiPlacesChunk(this.places, {this.center});

  final List<Place> places;

  /// Desde dónde se buscó (la ubicación del usuario), para marcarla en el
  /// mapa.
  final GeoPoint? center;

  @override
  List<Object?> get props => [places, center];
}
