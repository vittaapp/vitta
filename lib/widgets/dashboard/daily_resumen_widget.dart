import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/resumen_diario_service.dart';

// Color constante
const Color _kAzulVitta = Color(0xFF0066CC);

/// Widget que muestra el resumen del día del paciente.
/// 
/// Obtiene y genera el resumen del turno completado del día.
/// Si no hay turno completado, no muestra nada.
/// 
/// Parámetro:
/// - `pacienteId`: ID del paciente para obtener su resumen
class DailyResumenWidget extends StatefulWidget {
  const DailyResumenWidget({
    Key? key,
    required this.pacienteId,
  }) : super(key: key);

  final String pacienteId;

  @override
  State<DailyResumenWidget> createState() => _DailyResumenWidgetState();
}

class _DailyResumenWidgetState extends State<DailyResumenWidget> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _future = _cargar(widget.pacienteId, uid);
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _cargar(
    String pacienteId,
    String uid,
  ) async {
    await ResumenDiarioService().generarResumenDelDia(pacienteId, uid);
    return FirebaseFirestore.instance
        .collection(ResumenDiarioService.coleccionResumenes)
        .doc(ResumenDiarioService.documentoIdHoy(pacienteId))
        .get();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final doc = snap.data;
        if (doc == null || !doc.exists) return const SizedBox.shrink();
        final data = doc.data()!;
        if (data['tieneTurnoCompletadoHoy'] != true) {
          return const SizedBox.shrink();
        }
        final texto = (data['textoResumen'] as String?)?.trim() ?? '';
        if (texto.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen de hoy',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _kAzulVitta,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
              ),
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
