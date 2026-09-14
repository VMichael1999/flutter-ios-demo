import 'package:flutter/material.dart';

import '../../../../core/utils/dates.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../domain/entities/conversation.dart';

/// Una conversación del historial: de qué trató, cómo terminó y cuándo.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.summary,
    required this.now,
    required this.onTap,
  });

  final ConversationSummary summary;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVoice = summary.source == ConversationSource.voice;

    return Pressable(
      builder:
          (context, onHighlightChanged) => Material(
            color: scheme.surfaceContainerLowest,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: InkWell(
              onTap: onTap,
              onHighlightChanged: onHighlightChanged,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Icon(
                      isVoice
                          ? Icons.mic_none_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 22,
                      color: scheme.primary,
                      semanticLabel: isVoice ? 'Por voz' : 'Por chat',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (summary.preview.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              summary.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      relativeTimeLabel(summary.updatedAt, now),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
