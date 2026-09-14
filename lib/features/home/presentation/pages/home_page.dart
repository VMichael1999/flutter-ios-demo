import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../assistant/presentation/pages/chat_page.dart';
import '../../../../shared/widgets/nova_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _quickActions = [
    _QuickAction(
      icon: Icons.photo_camera_outlined,
      label: 'Cámara',
      // Pregunta si tomar la foto o elegirla de la galería.
      pickImage: true,
    ),
    _QuickAction(icon: Icons.mic_none_rounded, label: 'Voz'),
    _QuickAction(icon: Icons.description_outlined, label: 'Documento'),
    _QuickAction(
      icon: Icons.location_on_outlined,
      label: 'Ubicación',
      // Queda escrito sin enviar: el usuario completa qué quiere buscar.
      draft: ChatDraft(prefix: 'Busca ', suffix: ' cerca de mí'),
    ),
  ];

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

  void _onQuickAction(_QuickAction action) {
    if (action.pickImage) {
      context.push(
        AppRoutes.chat,
        extra: const ChatLaunchOptions(pickImage: true),
      );
    } else if (action.draft case final draft?) {
      context.push(AppRoutes.chat, extra: ChatLaunchOptions(draft: draft));
    } else {
      _showComingSoon(action.label);
    }
  }

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

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NovaLogo(size: 28),
            SizedBox(width: 10),
            Text(AppConfig.appName),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hola 👋',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '¿Qué quieres hacer?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submitPrompt(),
              decoration: InputDecoration(
                hintText: 'Pregúntale algo a NOVA…',
                prefixIcon: const Icon(Icons.auto_awesome_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Enviar',
                  icon: const Icon(Icons.arrow_upward_rounded),
                  onPressed: _submitPrompt,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Altura fija: con una proporción ancho/alto las tarjetas se
              // desbordaban en teléfonos estrechos (360 px) o con letra grande.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 100,
              ),
              children: [
                for (final action in _quickActions)
                  _QuickActionCard(
                    action: action,
                    onTap: () => _onQuickAction(action),
                  ),
              ],
            ),
            const SizedBox(height: 32),
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

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.draft,
    this.pickImage = false,
  });

  final IconData icon;
  final String label;

  /// Texto que queda escrito en el chat para que el usuario lo complete.
  final ChatDraft? draft;

  /// Abre el chat preguntando si usar la cámara o la galería.
  final bool pickImage;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(20);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(action.icon, color: theme.colorScheme.primary),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
