import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/strings/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/utils/dates.dart';
import '../../../../shared/widgets/nova_logo.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../assistant/presentation/pages/chat_page.dart';
import '../../../history/domain/entities/conversation.dart';
import '../../../history/domain/repositories/conversation_repository.dart';
import '../../../history/presentation/widgets/conversation_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.clock = DateTime.now, this.conversations});

  /// Hora actual. Los tests la fijan para que el saludo no dependa del reloj.
  final DateTime Function() clock;

  /// Historial para mostrar las conversaciones recientes.
  final ConversationRepository? conversations;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _recentLimit = 3;

  final _promptController = TextEditingController();
  List<ConversationSummary> _recent = const [];
  StreamSubscription<void>? _historyChanges;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _historyChanges = widget.conversations?.changes.listen(
      (_) => _loadRecent(),
    );
  }

  @override
  void dispose() {
    _historyChanges?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final conversations = widget.conversations;
    if (conversations == null) return;
    final recent = await conversations.recent();
    if (mounted) {
      setState(() => _recent = recent.take(_recentLimit).toList());
    }
  }

  void _openHistory() => context.push(AppRoutes.history);

  void _openConversation(ConversationSummary summary) => context.push(
    AppRoutes.chat,
    extra: ChatLaunchOptions(conversationId: summary.id),
  );

  void _openChat([String? prompt]) {
    context.push(AppRoutes.chat, extra: prompt);
    _promptController.clear();
  }

  void _submitPrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isNotEmpty) _openChat(prompt);
  }

  void _openVoice() => context.push(AppRoutes.voice);

  // Pregunta si tomar la foto o elegirla de la galería.
  void _openCamera() => context.push(
    AppRoutes.chat,
    extra: const ChatLaunchOptions(pickImage: true),
  );

  // Queda escrito sin enviar: el usuario completa qué quiere buscar.
  void _openLocation() => context.push(
    AppRoutes.chat,
    extra: const ChatLaunchOptions(
      draft: ChatDraft(
        prefix: HomeStrings.locationDraftPrefix,
        suffix: HomeStrings.locationDraftSuffix,
      ),
    ),
  );

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppStrings.comingSoon(feature))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = widget.clock();
    final sectionStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                const NovaLogo(size: 34),
                const SizedBox(width: 10),
                Text(AppStrings.brand, style: theme.textTheme.headlineSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shortSpanishDate(now),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.history,
                  onPressed: _openHistory,
                  icon: const Icon(Icons.history_rounded),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              greetingFor(now),
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text: HomeStrings.headlineStart,
                children: [
                  TextSpan(
                    text: HomeStrings.headlineHighlight,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: scheme.primary,
                    ),
                  ),
                  const TextSpan(text: HomeStrings.headlineEnd),
                ],
              ),
              style: theme.textTheme.displaySmall?.copyWith(height: 1.05),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submitPrompt(),
              decoration: InputDecoration(
                hintText: HomeStrings.promptHint,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton.filled(
                    tooltip: AppStrings.send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    onPressed: _submitPrompt,
                  ),
                ),
              ),
            ),
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(HomeStrings.recent, style: sectionStyle),
                  ),
                  TextButton(
                    onPressed: _openHistory,
                    child: const Text(HomeStrings.seeAll),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final summary in _recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ConversationTile(
                    summary: summary,
                    now: now,
                    onTap: () => _openConversation(summary),
                  ),
                ),
            ],
            const SizedBox(height: 36),
            Text(HomeStrings.shortcuts, style: sectionStyle),
            const SizedBox(height: 12),
            _VoiceCard(onTap: _openVoice),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ShortcutCard(
                      icon: Icons.photo_camera_outlined,
                      label: HomeStrings.cameraTitle,
                      caption: HomeStrings.cameraCaption,
                      onTap: _openCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutCard(
                      icon: Icons.near_me_outlined,
                      label: HomeStrings.locationTitle,
                      caption: HomeStrings.locationCaption,
                      onTap: _openLocation,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ShortcutCard(
              icon: Icons.description_outlined,
              label: HomeStrings.documentTitle,
              caption: HomeStrings.documentCaption,
              badge: AppStrings.soon,
              onTap: () => _showComingSoon(HomeStrings.documentTitle),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(HomeStrings.openChat),
            ),
          ],
        ),
      ),
    );
  }
}

/// El atajo principal: hablar con NOVA.
class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Pressable(
      builder:
          (context, onHighlightChanged) => Material(
            color: AppColors.ink,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.extraLarge),
              // En modo oscuro la tarjeta de tinta se perdería contra el fondo.
              side:
                  isDark
                      ? BorderSide(color: theme.colorScheme.outlineVariant)
                      : BorderSide.none,
            ),
            child: InkWell(
              onTap: onTap,
              onHighlightChanged: onHighlightChanged,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            HomeStrings.voiceTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.paper,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            HomeStrings.voiceCaption,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.paper.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.violet,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.white,
                        size: 28,
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

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  /// Etiqueta corta, como "Pronto". Con etiqueta la tarjeta va en horizontal.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badge = this.badge;

    final iconWidget = Icon(icon, color: scheme.primary, size: 26);
    final title = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final subtitle = Text(
      caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );

    return Pressable(
      builder:
          (context, onHighlightChanged) => Material(
            color: scheme.surfaceContainerLowest,
            clipBehavior: Clip.antiAlias,
            shape: AppShapes.outlinedCard(scheme),
            child: InkWell(
              onTap: onTap,
              onHighlightChanged: onHighlightChanged,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    badge == null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            iconWidget,
                            const SizedBox(height: 20),
                            title,
                            const SizedBox(height: 2),
                            subtitle,
                          ],
                        )
                        : Row(
                          children: [
                            iconWidget,
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [title, subtitle],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: theme.textTheme.labelSmall,
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
