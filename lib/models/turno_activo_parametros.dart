import 'package:flutter/foundation.dart';

/// Datos del turno y paciente pasados desde [AreaProfesionalView] a [TurnoActivoView].
@immutable
class TurnoActivoParametros {
  const TurnoActivoParametros({
    required this.turnoId,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.edad,
    required this.diagnosticoPrincipal,
    required this.alergiasImportantes,
    required this.direccionDomicilio,
  });

  final String turnoId;
  final String pacienteId;
  final String nombrePaciente;
  final String edad;
  final String diagnosticoPrincipal;
  final String alergiasImportantes;
  final String direccionDomicilio;
}
