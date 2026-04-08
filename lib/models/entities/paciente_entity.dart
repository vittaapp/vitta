import 'package:flutter/foundation.dart';

/// Documento `pacientes/{id}` en Firestore.
/// Fuente única de datos persistentes para pacientes.
@immutable
class PacienteEntity {
  const PacienteEntity({
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

  /// 1 = N1, 2 = N2, 3 = N3
  final int? nivelCuidado;

  final String? planActivo;
  final String? localidad;
  final String? provincia;
  final String? diagnostico;

  /// Crear desde documento de Firestore
  factory PacienteEntity.fromDoc(String id, Map<String, dynamic> m) {
    return PacienteEntity(
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

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familiarId': familiarId,
      'nombre': nombre,
      'edad': edad,
      'nivelCuidado': nivelCuidado,
      'planActivo': planActivo,
      'localidad': localidad,
      'provincia': provincia,
      'diagnostico': diagnostico,
    };
  }

  /// Crear copia con algunos campos actualizados
  PacienteEntity copyWith({
    String? id,
    String? familiarId,
    String? nombre,
    int? edad,
    int? nivelCuidado,
    String? planActivo,
    String? localidad,
    String? provincia,
    String? diagnostico,
  }) {
    return PacienteEntity(
      id: id ?? this.id,
      familiarId: familiarId ?? this.familiarId,
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      nivelCuidado: nivelCuidado ?? this.nivelCuidado,
      planActivo: planActivo ?? this.planActivo,
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      diagnostico: diagnostico ?? this.diagnostico,
    );
  }

  @override
  String toString() => 'PacienteEntity(id: $id, nombre: $nombre)';
}
