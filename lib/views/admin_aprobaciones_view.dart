import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/usuario_model.dart';
import 'login_view.dart';

/// Colores — `vitta_rules.md`
const Color _kAzulVitta = Color(0xFF1A3E6F);
const Color _kVerdeConfianza = Color(0xFF2E7D32);
const Color _kRojoEmergencia = Color(0xFFB71C1C);
const Color _kFondoApp = Color(0xFFE8EEF5);
const Color _kNivelN1 = Color(0xFF5DCAA5);
const Color _kNivelN2 = Color(0xFFF57F17);
const Color _kNivelN3 = Color(0xFF534AB7);

Color _colorChipNivel(int? nivel) {
  switch (nivel) {
    case 1:
      return _kNivelN1;
    case 2:
      return _kNivelN2;
    case 3:
      return _kNivelN3;
    default:
      return _kAzulVitta;
  }
}

String _etiquetaNivelCorto(int? nivel) {
  switch (nivel) {
    case 1:
      return 'N1';
    case 2:
      return 'N2';
    case 3:
      return 'N3';
    default:
      return '—';
  }
}

String _textoDisponibilidad(Map<String, dynamic> m) {
  final parts = <String>[];
  if (m['disponibilidadManana'] == true) parts.add('Mañana');
  if (m['disponibilidadTarde'] == true) parts.add('Tarde');
  if (m['disponibilidadNoche'] == true) parts.add('Noche');
  if (parts.isEmpty) return 'Sin indicar';
  return parts.join(' · ');
}

bool _pendienteDeAprobacion(Map<String, dynamic> m) {
  final v = m['verificado'];
  if (v is bool && v == true) return false;
  return true;
}

/// Panel de administración: aprobación de perfiles profesionales.
class AdminAprobacionesView extends StatelessWidget {
  const AdminAprobacionesView({super.key});

  static const double _botonMin = 56;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final queryPendientesBase = db
        .collection('usuarios')
        .where('perfilCompleto', isEqualTo: true)
        .where('rol', whereIn: [RolesVitta.profesional, RolesVitta.enfermeroN3]);

    final queryAprobados = db
        .collection('usuarios')
        .where('verificado', isEqualTo: true)
        .where('rol', whereIn: [RolesVitta.profesional, RolesVitta.enfermeroN3]);

    return Scaffold(
      backgroundColor: _kFondoApp,
      appBar: AppBar(
        title: const Text('Panel Admin Vitta'),
        backgroundColor: _kAzulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profesionales pendientes de aprobación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kAzulVitta,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: queryPendientesBase.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar: ${snap.error}',
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: _kAzulVitta),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                final pendientes = docs.where((d) {
                  return _pendienteDeAprobacion(d.data());
                }).toList();

                if (pendientes.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'No hay profesionales pendientes de aprobación.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                    ),
                  );
                }

                return Column(
                  children: pendientes.map((doc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TarjetaProfesionalPendiente(
                        doc: doc,
                        botonMin: _botonMin,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            _SeccionAprobadosColapsable(
              stream: queryAprobados.snapshots(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaProfesionalPendiente extends StatelessWidget {
  const _TarjetaProfesionalPendiente({
    required this.doc,
    required this.botonMin,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double botonMin;

  Future<void> _aprobar(BuildContext context) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    try {
      await doc.reference.update({
        'verificado': true,
        'verificadoAt': FieldValue.serverTimestamp(),
        'verificadoPor': adminUid,
        'rechazado': false,
        'motivoRechazo': FieldValue.delete(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profesional aprobado'),
          backgroundColor: _kVerdeConfianza,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo aprobar: $e'),
          backgroundColor: _kRojoEmergencia,
        ),
      );
    }
  }

  Future<void> _rechazar(BuildContext context) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DialogMotivoRechazo(),
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    final motivoTrim = motivo.trim();

    final data = doc.data();
    final token = (data['fcmToken'] as String?)?.trim() ?? '';
    final uid = doc.id;

    try {
      await doc.reference.update({
        'verificado': false,
        'rechazado': true,
        'motivoRechazo': motivoTrim,
      });

      if (token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notificaciones_pendientes').add({
          'destinatarioId': uid,
          'token': token,
          'titulo': 'Perfil no aprobado',
          'cuerpo': motivoTrim,
          'tipo': 'perfil_rechazado',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rechazo registrado y notificación enviada'),
          backgroundColor: _kAzulVitta,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _kRojoEmergencia,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = doc.data();
    final nombre = (m['nombre'] as String?)?.trim() ?? '—';
    final email = (m['email'] as String?)?.trim() ?? '—';
    final nivel = (m['nivel'] as num?)?.toInt();
    final matricula = (m['matriculaProfesional'] as String?)?.trim() ?? '—';
    final especialidad = (m['especialidad'] as String?)?.trim() ?? '—';
    final disp = _textoDisponibilidad(m);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kAzulVitta,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _etiquetaNivelCorto(nivel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  backgroundColor: _colorChipNivel(nivel),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _filaInfo(Icons.email_outlined, email),
            const SizedBox(height: 6),
            _filaInfo(Icons.badge_outlined, 'Matrícula: $matricula'),
            const SizedBox(height: 6),
            _filaInfo(Icons.medical_services_outlined, especialidad),
            const SizedBox(height: 6),
            _filaInfo(Icons.schedule_outlined, 'Disponibilidad: $disp'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _aprobar(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kVerdeConfianza,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(botonMin),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aprobar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rechazar(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kRojoEmergencia,
                      side: const BorderSide(color: _kRojoEmergencia, width: 1.6),
                      minimumSize: Size.fromHeight(botonMin),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Rechazar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _filaInfo(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade900, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _DialogMotivoRechazo extends StatefulWidget {
  const _DialogMotivoRechazo();

  @override
  State<_DialogMotivoRechazo> createState() => _DialogMotivoRechazoState();
}

class _DialogMotivoRechazoState extends State<_DialogMotivoRechazo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Motivo del rechazo',
        style: TextStyle(color: _kAzulVitta, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Escribí el motivo que verá el profesional…',
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final t = _controller.text.trim();
            if (t.isEmpty) return;
            Navigator.pop(context, t);
          },
          style: FilledButton.styleFrom(
            backgroundColor: _kRojoEmergencia,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 56),
          ),
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}

class _SeccionAprobadosColapsable extends StatelessWidget {
  const _SeccionAprobadosColapsable({
    required this.stream,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            'Error lista aprobados: ${snap.error}',
            style: TextStyle(color: Colors.red.shade800),
          );
        }

        final docs = snap.data?.docs ?? [];
        final ordenados = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
        ordenados.sort((a, b) {
          final ta = a.data()['verificadoAt'];
          final tb = b.data()['verificadoAt'];
          if (ta is Timestamp && tb is Timestamp) {
            return tb.compareTo(ta);
          }
          return 0;
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Profesionales aprobados',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kAzulVitta,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kVerdeConfianza.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${ordenados.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _kVerdeConfianza,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              if (snap.connectionState == ConnectionState.waiting && docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: _kAzulVitta),
                  ),
                )
              else if (ordenados.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    'Todavía no hay profesionales aprobados.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ordenados.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, i) {
                    final d = ordenados[i];
                    final m = d.data();
                    final nombre = (m['nombre'] as String?)?.trim() ?? '—';
                    final nivel = (m['nivel'] as num?)?.toInt();
                    final va = m['verificadoAt'];
                    String fechaStr = '—';
                    if (va is Timestamp) {
                      final dt = va.toDate();
                      fechaStr =
                          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _kAzulVitta,
                        ),
                      ),
                      subtitle: Text(
                        'Nivel ${_etiquetaNivelCorto(nivel)} · Aprobado: $fechaStr',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _colorChipNivel(nivel).withValues(alpha: 0.2),
                        child: Text(
                          _etiquetaNivelCorto(nivel),
                          style: TextStyle(
                            color: _colorChipNivel(nivel),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
