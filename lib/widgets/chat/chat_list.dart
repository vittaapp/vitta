import 'package:flutter/material.dart';
import '../../models/domain/chat_message_domain.dart';
import '../../models/ui/chat_message_ui.dart';
import 'chat_bubble.dart';

/// Lista scrolleable de mensajes de chat.
class ChatListWidget extends StatelessWidget {
  const ChatListWidget({
    super.key,
    required this.mensajes,
    required this.usuarioActualId,
  });

  final List<ChatMessageDomain> mensajes;
  final String usuarioActualId;

  @override
  Widget build(BuildContext context) {
    if (mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin mensajes aún',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Iniciá una conversación',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      itemCount: mensajes.length,
      itemBuilder: (context, index) {
        final mensaje = mensajes[mensajes.length - 1 - index];
        final mensajeUI = ChatMessageUI.from(mensaje, usuarioActualId);
        return ChatBubbleWidget(mensaje: mensajeUI);
      },
    );
  }
}
