import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/registro_historial_clinico.dart';
import '../services/historial_service.dart';

/// Últimos 20 registros de `historial_clinico` para el paciente, tiempo real, `fecha` descendente.
/// Ordena en memoria para evitar requerir índice compuesto en Firestore.
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
        .limit(20)
        .snapshots()
        .map(
          (snap) {
            final lista = snap.docs
                .map((d) => RegistroHistorialClinico.fromMap(d.id, d.data()))
                .toList()
              ..sort((a, b) => b.fecha.compareTo(a.fecha));
            return lista;
          },
        );
  },
);

/// Misma consulta sin tope para la pantalla de historial completo.
/// Ordena en memoria para evitar requerir índice compuesto en Firestore.
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
        .snapshots()
        .map(
          (snap) {
            final lista = snap.docs
                .map((d) => RegistroHistorialClinico.fromMap(d.id, d.data()))
                .toList()
              ..sort((a, b) => b.fecha.compareTo(a.fecha));
            return lista;
          },
        );
  },
);
