import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/turno_service.dart';
import '../../providers/usuario_rol_provider.dart';
import 'turno_card_widget.dart';

const Color _azulVitta = Color(0xFF0066CC);

/// Panel que muestra los turnos asignados al profesional.
/// Utiliza ConsumerWidget para acceder a providers de Riverpod.
class ProfessionalTurnosPanelWidget extends ConsumerWidget {
  const ProfessionalTurnosPanelWidget({
    Key? key,
    required this.minButtonHeight,
  }) : super(key: key);

  final double minButtonHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final usuario = ref.watch(usuarioActualProvider).value;
    final nivel = TurnoService.nivelProfesionalDesdeRol(usuario?.rol);

    // Validar que el usuario está autenticado y tiene nivel
    if (uid == null || nivel == 0) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tu perfil no está habilitado para gestionar turnos.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.35),
          ),
        ),
      );
    }

    // Stream de turnos para el profesional
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TurnoService().obtenerTurnosProfesional(
        uid: uid,
        nivelProfesional: nivel,
      ),
      builder: (context, snapshot) {
        // Manejo de errores
        if (snapshot.hasError) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No se pudieron cargar los turnos: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          );
        }

        // Cargando
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: _azulVitta),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Sin turnos
        if (docs.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No tenés turnos pendientes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Lista de turnos
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < docs.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              TurnoCardWidget(
                doc: docs[i],
                uid: uid,
                minButtonHeight: minButtonHeight,
              ),
            ],
          ],
        );
      },
    );
  }
}
