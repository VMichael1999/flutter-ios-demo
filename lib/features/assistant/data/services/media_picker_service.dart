import 'package:image_picker/image_picker.dart';

import '../../domain/entities/chat_attachment.dart';

enum MediaSource { camera, gallery }

abstract interface class MediaPickerService {
  /// Imagen elegida por el usuario, o `null` si cancela.
  Future<ChatAttachment?> pickImage(MediaSource source);
}

/// Usa la cámara o la galería del sistema. En Android no requiere el permiso
/// CAMERA porque la foto la toma la app de cámara del dispositivo.
class ImagePickerMediaService implements MediaPickerService {
  ImagePickerMediaService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Suficiente para leer letreros y facturas sin enviar fotos enormes.
  static const maxDimension = 1600.0;
  static const imageQuality = 85;

  final ImagePicker _picker;

  @override
  Future<ChatAttachment?> pickImage(MediaSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        MediaSource.camera => ImageSource.camera,
        MediaSource.gallery => ImageSource.gallery,
      },
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: imageQuality,
    );
    if (file == null) return null;

    return ChatAttachment(
      bytes: await file.readAsBytes(),
      mimeType: file.mimeType ?? imageMimeTypeFor(file.name),
      name: file.name,
    );
  }
}

/// Tipo MIME a partir de la extensión, para plataformas que no lo informan.
String imageMimeTypeFor(String fileName) {
  final fileExtension = fileName.split('.').last.toLowerCase();
  return switch (fileExtension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };
}
