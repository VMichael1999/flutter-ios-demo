import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/motion.dart';
import '../../../../shared/widgets/entrance.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../domain/speakable_text.dart';
import '../cubit/voice_conversation_cubit.dart';
import '../widgets/voice_orb.dart';

/// Modo voz: una conversación con NOVA sin escribir.
class VoicePage extends StatefulWidget {
  const VoicePage({super.key, this.listenOnOpen = true});

  /// Empieza a escuchar apenas se abre la pantalla.
  final bool listenOnOpen;

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  @override
  void initState() {
    super.initState();
    if (widget.listenOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<VoiceConversationCubit>().startListening();
      });
    }
  }

  static String _statusLabel(VoiceState state) => switch (state.status) {
    VoiceStatus.idle => 'Toca el micrófono y habla',
    VoiceStatus.listening => 'Te escucho… habla ahora',
    VoiceStatus.thinking => 'Pensando…',
    VoiceStatus.speaking => 'Hablando · toca para interrumpir',
    VoiceStatus.failure =>
      state.errorMessage ?? 'Algo salió mal. Inténtalo otra vez.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Habla con NOVA')),
      body: SafeArea(
        child: BlocBuilder<VoiceConversationCubit, VoiceState>(
          builder: (context, state) {
            final reply = speakableText(state.reply);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VoiceOrb(
                              status: state.status,
                              level:
                                  context
                                      .read<VoiceConversationCubit>()
                                      .soundLevel,
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              liveRegion: true,
                              child: AnimatedSwitcher(
                                duration: Motion.standard,
                                switchInCurve: Motion.easeOut,
                                switchOutCurve: Motion.easeOut,
                                child: Text(
                                  _statusLabel(state),
                                  key: ValueKey(_statusLabel(state)),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        state.status == VoiceStatus.failure
                                            ? scheme.error
                                            : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            if (state.transcript.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                '“${state.transcript}”',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (reply.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Entrance(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: scheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    reply,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MicButton(
                    status: state.status,
                    onPressed: context.read<VoiceConversationCubit>().toggle,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.status, required this.onPressed});

  final VoiceStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, tooltip, background, foreground) = switch (status) {
      VoiceStatus.listening => (
        Icons.stop_rounded,
        'Terminar de hablar',
        scheme.onSurface,
        scheme.surface,
      ),
      VoiceStatus.thinking || VoiceStatus.speaking => (
        Icons.close_rounded,
        'Interrumpir',
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      VoiceStatus.idle || VoiceStatus.failure => (
        Icons.mic_rounded,
        'Hablar',
        scheme.primary,
        scheme.onPrimary,
      ),
    };

    // El color cambia con `ease` y el ícono con un fundido desde el 90 %:
    // el botón se transforma en vez de parpadear entre estados.
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        child: Pressable(
          builder:
              (context, onHighlightChanged) => AnimatedContainer(
                duration: Motion.standard,
                curve: Curves.ease,
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPressed,
                    onHighlightChanged: onHighlightChanged,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: Motion.fast,
                        switchInCurve: Motion.easeOut,
                        switchOutCurve: Motion.easeOut,
                        transitionBuilder: Motion.fadeScale,
                        child: Icon(
                          icon,
                          key: ValueKey(icon),
                          size: 36,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
