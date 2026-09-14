import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/nova_logo.dart';
import '../../../../shared/widgets/nova_mark.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../assistant/presentation/pages/chat_page.dart';

/// Saludo según la hora del día.
String greetingFor(DateTime time) => switch (time.hour) {
  < 5 => 'Buenas noches',
  < 12 => 'Buenos días',
  < 19 => 'Buenas tardes',
  _ => 'Buenas noches',
};

/// Fecha corta en español, por ejemplo "dom 13 sep".
String shortSpanishDate(DateTime date) {
  const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.clock = DateTime.now});

  /// Hora actual. Los tests la fijan para que el saludo no dependa del reloj.
  final DateTime Function() clock;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

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
      draft: ChatDraft(prefix: 'Busca ', suffix: ' cerca de mí'),
    ),
  );

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature estará disponible en próximas versiones.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = widget.clock();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                const NovaLogo(size: 34),
                const SizedBox(width: 10),
                Text('NOVA', style: theme.textTheme.headlineSmall),
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
                text: '¿Qué hacemos ',
                children: [
                  TextSpan(
                    text: 'hoy',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: scheme.primary,
                    ),
                  ),
                  const TextSpan(text: '?'),
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
                hintText: 'Pregúntale algo a NOVA…',
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton.filled(
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.arrow_upward_rounded),
                    onPressed: _submitPrompt,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Atajos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                      label: 'Cámara',
                      caption: 'Toma una foto o elige una',
                      onTap: _openCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutCard(
                      icon: Icons.near_me_outlined,
                      label: 'Ubicación',
                      caption: 'Lugares cerca de ti',
                      onTap: _openLocation,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ShortcutCard(
              icon: Icons.description_outlined,
              label: 'Documento',
              caption: 'Lee y resume un PDF',
              badge: 'Pronto',
              onTap: () => _showComingSoon('Documento'),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Abrir chat con NOVA'),
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
            color: NovaBrand.ink,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
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
                            'Voz',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: NovaBrand.paper,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Conversa con NOVA sin escribir',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: NovaBrand.paper.withValues(alpha: 0.72),
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
                        color: NovaBrand.violet,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: Colors.white,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant),
            ),
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
                                borderRadius: BorderRadius.circular(99),
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
