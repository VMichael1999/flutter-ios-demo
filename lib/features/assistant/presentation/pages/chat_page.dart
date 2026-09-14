import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.initialPrompt,
    this.aiMode = AiMode.firebase,
  });

  /// Mensaje que se envía automáticamente al abrir el chat.
  final String? initialPrompt;
  final AiMode aiMode;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      context.read<ChatBloc>().add(ChatMessageSent(prompt));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = text ?? _textController.text;
    if (message.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(message));
    if (text == null) _textController.clear();
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
                isStreaming: isStreaming,
                onSend: _send,
                onStop: () => context
                    .read<ChatBloc>()
                    .add(const ChatGenerationStopped()),
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
    'Ayúdame a organizar mi semana',
    'Explícame qué es Flutter',
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
