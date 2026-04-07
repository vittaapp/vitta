// lib/services/asignacion_service.dart
import '../models/profesional_model.dart';
import '../models/paciente_model.dart';

class AsignacionService {
  // Esta función filtra la lista de profesionales según el riesgo del paciente
  List<Profesional> filtrarProfesionalesValidos(
      List<Profesional> todosLosProfesionales, NivelRiesgo riesgoPaciente) {

    return todosLosProfesionales.where((pro) {
      // Aplicamos tu protocolo de seguridad directamente
      switch (riesgoPaciente) {
        case NivelRiesgo.rojo:
        // Solo enfermeros universitarios para casos críticos
          return pro.tipo == TipoProfesional.enfermeroUniversitario;

        case NivelRiesgo.amarillo:
        // Enfermeros o Auxiliares para medicación
          return pro.tipo == TipoProfesional.enfermeroUniversitario ||
              pro.tipo == TipoProfesional.auxiliarEnfermeria;

        case NivelRiesgo.verde:
        // Todos pueden atender casos de acompañamiento
          return true;
      }
    }).toList();
  }
}