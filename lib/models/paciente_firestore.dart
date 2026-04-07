import 'package:flutter/foundation.dart';

/// Documento `pacientes/{id}` (vitta_rules / Firestore).
@immutable
class PacienteFirestore {
  const PacienteFirestore({
    required this.id,
    required this.familiarId,
    required this.nombre,
    this.edad,
    this.nivelCuidado,
    this.planActivo,
    this.localidad,
    this.provincia,
    this.diagnostico,
  });

  final String id;
  final String familiarId;
  final String nombre;
  final int? edad;
  /// 1 = N1, 2 = N2, 3 = N3 (registro paciente / `pacientes`).
  final int? nivelCuidado;
  final String? planActivo;
  final String? localidad;
  final String? provincia;
  final String? diagnostico;

  factory PacienteFirestore.fromDoc(String id, Map<String, dynamic> m) {
    return PacienteFirestore(
      id: id,
      familiarId: m['familiarId'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      edad: (m['edad'] as num?)?.toInt(),
      nivelCuidado: (m['nivelCuidado'] as num?)?.toInt(),
      planActivo: m['planActivo'] as String?,
      localidad: m['localidad'] as String?,
      provincia: m['provincia'] as String?,
      diagnostico: m['diagnostico'] as String?,
    );
  }
}
