import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'place_card.dart';
import 'typing_indicator.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.isUser;
    final showTyping = message.isStreaming && message.text.isEmpty;
    final text = message.text.trimRight();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
            if (showTyping || text.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isUser ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                ),
                child: showTyping
                    ? const TypingIndicator()
                    : Text(
                        message.isStreaming ? '$text ▍' : text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isUser ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
              ),
            for (final place in message.places)
              PlaceCard(
                place: place,
                onDirections: () => openDirections(place),
              ),
          ],
        ),
      ),
    );
  }
}
