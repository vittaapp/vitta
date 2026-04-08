import 'package:flutter/material.dart';
import '../domain/paciente_domain.dart';

/// View-model de Paciente para presentación en UI.
/// Contiene solo datos y métodos relevantes para la interfaz.
class PacienteUI {
  PacienteUI({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.colorRiesgo,
    required this.textoRiesgo,
    required this.iconoRiesgo,
    required this.diagnostico,
    required this.localidad,
    required this.provincia,
    required this.tieneMedicamentos,
    required this.tieneAlergias,
  });

  final String id;
  final String nombre;
  final int? edad;
  final Color colorRiesgo;
  final String textoRiesgo;
  final IconData iconoRiesgo;
  final String? diagnostico;
  final String? localidad;
  final String? provincia;
  final bool tieneMedicamentos;
  final bool tieneAlergias;

  /// Crear desde PacienteDomain
  factory PacienteUI.from(PacienteDomain domain) {
    return PacienteUI(
      id: domain.id,
      nombre: domain.nombre,
      edad: domain.edad,
      colorRiesgo: _colorParaRiesgo(domain.riesgo),
      textoRiesgo: domain.descripcionRiesgo,
      iconoRiesgo: _iconoParaRiesgo(domain.riesgo),
      diagnostico: domain.diagnostico,
      localidad: domain.localidad,
      provincia: domain.provincia,
      tieneMedicamentos: domain.tieneMedicamentos(),
      tieneAlergias: domain.tieneAlergias(),
    );
  }

  /// Obtener color según nivel de riesgo
  static Color _colorParaRiesgo(NivelRiesgo riesgo) {
    switch (riesgo) {
      case NivelRiesgo.rojo:
        return Colors.red;
      case NivelRiesgo.amarillo:
        return Colors.orange;
      case NivelRiesgo.verde:
        return Colors.green;
    }
  }

  /// Obtener ícono según nivel de riesgo
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

  /// Obtener ubicación formateada
  String get ubicacion {
    final partes = [
      if (localidad != null && localidad!.isNotEmpty) localidad,
      if (provincia != null && provincia!.isNotEmpty) provincia,
    ];
    return partes.join(', ');
  }

  /// Obtener edad formateada
  String get edadFormato {
    if (edad == null) return '—';
    return '$edad años';
  }

  /// Badge de medicamentos
  String get badgeMedicamentos {
    return tieneMedicamentos ? '💊' : '';
  }

  /// Badge de alergias
  String get badgeAlergias {
    return tieneAlergias ? '⚠️' : '';
  }

  @override
  String toString() => 'PacienteUI(id: $id, nombre: $nombre)';
}
