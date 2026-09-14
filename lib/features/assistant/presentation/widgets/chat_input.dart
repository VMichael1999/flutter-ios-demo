import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(hintText: 'Escribe a NOVA…'),
            ),
          ),
          const SizedBox(width: 8),
          if (isStreaming)
            IconButton.filledTonal(
              tooltip: 'Detener',
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded),
            )
          else
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: onSend,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
        ],
      ),
    );
  }
}
