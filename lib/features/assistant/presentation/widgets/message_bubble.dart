import 'package:flutter/material.dart';

import '../../../../core/theme/motion.dart';
import '../../../../shared/widgets/entrance.dart';
import '../../domain/entities/chat_message.dart';
import 'nova_thinking_indicator.dart';
import 'place_card.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.animateIn = false,
    this.animatePlaces = false,
  });

  final ChatMessage message;

  /// El mensaje es nuevo: entra con una animación en vez de aparecer de golpe.
  final bool animateIn;

  /// Los lugares acaban de llegar: entran escalonados.
  final bool animatePlaces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.isUser;
    final isThinking = message.isStreaming && message.text.isEmpty;
    final text = message.text.trimRight();
    final alignment =
        isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart;

    final Widget content;
    if (isThinking) {
      content = const Padding(
        key: ValueKey('thinking'),
        padding: EdgeInsets.symmetric(vertical: 4),
        child: NovaThinkingIndicator(),
      );
    } else if (text.isNotEmpty) {
      content = Container(
        key: const ValueKey('text'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Text(
          message.isStreaming ? '$text ▍' : text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey('empty'));
    }

    return Entrance(
      enabled: animateIn,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.attachment case final attachment?
                  when attachment.isImage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      attachment.bytes,
                      width: 220,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      semanticLabel: 'Imagen enviada',
                    ),
                  ),
                ),
              if (message.attachment == null && message.hadImage)
                const _SavedImageNote(),
              // De "pensando" a la respuesta sin salto: fundido y el alto
              // se ajusta suave mientras llega el texto.
              AnimatedSize(
                duration: Motion.standard,
                curve: Motion.easeOut,
                alignment: isUser ? Alignment.topRight : Alignment.topLeft,
                child: AnimatedSwitcher(
                  duration: Motion.standard,
                  switchInCurve: Motion.easeOut,
                  switchOutCurve: Motion.easeOut,
                  layoutBuilder:
                      (current, previous) => Stack(
                        alignment: alignment,
                        children: [...previous, if (current != null) current],
                      ),
                  child: content,
                ),
              ),
              for (final (index, place) in message.places.indexed)
                Entrance(
                  enabled: animatePlaces,
                  delay: Motion.stagger * index,
                  child: PlaceCard(
                    place: place,
                    onDirections: () => openDirections(place),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En el historial las fotos no se guardan: queda una nota en su lugar.
class _SavedImageNote extends StatelessWidget {
  const _SavedImageNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Imagen enviada',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
