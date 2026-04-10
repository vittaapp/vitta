import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/turno_service.dart';
import '../../views/chat_turno_view.dart';
import '../mapa_turno_activo_card.dart';

const Color _kAzulVitta = Color(0xFF1A3E6F);

/// Demo: `false` muestra próxima guardia (verde). Conectar con backend en producción.
class ServiceStatusWidget extends StatelessWidget {
  const ServiceStatusWidget({
    super.key,
    required this.onLlamarSoporte,
    required this.nombrePaciente,
  });

  final VoidCallback onLlamarSoporte;
  final String nombrePaciente;

  static DateTime? _timestampToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static String _fmtHHmm(dynamic v) {
    final d = _timestampToDate(v);
    if (d == null) return '—';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _fmtFechaHora(dynamic v) {
    final d = _timestampToDate(v);
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} · ${_fmtHHmm(v)}';
  }

  /// Muestra el código de 6 dígitos con espacio entre cifras (estilo Uber).
  static String _codigoEspaciado(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return '— — — — — —';
    return digits.split('').join(' ');
  }

  static Widget _card({
    required Color background,
    required Color borde,
    required Widget cuerpo,
    required VoidCallback? onCancelar,
    required VoidCallback? onChat,
    required VoidCallback? onSoporte,
    required bool mostrarBotonCancelar,
    required bool mostrarBotonChat,
    required bool mostrarBotonSoporte,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 2),
        boxShadow: [
          BoxShadow(
            color: _kAzulVitta.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estado del servicio',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          cuerpo,
          if (mostrarBotonCancelar) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onCancelar,
              icon: const Icon(Icons.cancel_rounded, size: 20),
              label: const Text(
                'Cancelar turno',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB71C1C),
                side: const BorderSide(color: Color(0xFFB71C1C), width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (mostrarBotonChat) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: const Text(
                'Chat con el cuidador',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (mostrarBotonSoporte) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSoporte,
              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
              label: const Text(
                'Llamar a Soporte Vitta',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: const Text(
          'Estado del servicio',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TurnoService().obtenerTurnosFamiliar(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Text(
              'No se pudo cargar el estado del servicio. Intentá más tarde.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: _kAzulVitta,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final estado = (d.data()['estado'] as String?) ?? '';
          return estado == 'pendiente' || estado == 'aceptado' || estado == 'activo';
        }).toList();

        QueryDocumentSnapshot<Map<String, dynamic>>? buscar(String estado) {
          for (final d in docs) {
            final e = (d.data()['estado'] as String?) ?? '';
            if (e == estado) return d;
          }
          return null;
        }

        final pendienteDoc = buscar('pendiente');
        final aceptadoDoc = buscar('aceptado');
        final activoDoc = buscar('activo');

        if (activoDoc != null) {
          final m = activoDoc.data();
          final rawCheck = m['checkinGps'];
          final GeoPoint? checkGps = rawCheck is GeoPoint ? rawCheck : null;
          final rawDom = m['domicilioGps'];
          final GeoPoint? domGps = rawDom is GeoPoint ? rawDom : null;
          final profId = (m['profesionalId'] as String?) ?? '';
          final nombreProfesionalFuture =
              FirebaseFirestore.instance.collection('usuarios').doc(profId).get();
          final fechaInicio = m['checkinTime'] ?? m['fechaSolicitada'];

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: nombreProfesionalFuture,
            builder: (context, profSnap) {
              final nombre = profSnap.data?.data()?['nombre'] as String?;
              final nombreProfesional =
                  (nombre != null && nombre.trim().isNotEmpty) ? nombre.trim() : 'Profesional';

              return _card(
                background: const Color(0xFFE3F2FD),
                borde: const Color(0xFF1A3E6F),
                cuerpo: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _IconoRadioPulso(color: Color(0xFFB71C1C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'En curso ahora',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: _kAzulVitta,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$nombreProfesional · Inicio: ${_fmtHHmm(fechaInicio)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: _kAzulVitta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MapaTurnoActivoCard(
                      checkinGps: checkGps,
                      domicilioGps: domGps,
                    ),
                  ],
                ),
                onCancelar: null,
                onChat: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatTurnoView(
                        turnoId: activoDoc.id,
                        nombrePaciente: nombrePaciente,
                      ),
                    ),
                  );
                },
                onSoporte: onLlamarSoporte,
                mostrarBotonCancelar: false,
                mostrarBotonChat: true,
                mostrarBotonSoporte: true,
              );
            },
          );
        }

        if (aceptadoDoc != null) {
          final m = aceptadoDoc.data();
          final profId = (m['profesionalId'] as String?) ?? '';
          final fechaEstimada = m['fechaSolicitada'];
          final direccion = m['direccion'] as String? ?? '';
          final tipo = m['tipoServicio'] as String? ?? '';

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance.collection('usuarios').doc(profId).get(),
            builder: (context, profSnap) {
              final nombre = profSnap.data?.data()?['nombre'] as String?;
              final nombreProfesional =
                  (nombre != null && nombre.trim().isNotEmpty) ? nombre.trim() : 'Profesional';

              return _card(
                background: const Color(0xFFE8F5E9),
                borde: const Color(0xFF2E7D32),
                cuerpo: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profesional confirmado',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$nombreProfesional · Llegada estimada: ${_fmtHHmm(fechaEstimada)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A3E6F), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFF1A3E6F), size: 26),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tu código de seguridad',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A3E6F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _codigoEspaciado(m['codigoVerificacion'] as String?),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dáselo al cuidador cuando llegue a tu puerta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Detalles del turno'),
                            content: Text(
                              [
                                'Profesional: $nombreProfesional',
                                'Llegada estimada: ${_fmtHHmm(fechaEstimada)}',
                                if (tipo.trim().isNotEmpty)
                                  'Tipo de servicio: $tipo',
                                if (direccion.trim().isNotEmpty) 'Dirección: $direccion',
                              ].join('\n'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_rounded, size: 20),
                      label: const Text(
                        'Ver detalles',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kAzulVitta,
                        side: const BorderSide(color: _kAzulVitta, width: 1.6),
                        minimumSize: const Size.fromHeight(56),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                onCancelar: null,
                onChat: null,
                onSoporte: null,
                mostrarBotonCancelar: false,
                mostrarBotonChat: false,
                mostrarBotonSoporte: false,
              );
            },
          );
        }

        if (pendienteDoc != null) {
          final m = pendienteDoc.data();
          final fechaSolicitada = m['fechaSolicitada'];
          final direccion = m['direccion'] as String? ?? '';
          final notas = m['notasAdicionales'] as String? ?? '';

          return _card(
            background: const Color(0xFFFFF8E1),
            borde: const Color(0xFFF57F17),
            cuerpo: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFF57F17), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscando profesional...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fecha y hora solicitada: ${_fmtFechaHora(fechaSolicitada)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (direccion.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Dirección: $direccion',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                      if (notas.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Notas: $notas',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            onCancelar: () async {
              try {
                await TurnoService().cancelarTurno(
                  turnoId: pendienteDoc.id,
                  familiarUid: uid,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Turno cancelado.'),
                    backgroundColor: Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo cancelar: $e'),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onChat: null,
            onSoporte: null,
            mostrarBotonCancelar: true,
            mostrarBotonChat: false,
            mostrarBotonSoporte: false,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: _kAzulVitta.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Estado del servicio',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available_rounded, color: _kAzulVitta, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sin servicio activo — solicitá un turno',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: _kAzulVitta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onLlamarSoporte,
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                label: const Text(
                  'Llamar a Soporte Vitta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAzulVitta,
                  side: const BorderSide(color: _kAzulVitta, width: 1.6),
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconoRadioPulso extends StatefulWidget {
  const _IconoRadioPulso({required this.color});

  final Color color;

  @override
  State<_IconoRadioPulso> createState() => _IconoRadioPulsoState();
}

class _IconoRadioPulsoState extends State<_IconoRadioPulso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.92 + (t * 0.18);
        final opacity = 0.75 + (t * 0.25);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.radio_button_checked_rounded,
              color: widget.color,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
