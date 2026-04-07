import 'package:flutter/foundation.dart';

import 'medicacion_historia_clinica.dart';
import 'nivel_cuidado.dart';

/// Datos de historia clínica cargados por la **familia** — patologías, alergias, etc. (Secc. 21).
/// Distinto del registro por turno (`RegistroHistorialClinico`).
@immutable
class DatosHistoriaPaciente {
  const DatosHistoriaPaciente({
    required this.pacienteId,
    required this.nivelCuidado,
    this.edad,
    this.patologias = const [],
    this.alergias = const [],
    this.grupoSanguineo,
    this.medicacionHabitual = const [],
    this.observacionesFamilia,
  });

  final String pacienteId;
  final NivelCuidadoPaciente nivelCuidado;
  final int? edad;
  final List<String> patologias;
  final List<String> alergias;
  final String? grupoSanguineo;
  final List<MedicacionHabitualItem> medicacionHabitual;
  final String? observacionesFamilia;

  Map<String, dynamic> toMap() => {
        'pacienteId': pacienteId,
        'nivelCuidado': nivelCuidado.valor,
        if (edad != null) 'edad': edad,
        'patologias': patologias,
        'alergias': alergias,
        if (grupoSanguineo != null) 'grupoSanguineo': grupoSanguineo,
        'medicacionHabitual': medicacionHabitual.map((e) => e.toMap()).toList(),
        if (observacionesFamilia != null) 'observacionesFamilia': observacionesFamilia,
      };

  factory DatosHistoriaPaciente.fromMap(Map<String, dynamic> map) {
    final med = (map['medicacionHabitual'] as List<dynamic>?)
            ?.map((e) => MedicacionHabitualItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <MedicacionHabitualItem>[];

    return DatosHistoriaPaciente(
      pacienteId: map['pacienteId'] as String? ?? '',
      nivelCuidado: NivelCuidadoPaciente.desdeEntero((map['nivelCuidado'] as num?)?.toInt() ?? 1),
      edad: (map['edad'] as num?)?.toInt(),
      patologias: List<String>.from(map['patologias'] as List<dynamic>? ?? const []),
      alergias: List<String>.from(map['alergias'] as List<dynamic>? ?? const []),
      grupoSanguineo: map['grupoSanguineo'] as String?,
      medicacionHabitual: med,
      observacionesFamilia: map['observacionesFamilia'] as String?,
    );
  }
}
