import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/theme/motion.dart';
import '../../data/services/media_picker_service.dart';
import '../../domain/entities/chat_attachment.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Cómo abrir el chat: con un mensaje inicial, un texto a medio escribir o
/// preguntando de dónde tomar una imagen.
class ChatLaunchOptions {
  const ChatLaunchOptions({this.prompt, this.draft, this.pickImage = false});

  final String? prompt;
  final ChatDraft? draft;

  /// Pregunta al entrar si usar la cámara o la galería.
  final bool pickImage;
}

/// Texto que se deja escrito, sin enviar, con el cursor entre [prefix] y
/// [suffix]. Por ejemplo "Busca | cerca de mí".
class ChatDraft {
  const ChatDraft({required this.prefix, this.suffix = ''});

  final String prefix;
  final String suffix;

  String get text => '$prefix$suffix';

  int get cursorOffset => prefix.length;
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.mediaPicker,
    this.speechService,
    this.initialPrompt,
    this.initialDraft,
    this.pickImageOnOpen = false,
    this.aiMode = AiMode.firebase,
  });

  final MediaPickerService mediaPicker;

  /// Dictado por voz. Sin servicio no se muestra el micrófono.
  final SpeechService? speechService;

  /// Mensaje que se envía automáticamente al abrir el chat.
  final String? initialPrompt;

  /// Texto que queda escrito para que el usuario lo complete.
  final ChatDraft? initialDraft;

  /// Al entrar, pregunta si tomar una foto o elegirla de la galería.
  final bool pickImageOnOpen;
  final AiMode aiMode;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  ChatAttachment? _attachment;
  StreamSubscription<SpeechUpdate>? _dictation;

  /// Mensajes (y listas de lugares) que ya hicieron su animación de entrada.
  final _animatedIds = <String>{};

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      context.read<ChatBloc>().add(ChatMessageSent(prompt));
    }
    if (widget.initialDraft case final draft?) {
      _textController.value = TextEditingValue(
        text: draft.text,
        selection: TextSelection.collapsed(offset: draft.cursorOffset),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocus.requestFocus();
      });
    }
    if (widget.pickImageOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _chooseImageSource();
      });
    }
  }

  @override
  void dispose() {
    _dictation?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<MediaSource>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    'Añadir una imagen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(context, MediaSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Elegir de la galería'),
                  onTap: () => Navigator.pop(context, MediaSource.gallery),
                ),
              ],
            ),
          ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(MediaSource source) async {
    try {
      final attachment = await widget.mediaPicker.pickImage(source);
      if (attachment != null && mounted) {
        setState(() => _attachment = attachment);
      }
    } catch (error) {
      debugPrint('No se pudo obtener la imagen: $error');
      if (!mounted) return;
      _showMessage(
        source == MediaSource.camera
            ? 'No se pudo abrir la cámara.'
            : 'No se pudo abrir la galería.',
      );
    }
  }

  /// Empieza a dictar o, si ya se está dictando, termina la frase.
  Future<void> _toggleDictation() async {
    final speech = widget.speechService;
    if (speech == null) return;
    if (_dictation != null) {
      await speech.stop();
      return;
    }

    // Lo dictado se añade a lo que ya estaba escrito.
    final written = _textController.text.trimRight();
    setState(() {
      _dictation = speech.listen().listen(
        (update) => _showDictation(written, update.text),
        onError: (Object error) {
          _endDictation();
          if (mounted) {
            _showMessage(
              error is SpeechFailure ? error.message : 'No pude escucharte.',
            );
          }
        },
        onDone: _endDictation,
        cancelOnError: true,
      );
    });
  }

  void _showDictation(String written, String dictated) {
    final text = [
      if (written.isNotEmpty) written,
      if (dictated.isNotEmpty) dictated,
    ].join(' ');
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _endDictation() {
    if (_dictation == null) return;
    if (mounted) {
      setState(() => _dictation = null);
    } else {
      _dictation = null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _send([String? suggestion]) {
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;

    final text = suggestion ?? _textController.text;
    final attachment = suggestion == null ? _attachment : null;
    if (text.trim().isEmpty && attachment == null) return;

    // Enviar a mitad del dictado lo da por terminado con lo ya escrito.
    if (_dictation != null) {
      _dictation?.cancel();
      widget.speechService?.cancel();
      _dictation = null;
    }

    bloc.add(ChatMessageSent(text, attachment: attachment));
    if (suggestion == null) {
      _textController.clear();
      setState(() => _attachment = null);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Motion.enter,
        curve: Motion.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA'),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ChatBloc>().add(const ChatCleared()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.aiMode == AiMode.demo) const _DemoModeBanner(),
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listenWhen:
                    (previous, current) =>
                        previous.messages != current.messages,
                listener: (context, state) => _scrollToBottom(),
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return _EmptyChat(onSuggestionTap: _send);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      // Solo entra animado la primera vez que se muestra: al
                      // volver a verlo con el scroll ya no se repite.
                      return MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        animateIn: _animatedIds.add(message.id),
                        animatePlaces:
                            message.places.isNotEmpty &&
                            _animatedIds.add('${message.id}:places'),
                      );
                    },
                  );
                },
              ),
            ),
            BlocSelector<ChatBloc, ChatState, String?>(
              selector: (state) => state.errorMessage,
              builder:
                  (context, error) => AnimatedSwitcher(
                    duration: Motion.standard,
                    switchInCurve: Motion.easeOut,
                    switchOutCurve: Motion.easeOut,
                    transitionBuilder:
                        (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.bottomCenter,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        error == null
                            ? const SizedBox(width: double.infinity)
                            : _ErrorBanner(
                              key: ValueKey(error),
                              message: error,
                            ),
                  ),
            ),
            BlocSelector<ChatBloc, ChatState, bool>(
              selector: (state) => state.isStreaming,
              builder:
                  (context, isStreaming) => ChatInput(
                    controller: _textController,
                    focusNode: _inputFocus,
                    isStreaming: isStreaming,
                    attachment: _attachment,
                    isListening: _dictation != null,
                    onMicTap:
                        widget.speechService == null ? null : _toggleDictation,
                    onSend: _send,
                    onStop:
                        () => context.read<ChatBloc>().add(
                          const ChatGenerationStopped(),
                        ),
                    onAttach: _chooseImageSource,
                    onRemoveAttachment:
                        () => setState(() => _attachment = null),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestionTap});

  static const _suggestions = [
    '¿Qué puedes hacer?',
    '¿Qué hay cerca de mí?',
    'Ayúdame a organizar mi semana',
  ];

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pregúntame lo que quieras',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Escribe, dicta con el micrófono o mándame una foto.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'Modo demo: Firebase aún no está configurado y las respuestas son '
        'simuladas.',
        style: TextStyle(color: scheme.onTertiaryContainer),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
