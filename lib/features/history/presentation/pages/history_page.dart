import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/dates.dart';
import '../../../../shared/widgets/nova_logo.dart';
import '../../../assistant/presentation/pages/chat_page.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../widgets/conversation_tile.dart';

/// Todas las conversaciones guardadas, agrupadas por fecha.
class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.conversations,
    this.clock = DateTime.now,
  });

  final ConversationRepository conversations;
  final DateTime Function() clock;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ConversationSummary>? _items;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _load();
    _changes = widget.conversations.changes.listen((_) => _load());
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await widget.conversations.recent();
    if (mounted) setState(() => _items = items);
  }

  void _open(ConversationSummary summary) => context.push(
    AppRoutes.chat,
    extra: ChatLaunchOptions(conversationId: summary.id),
  );

  Future<void> _delete(ConversationSummary summary) async {
    setState(() => _items = [...?_items]..remove(summary));
    final conversation = await widget.conversations.load(summary.id);
    await widget.conversations.delete(summary.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Conversación eliminada'),
          action:
              conversation == null
                  ? null
                  : SnackBarAction(
                    label: 'Deshacer',
                    onPressed: () => widget.conversations.save(conversation),
                  ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _items;
    final now = widget.clock();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: switch (items) {
          null => const Center(child: CircularProgressIndicator()),
          [] => const _EmptyHistory(),
          _ => ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                'Toca una conversación para seguirla. Desliza a la '
                'izquierda para borrarla.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              for (final (index, summary) in items.indexed) ...[
                if (index == 0 ||
                    historySectionLabel(items[index - 1].updatedAt, now) !=
                        historySectionLabel(summary.updatedAt, now))
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      historySectionLabel(summary.updatedAt, now),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(summary.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _delete(summary),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    child: Semantics(
                      onDismiss: () => _delete(summary),
                      child: ConversationTile(
                        summary: summary,
                        now: now,
                        onTap: () => _open(summary),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NovaLogo(size: 64),
            const SizedBox(height: 20),
            Text(
              'Aún no hay conversaciones',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Lo que hables con NOVA, escribiendo o por voz, se guardará '
              'aquí.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
