import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Archivo que el usuario adjunta a un mensaje (por ahora, imágenes).
class ChatAttachment extends Equatable {
  const ChatAttachment({
    required this.bytes,
    required this.mimeType,
    this.name,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? name;

  bool get isImage => mimeType.startsWith('image/');

  // Comparar byte a byte una foto de varios MB en cada estado sería costoso.
  @override
  List<Object?> get props => [
    name,
    mimeType,
    bytes.lengthInBytes,
    identityHashCode(bytes),
  ];
}
