import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/usuario_rol_provider.dart';
import 'chat_input.dart';
import 'chat_list.dart';

const Color _azulVitta = Color(0xFF1A3E6F);

/// Vista completa del chat de un turno (Scaffold propio — push como page).
class ChatViewWidget extends ConsumerWidget {
  const ChatViewWidget({
    super.key,
    required this.turnoId,
    required this.permitirEnvio,
  });

  final String turnoId;
  final bool permitirEnvio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioActualProvider);
    final mensajesAsync = ref.watch(chatStreamProvider(turnoId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat del turno',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: usuarioAsync.when(
        data: (usuario) {
          if (usuario == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          return mensajesAsync.when(
            data: (mensajes) => Column(
              children: [
                Expanded(
                  child: ChatListWidget(
                    mensajes: mensajes,
                    usuarioActualId: usuario.id,
                  ),
                ),
                if (!permitirEnvio)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: Colors.orange.shade50,
                    child: Text(
                      'El chat está habilitado solo durante un turno activo o aceptado.',
                      style: TextStyle(
                          color: Colors.orange.shade800, fontSize: 12.5),
                    ),
                  ),
                ChatInputWidget(
                  enabled: permitirEnvio,
                  onSendMessage: (texto) async {
                    try {
                      await ref.read(chatServiceProvider).enviarMensaje(
                            turnoId: turnoId,
                            texto: texto,
                            nombreRemitente: usuario.nombre,
                          );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al enviar: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _azulVitta)),
            error: (error, _) =>
                Center(child: Text('Error al cargar mensajes: $error')),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _azulVitta)),
        error: (error, _) =>
            Center(child: Text('Error de sesión: $error')),
      ),
    );
  }
}
