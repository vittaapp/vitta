import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario_model.dart' show RolesVitta;
import '../providers/usuario_rol_provider.dart' show authStateProvider, usuarioActualProvider;
import '../services/chat_service.dart';

const Color _azulVitta = Color(0xFF1A3E6F);
const Color _bordeOtro = Color(0xFFBBDEFB);

class ChatTurnoView extends ConsumerStatefulWidget {
  const ChatTurnoView({
    super.key,
    required this.turnoId,
    required this.nombrePaciente,
  });

  final String turnoId;
  final String nombrePaciente;

  @override
  ConsumerState<ChatTurnoView> createState() => _ChatTurnoViewState();
}

class _ChatTurnoViewState extends ConsumerState<ChatTurnoView> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _enviando = false;
  int _lastMsgCount = 0;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _fmtHora(dynamic timestamp) {
    DateTime? d;
    if (timestamp is Timestamp) d = timestamp.toDate();
    if (timestamp is DateTime) d = timestamp;
    if (d == null) return '—';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final usuarioAsync = ref.watch(usuarioActualProvider);

    final uid = authAsync.maybeWhen(data: (u) => u?.uid, orElse: () => null);

    final chatService = ref.read(chatServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        title: _TituloInterlocutor(
          turnoId: widget.turnoId,
          nombrePaciente: widget.nombrePaciente,
          uidActual: uid,
          usuarioAsync: usuarioAsync,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('turnos')
            .doc(widget.turnoId)
            .snapshots(),
        builder: (context, turnSnap) {
          final estado = turnSnap.data?.data()?['estado'] as String? ?? '';
          final habilitado = estado == 'activo' || estado == 'aceptado';

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: chatService.obtenerMensajes(widget.turnoId),
                  builder: (context, msgSnap) {
                    if (msgSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _azulVitta),
                      );
                    }
                    final docs = msgSnap.data?.docs ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (docs.length == _lastMsgCount) return;
                      _lastMsgCount = docs.length;
                      if (_scrollCtrl.hasClients) {
                        _scrollCtrl.animateTo(
                          _scrollCtrl.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Todavía no hay mensajes. Escribí para empezar la conversación.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final m = docs[idx].data();
                        final texto = (m['texto'] as String? ?? '').trim();
                        final remitenteId = (m['remitenteId'] as String? ?? '');
                        final nombreRemitente =
                            (m['nombreRemitente'] as String? ?? '').trim();
                        final timestamp = m['timestamp'];
                        final esPropio = uid != null && remitenteId == uid;

                        return _BurbujasMensaje(
                          texto: texto,
                          esPropio: esPropio,
                          nombreRemitente: nombreRemitente,
                          hora: _fmtHora(timestamp),
                        );
                      },
                    );
                  },
                ),
              ),
              _Composer(
                habilitado: habilitado,
                enviando: _enviando,
                textCtrl: _textCtrl,
                onEnviar: () async {
                  if (!habilitado) return;
                  if (uid == null) return;
                  final t = _textCtrl.text.trim();
                  if (t.isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _enviando = true);
                  try {
                    final usuario = usuarioAsync.asData?.value;
                    final nombreRemitente =
                        (usuario?.nombre ?? '').trim().isNotEmpty
                            ? usuario!.nombre.trim()
                            : 'Usuario';
                    await chatService.enviarMensaje(
                      turnoId: widget.turnoId,
                      texto: t,
                      remitenteId: uid,
                      nombreRemitente: nombreRemitente,
                    );
                    _textCtrl.clear();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('No se pudo enviar el mensaje: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _enviando = false);
                  }
                },
              ),
              if (!habilitado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'El chat está habilitado solo cuando el turno está en estado activo o aceptado.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class _TituloInterlocutor extends StatelessWidget {
  const _TituloInterlocutor({
    required this.turnoId,
    required this.nombrePaciente,
    required this.uidActual,
    required this.usuarioAsync,
  });

  final String turnoId;
  final String nombrePaciente;
  final String? uidActual;
  final AsyncValue<dynamic> usuarioAsync;

  @override
  Widget build(BuildContext context) {
    final usuario = usuarioAsync.asData?.value;
    final rol = usuario?.rol as String?;
    final esFamiliar = rol == RolesVitta.familiar;

    if (!esFamiliar) {
      return Text(
        nombrePaciente.trim().isNotEmpty ? nombrePaciente.trim() : 'Paciente',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Familiar: título = nombre del profesional del turno.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('turnos').doc(turnoId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final profId = (data?['profesionalId'] as String?) ?? '';
        if (profId.isEmpty) return const Text('Profesional');

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('usuarios').doc(profId).get(),
          builder: (context, profSnap) {
            final nombre =
                (profSnap.data?.data()?['nombre'] as String?) ?? '';
            final title = nombre.trim().isNotEmpty ? nombre.trim() : 'Profesional';
            return Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
      },
    );
  }
}

class _BurbujasMensaje extends StatelessWidget {
  const _BurbujasMensaje({
    required this.texto,
    required this.esPropio,
    required this.nombreRemitente,
    required this.hora,
  });

  final String texto;
  final bool esPropio;
  final String nombreRemitente;
  final String hora;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final bgColor = esPropio ? _azulVitta : Colors.white;
    final txtColor = esPropio ? Colors.white : const Color(0xFF1A1A1A);
    final borderColor = esPropio ? Colors.transparent : _bordeOtro;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: esPropio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!esPropio)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        nombreRemitente,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    texto,
                    style: TextStyle(
                      color: txtColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: esPropio ? Alignment.bottomRight : Alignment.bottomLeft,
                    child: Text(
                      hora,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: esPropio ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.habilitado,
    required this.enviando,
    required this.textCtrl,
    required this.onEnviar,
  });

  final bool habilitado;
  final bool enviando;
  final TextEditingController textCtrl;
  final Future<void> Function() onEnviar;

  @override
  Widget build(BuildContext context) {
    final disabled = !habilitado || enviando;
    final iconColor = disabled ? Colors.grey.shade600 : _azulVitta;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textCtrl,
                enabled: !disabled,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: disabled
                      ? 'Chat no habilitado'
                      : 'Escribí tu mensaje...',
                  filled: true,
                  fillColor: const Color(0xFFF3F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Enviar',
              onPressed: disabled ? null : onEnviar,
              icon: Icon(Icons.send_rounded, color: iconColor),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: iconColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

