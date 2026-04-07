import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/registro_historial_clinico.dart';
import '../services/historial_service.dart';

/// Últimos 20 registros de `historial_clinico` para el paciente, tiempo real, `fecha` descendente.
final bitacoraProvider =
    StreamProvider.autoDispose.family<List<RegistroHistorialClinico>, String>(
  (ref, pacienteId) {
    if (pacienteId.isEmpty) {
      return Stream<List<RegistroHistorialClinico>>.value(
        const <RegistroHistorialClinico>[],
      );
    }
    return FirebaseFirestore.instance
        .collection(HistorialService.coleccionHistorial)
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fecha', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RegistroHistorialClinico.fromMap(d.id, d.data()))
              .toList(),
        );
  },
);

/// Misma consulta sin tope para la pantalla de historial completo.
final historialClinicoCompletoProvider =
    StreamProvider.autoDispose.family<List<RegistroHistorialClinico>, String>(
  (ref, pacienteId) {
    if (pacienteId.isEmpty) {
      return Stream<List<RegistroHistorialClinico>>.value(
        const <RegistroHistorialClinico>[],
      );
    }
    return FirebaseFirestore.instance
        .collection(HistorialService.coleccionHistorial)
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RegistroHistorialClinico.fromMap(d.id, d.data()))
              .toList(),
        );
  },
);
