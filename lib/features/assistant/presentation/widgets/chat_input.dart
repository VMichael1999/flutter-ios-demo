import 'package:flutter/material.dart';

import '../../../../core/theme/motion.dart';
import '../../../../shared/widgets/entrance.dart';
import '../../domain/entities/chat_attachment.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    required this.onAttach,
    required this.onRemoveAttachment,
    this.attachment,
    this.focusNode,
    this.isListening = false,
    this.onMicTap,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;

  /// Imagen lista para enviarse con el próximo mensaje.
  final ChatAttachment? attachment;

  /// Se está dictando: lo que dice la persona va apareciendo en el campo.
  final bool isListening;

  /// Empieza o termina el dictado. Si es null no se muestra el micrófono.
  final VoidCallback? onMicTap;

  @override
  Widget build(BuildContext context) {
    final attachment = this.attachment;
    final onMicTap = this.onMicTap;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La vista previa abre y cierra su espacio en vez de empujar la barra
          // de golpe.
          AnimatedSize(
            duration: Motion.standard,
            curve: Motion.easeOut,
            alignment: Alignment.bottomLeft,
            child:
                attachment == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                      child: Entrance(
                        child: _AttachmentPreview(
                          attachment: attachment,
                          onRemove: onRemoveAttachment,
                        ),
                      ),
                    ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Adjuntar imagen',
                onPressed: isStreaming ? null : onAttach,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText:
                        isListening
                            ? 'Te escucho…'
                            : attachment == null
                            ? 'Escribe o dicta a NOVA…'
                            : 'Pregunta sobre la imagen…',
                    suffixIcon:
                        onMicTap == null
                            ? null
                            : AnimatedSwitcher(
                              duration: Motion.fast,
                              switchInCurve: Motion.easeOut,
                              switchOutCurve: Motion.easeOut,
                              transitionBuilder: Motion.fadeScale,
                              child:
                                  isListening
                                      ? IconButton.filledTonal(
                                        key: const ValueKey('listening'),
                                        tooltip: 'Dejar de dictar',
                                        onPressed: onMicTap,
                                        icon: const Icon(
                                          Icons.graphic_eq_rounded,
                                        ),
                                      )
                                      : IconButton(
                                        key: const ValueKey('mic'),
                                        tooltip: 'Dictar',
                                        onPressed:
                                            isStreaming ? null : onMicTap,
                                        icon: const Icon(
                                          Icons.mic_none_rounded,
                                        ),
                                      ),
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: Motion.fast,
                switchInCurve: Motion.easeOut,
                switchOutCurve: Motion.easeOut,
                transitionBuilder: Motion.fadeScale,
                child:
                    isStreaming
                        ? IconButton.filledTonal(
                          key: const ValueKey('stop'),
                          tooltip: 'Detener',
                          onPressed: onStop,
                          icon: const Icon(Icons.stop_rounded),
                        )
                        : IconButton.filled(
                          key: const ValueKey('send'),
                          tooltip: 'Enviar',
                          onPressed: onSend,
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.onRemove});

  final ChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            attachment.bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            semanticLabel: 'Imagen para enviar',
          ),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: IconButton.filledTonal(
            tooltip: 'Quitar imagen',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
