import 'package:flutter/material.dart';
import '../domain/profesional_domain.dart';

/// View-model de Profesional para presentación en UI.
/// Contiene solo datos y métodos relevantes para la interfaz.
class ProfesionalUI {
  ProfesionalUI({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.fotoUrl,
    required this.tipo,
    required this.calificacionPromedio,
    required this.cantidadResenas,
    required this.zona,
    required this.latitud,
    required this.longitud,
    required this.esNuevoTalento,
    required this.biografia,
    required this.etiquetas,
    required this.fortaleza,
    required this.disponibilidadManana,
    required this.disponibilidadTarde,
    required this.disponibilidadNoche,
    required this.estaValidado,
  });

  final String id;
  final String nombre;
  final String especialidad;
  final String fotoUrl;
  final String tipo;
  final double calificacionPromedio;
  final int cantidadResenas;
  final String? zona;
  final double? latitud;
  final double? longitud;
  final bool esNuevoTalento;
  final String? biografia;
  final List<String> etiquetas;
  final String? fortaleza;
  final bool disponibilidadManana;
  final bool disponibilidadTarde;
  final bool disponibilidadNoche;
  final bool estaValidado;

  /// Crear desde ProfesionalDomain
  factory ProfesionalUI.from(ProfesionalDomain domain) {
    return ProfesionalUI(
      id: domain.id,
      nombre: domain.nombre,
      especialidad: domain.especialidad,
      fotoUrl: domain.fotoUrl,
      tipo: domain.descripcionTipo,
      calificacionPromedio: domain.calificacionPromedio,
      cantidadResenas: domain.cantidadResenas,
      zona: domain.zona,
      latitud: domain.latitud,
      longitud: domain.longitud,
      esNuevoTalento: domain.esNuevoTalento,
      biografia: domain.biografia,
      etiquetas: domain.etiquetas,
      fortaleza: domain.fortaleza,
      disponibilidadManana: domain.disponibilidadManana,
      disponibilidadTarde: domain.disponibilidadTarde,
      disponibilidadNoche: domain.disponibilidadNoche,
      estaValidado: domain.estaValidado(),
    );
  }

  /// Obtener disponibilidad formateada
  String get disponibilidadFormato {
    final horarios = [
      if (disponibilidadManana) 'Mañana',
      if (disponibilidadTarde) 'Tarde',
      if (disponibilidadNoche) 'Noche',
    ];
    return horarios.isEmpty ? 'Sin disponibilidad' : horarios.join(', ');
  }

  /// Obtener calificación con formato
  String get calificacionFormato {
    if (cantidadResenas == 0) return 'Sin calificaciones';
    return '$calificacionPromedio/5.0';
  }

  /// Obtener badge de reputación
  String get badgeCalificacion {
    if (cantidadResenas == 0) return '';
    if (calificacionPromedio >= 4.5) return '⭐⭐⭐⭐⭐';
    if (calificacionPromedio >= 4.0) return '⭐⭐⭐⭐';
    if (calificacionPromedio >= 3.5) return '⭐⭐⭐';
    return '⭐⭐';
  }

  /// Badge de nuevo talento
  String get badgeNuevoTalento {
    return esNuevoTalento ? '🌟 Nuevo Talento' : '';
  }

  /// Color de estado de validación
  Color get colorEstado {
    if (!estaValidado) return Colors.grey;
    if (calificacionPromedio >= 4.5) return Colors.green;
    if (calificacionPromedio >= 4.0) return Colors.blue;
    return Colors.orange;
  }

  /// Ícono de estado
  IconData get iconoEstado {
    if (!estaValidado) return Icons.hourglass_empty_rounded;
    if (calificacionPromedio >= 4.5) return Icons.verified_rounded;
    return Icons.check_circle_rounded;
  }

  /// Texto de estado
  String get textoEstado {
    if (!estaValidado) return 'Validación pendiente';
    if (calificacionPromedio >= 4.5) return 'Profesional destacado';
    if (calificacionPromedio >= 4.0) return 'Muy calificado';
    return 'Disponible';
  }

  @override
  String toString() => 'ProfesionalUI(id: $id, nombre: $nombre)';
}
