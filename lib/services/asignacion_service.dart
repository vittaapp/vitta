import '../models/domain/paciente_domain.dart';
import '../models/domain/profesional_domain.dart';
import '../models/entities/profesional_entity.dart';

/// Servicio de asignación: filtra profesionales según el riesgo del paciente.
class AsignacionService {
  List<ProfesionalDomain> filtrarProfesionalesValidos(
    List<ProfesionalDomain> todosLosProfesionales,
    NivelRiesgo riesgoPaciente,
  ) {
    return todosLosProfesionales.where((pro) {
      switch (riesgoPaciente) {
        case NivelRiesgo.rojo:
          return pro.tipo == TipoProfesional.enfermeroUniversitario;
        case NivelRiesgo.amarillo:
          return pro.tipo == TipoProfesional.enfermeroUniversitario ||
              pro.tipo == TipoProfesional.auxiliarEnfermeria;
        case NivelRiesgo.verde:
          return true;
      }
    }).toList();
  }
}
