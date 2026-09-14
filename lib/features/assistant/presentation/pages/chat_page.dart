import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../data/services/media_picker_service.dart';
import '../../domain/entities/chat_attachment.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Cómo abrir el chat: con un mensaje inicial, un texto a medio escribir o
/// directamente con la cámara.
class ChatLaunchOptions {
  const ChatLaunchOptions({this.prompt, this.draft, this.imageSource});

  final String? prompt;
  final ChatDraft? draft;
  final MediaSource? imageSource;
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
    this.initialPrompt,
    this.initialDraft,
    this.initialImageSource,
    this.aiMode = AiMode.firebase,
  });

  final MediaPickerService mediaPicker;

  /// Mensaje que se envía automáticamente al abrir el chat.
  final String? initialPrompt;

  /// Texto que queda escrito para que el usuario lo complete.
  final ChatDraft? initialDraft;

  /// Abre la cámara o la galería al entrar.
  final MediaSource? initialImageSource;
  final AiMode aiMode;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  ChatAttachment? _attachment;

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
    if (widget.initialImageSource case final source?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(source));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<MediaSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == MediaSource.camera
                ? 'No se pudo abrir la cámara.'
                : 'No se pudo abrir la galería.',
          ),
        ),
      );
    }
  }

  void _send([String? suggestion]) {
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;

    final text = suggestion ?? _textController.text;
    final attachment = suggestion == null ? _attachment : null;
    if (text.trim().isEmpty && attachment == null) return;

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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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
                listenWhen: (previous, current) =>
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
                    itemBuilder: (context, index) =>
                        MessageBubble(message: state.messages[index]),
                  );
                },
              ),
            ),
            BlocSelector<ChatBloc, ChatState, String?>(
              selector: (state) => state.errorMessage,
              builder: (context, error) => error == null
                  ? const SizedBox.shrink()
                  : _ErrorBanner(message: error),
            ),
            BlocSelector<ChatBloc, ChatState, bool>(
              selector: (state) => state.isStreaming,
              builder: (context, isStreaming) => ChatInput(
                controller: _textController,
                focusNode: _inputFocus,
                isStreaming: isStreaming,
                attachment: _attachment,
                onSend: _send,
                onStop: () => context
                    .read<ChatBloc>()
                    .add(const ChatGenerationStopped()),
                onAttach: _chooseImageSource,
                onRemoveAttachment: () => setState(() => _attachment = null),
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
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Pregúntame lo que quieras',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'También puedes enviarme una foto con el botón de imagen.',
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
  const _ErrorBanner({required this.message});

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
