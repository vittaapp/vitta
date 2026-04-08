import 'package:flutter/material.dart';
import '../models/domain/paciente_domain.dart';
import '../models/entities/paciente_entity.dart';
import '../models/ui/paciente_ui.dart';

/// Mapper para convertir entre capas de Paciente.
/// Responsable de transformar datos entre Entity → Domain → UI
class PacienteMapper {
  /// Convertir PacienteEntity → PacienteDomain
  ///
  /// Requiere historia clínica para completar el dominio.
  static PacienteDomain toDomain(
    PacienteEntity entity,
    HistoriaClinica historia,
    NivelRiesgo riesgo,
  ) {
    return PacienteDomain(
      id: entity.id,
      familiarId: entity.familiarId,
      nombre: entity.nombre,
      edad: entity.edad,
      nivelCuidado: entity.nivelCuidado,
      planActivo: entity.planActivo,
      localidad: entity.localidad,
      provincia: entity.provincia,
      diagnostico: entity.diagnostico,
      riesgo: riesgo,
      historia: historia,
    );
  }

  /// Convertir PacienteDomain → PacienteUI (para presentación)
  static PacienteUI toUI(PacienteDomain domain) {
    return PacienteUI.from(domain);
  }

  /// Convertir PacienteEntity directamente a UI (si no hay lógica de dominio requerida)
  static PacienteUI toUIFromEntity(
    PacienteEntity entity,
    NivelRiesgo riesgo,
  ) {
    return PacienteUI(
      id: entity.id,
      nombre: entity.nombre,
      edad: entity.edad,
      colorRiesgo: _colorParaRiesgo(riesgo),
      textoRiesgo: _textoParaRiesgo(riesgo),
      iconoRiesgo: _iconoParaRiesgo(riesgo),
      diagnostico: entity.diagnostico,
      localidad: entity.localidad,
      provincia: entity.provincia,
      tieneMedicamentos: false,
      tieneAlergias: false,
    );
  }

  /// Convertir PacienteDomain → PacienteEntity (para persistencia)
  static PacienteEntity toPersistence(PacienteDomain domain) {
    return PacienteEntity(
      id: domain.id,
      familiarId: domain.familiarId,
      nombre: domain.nombre,
      edad: domain.edad,
      nivelCuidado: domain.nivelCuidado,
      planActivo: domain.planActivo,
      localidad: domain.localidad,
      provincia: domain.provincia,
      diagnostico: domain.diagnostico,
    );
  }

  // Helpers privados
  static Color _colorParaRiesgo(NivelRiesgo riesgo) {
    switch (riesgo) {
      case NivelRiesgo.rojo:
        return const Color(0xFFB71C1C);
      case NivelRiesgo.amarillo:
        return const Color(0xFFF57F17);
      case NivelRiesgo.verde:
        return const Color(0xFF2E7D32);
    }
  }

  static String _textoParaRiesgo(NivelRiesgo riesgo) {
    switch (riesgo) {
      case NivelRiesgo.rojo:
        return 'Crítico - Requiere seguimiento intensivo';
      case NivelRiesgo.amarillo:
        return 'Intermedio - Requiere monitoreo regular';
      case NivelRiesgo.verde:
        return 'Bajo - Acompañamiento estándar';
    }
  }

  static IconData _iconoParaRiesgo(NivelRiesgo riesgo) {
    switch (riesgo) {
      case NivelRiesgo.rojo:
        return Icons.warning_rounded;
      case NivelRiesgo.amarillo:
        return Icons.info_rounded;
      case NivelRiesgo.verde:
        return Icons.check_circle_rounded;
    }
  }
}
