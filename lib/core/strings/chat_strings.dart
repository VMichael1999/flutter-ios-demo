/// Textos del chat: pantalla, barra de escritura y burbujas.
abstract final class ChatStrings {
  static const newConversation = 'Nueva conversación';

  static const emptyTitle = 'Pregúntame lo que quieras';
  static const emptySubtitle =
      'Escribe, dicta con el micrófono o mándame una foto.';
  static const suggestions = [
    '¿Qué puedes hacer?',
    '¿Qué hay cerca de mí?',
    'Ayúdame a organizar mi semana',
  ];

  static const demoBanner =
      'Modo demo: Firebase aún no está configurado y las respuestas son '
      'simuladas.';

  // Imágenes.
  static const addImageTitle = 'Añadir una imagen';
  static const takePhoto = 'Tomar foto';
  static const chooseFromGallery = 'Elegir de la galería';
  static const cameraError = 'No se pudo abrir la cámara.';
  static const galleryError = 'No se pudo abrir la galería.';
  static const attachImage = 'Adjuntar imagen';
  static const imageToSend = 'Imagen para enviar';
  static const removeImage = 'Quitar imagen';
  static const imageSent = 'Imagen enviada';

  // Barra de escritura.
  static const inputHint = 'Escribe o dicta a NOVA…';
  static const inputHintWithImage = 'Pregunta sobre la imagen…';
  static const listeningHint = 'Te escucho…';
  static const dictate = 'Dictar';
  static const stopDictation = 'Dejar de dictar';
  static const stop = 'Detener';

  static const thinking = 'NOVA está pensando…';
}
