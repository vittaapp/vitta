import 'package:flutter/material.dart';

/// Alcance y especialidad del profesional (no es una jerarquía “mejor / peor”).
enum BandejaPerfilProfesional {
  /// Cuidado y acompañamiento — estudiantes iniciales y cuidadores.
  celeste,

  /// Asistencia sanitaria — estudiantes avanzados y auxiliares.
  amarillo,

  /// Atención clínica — enfermeros y licenciados matriculados.
  verde,
}

extension BandejaPerfilProfesionalX on BandejaPerfilProfesional {
  String get tituloCategoria {
    switch (this) {
      case BandejaPerfilProfesional.celeste:
        return 'Acompañamiento y Paseos';
      case BandejaPerfilProfesional.amarillo:
        return 'Asistencia Sanitaria';
      case BandejaPerfilProfesional.verde:
        return 'Atención Clínica';
    }
  }

  String get etiquetaContexto {
    switch (this) {
      case BandejaPerfilProfesional.celeste:
        return 'Ideal para estudiantes y cuidadores';
      case BandejaPerfilProfesional.amarillo:
        return 'Control de signos vitales';
      case BandejaPerfilProfesional.verde:
        return 'Exclusivo matriculados';
    }
  }

  /// Título corto para ficha detalle (3 niveles de alcance).
  String get tituloNivelDetalle {
    switch (this) {
      case BandejaPerfilProfesional.celeste:
        return 'Acompañamiento';
      case BandejaPerfilProfesional.amarillo:
        return 'Asistencia';
      case BandejaPerfilProfesional.verde:
        return 'Clínica';
    }
  }

  Color get colorAcento {
    switch (this) {
      case BandejaPerfilProfesional.celeste:
        return const Color(0xFF87CEEB);
      case BandejaPerfilProfesional.amarillo:
        return const Color(0xFFF9A825);
      case BandejaPerfilProfesional.verde:
        return const Color(0xFF2E7D32);
    }
  }

  Color get colorFondoChip {
    switch (this) {
      case BandejaPerfilProfesional.celeste:
        return const Color(0xFFE8F6FC);
      case BandejaPerfilProfesional.amarillo:
        return const Color(0xFFFFF8E1);
      case BandejaPerfilProfesional.verde:
        return const Color(0xFFE8F5E9);
    }
  }
}

/// Orden por afinidad con la necesidad del paciente (alcance), no por “calidad”.
int prioridadBandejaParaNecesidad(
  BandejaPerfilProfesional bandeja,
  String? necesidadPaciente,
) {
  switch (necesidadPaciente) {
    case 'Acompañamiento':
    case 'Adulto Mayor':
      switch (bandeja) {
        case BandejaPerfilProfesional.celeste:
          return 0;
        case BandejaPerfilProfesional.amarillo:
          return 1;
        case BandejaPerfilProfesional.verde:
          return 2;
      }
    case 'Post-operatorio':
      switch (bandeja) {
        case BandejaPerfilProfesional.verde:
          return 0;
        case BandejaPerfilProfesional.amarillo:
          return 1;
        case BandejaPerfilProfesional.celeste:
          return 2;
      }
    case 'Pediatría':
    case 'Discapacidad':
      switch (bandeja) {
        case BandejaPerfilProfesional.verde:
          return 0;
        case BandejaPerfilProfesional.amarillo:
          return 1;
        case BandejaPerfilProfesional.celeste:
          return 2;
      }
    default:
      return bandeja.index;
  }
}
