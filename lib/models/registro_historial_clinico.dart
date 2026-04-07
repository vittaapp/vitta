import 'package:flutter/foundation.dart';

import 'medicacion_historia_clinica.dart';
import 'signos_vitales.dart';

/// Tipos de entrada en `pacientes/{id}/historial/{registroId}` (Secc. 11).
enum TipoRegistroHistorial {
  turno,
  observacion,
  medicacion,
  emergencia,
}

/// Registro **inmutable** de historia clínica (cuidador / sistema). No editar ni borrar en Firestore.
@immutable
class RegistroHistorialClinico {
  const RegistroHistorialClinico({
    required this.id,
    required this.profesionalId,
    required this.turnoId,
    required this.fecha,
    required this.tipoRegistro,
    this.descripcion,
    this.estadoAnimo,
    this.signosVitales,
    this.medicacionAdministrada = const [],
    this.requiereSeguimiento = false,
    this.nombreProfesional,
  });

  final String id;
  final String profesionalId;
  final String turnoId;
  final DateTime fecha;
  final TipoRegistroHistorial tipoRegistro;
  /// Denormalizado desde Firestore (`nombreProfesional` al crear el registro).
  final String? nombreProfesional;
  final String? descripcion;
  final String? estadoAnimo;
  final SignosVitales? signosVitales;
  final List<MedicacionAdministradaItem> medicacionAdministrada;
  final bool requiereSeguimiento;

  Map<String, dynamic> toMap() => {
        'profesionalId': profesionalId,
        'turnoId': turnoId,
        'fecha': fecha.toIso8601String(),
        'tipoRegistro': tipoRegistro.name,
        if (descripcion != null) 'descripcion': descripcion,
        if (estadoAnimo != null) 'estadoAnimo': estadoAnimo,
        if (signosVitales != null && signosVitales!.tieneAlguno)
          'signosVitales': signosVitales!.toMap(),
        if (medicacionAdministrada.isNotEmpty)
          'medicacionAdministrada': medicacionAdministrada.map((e) => e.toMap()).toList(),
        'requiereSeguimiento': requiereSeguimiento,
      };

  factory RegistroHistorialClinico.fromMap(String id, Map<String, dynamic> map) {
    final tipoNombre = map['tipoRegistro'] as String? ?? 'turno';
    final tipo = TipoRegistroHistorial.values.firstWhere(
      (e) => e.name == tipoNombre,
      orElse: () => TipoRegistroHistorial.turno,
    );
    final meds = (map['medicacionAdministrada'] as List<dynamic>?)
            ?.map((e) => MedicacionAdministradaItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <MedicacionAdministradaItem>[];

    return RegistroHistorialClinico(
      id: id,
      profesionalId: map['profesionalId'] as String? ?? '',
      turnoId: map['turnoId'] as String? ?? '',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      tipoRegistro: tipo,
      nombreProfesional: map['nombreProfesional'] as String?,
      descripcion: map['descripcion'] as String?,
      estadoAnimo: map['estadoAnimo'] as String?,
      signosVitales: SignosVitales.fromMap(
        map['signosVitales'] != null ? Map<String, dynamic>.from(map['signosVitales'] as Map) : null,
      ),
      medicacionAdministrada: meds,
      requiereSeguimiento: map['requiereSeguimiento'] as bool? ?? false,
    );
  }
}
