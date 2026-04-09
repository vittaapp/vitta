import 'package:flutter/material.dart';
import '../../models/ui/chat_message_ui.dart';

const Color _azulVitta = Color(0xFF1A3E6F);

/// Burbuja de un mensaje de chat.
class ChatBubbleWidget extends StatelessWidget {
  const ChatBubbleWidget({super.key, required this.mensaje});

  final ChatMessageUI mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: mensaje.alineacion,
        mainAxisAlignment:
            mensaje.esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mensaje.esMio)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person_rounded, size: 16),
              ),
            ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mensaje.colorBurbuja,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mensaje.esMio) ...[
                    Text(
                      mensaje.nombreRemitente,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _azulVitta,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    mensaje.texto,
                    style: TextStyle(
                      fontSize: 15,
                      color: mensaje.colorTexto,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensaje.horaFormato,
                    style: TextStyle(
                      fontSize: 11,
                      color: mensaje.esMio
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
