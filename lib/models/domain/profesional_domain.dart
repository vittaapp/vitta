import 'package:flutter/foundation.dart';
import '../entities/profesional_entity.dart';

/// Profesional como entidad de dominio con lógica de negocio.
/// Extiende ProfesionalEntity para heredar datos persistentes.
@immutable
class ProfesionalDomain extends ProfesionalEntity {
  const ProfesionalDomain({
    required super.id,
    required super.nombre,
    required super.email,
    required super.rol,
    required super.tipo,
    super.telefono,
    super.fotoUrl,
    super.matriculaProfesional,
    super.nivel,
    super.especialidad,
    super.institucionEducativa,
    super.identidadValidada,
    super.disponibilidadManana,
    super.disponibilidadTarde,
    super.disponibilidadNoche,
    super.calificacionPromedio,
    super.cantidadResenas,
    super.zona,
    super.latitud,
    super.longitud,
    super.esNuevoTalento,
    super.biografia,
    super.etiquetas,
    super.fortaleza,
  });

  /// Verificar si puede atender un nivel de riesgo específico.
  ///
  /// - Enfermero universitario: Atiende todos los niveles
  /// - Auxiliar enfermería: Atiende Amarillo y Verde
  /// - Cuidador: Atiende solo Verde
  bool puedeAtenderRiesgo(String nivelRiesgo) {
    final riesgo = nivelRiesgo.toLowerCase();

    switch (tipo) {
      case TipoProfesional.enfermeroUniversitario:
        return true; // Atiende todos: Rojo, Amarillo, Verde

      case TipoProfesional.auxiliarEnfermeria:
        return riesgo != 'rojo'; // Atiende Amarillo y Verde

      case TipoProfesional.cuidadorDomiciliario:
        return riesgo == 'verde'; // Solo Verde
    }
  }

  /// Verificar si está disponible en algún horario
  bool estaDisponible() {
    return disponibilidadManana || disponibilidadTarde || disponibilidadNoche;
  }

  /// Obtener descripción del tipo de profesional
  String get descripcionTipo {
    switch (tipo) {
      case TipoProfesional.enfermeroUniversitario:
        return 'Enfermero/a Universitario/a';
      case TipoProfesional.auxiliarEnfermeria:
        return 'Auxiliar de Enfermería';
      case TipoProfesional.cuidadorDomiciliario:
        return 'Cuidador/a Domiciliario/a';
    }
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

  /// Verificar si tiene reputación establecida
  bool tieneResenas() {
    return cantidadResenas > 0;
  }

  /// Obtener calificación con formato
  String get calificacionFormato {
    if (!tieneResenas()) return 'Sin calificaciones';
    return '$calificacionPromedio/5 ($cantidadResenas reseñas)';
  }

  /// Verificar si está validado y listo para trabajar
  bool estaValidado() {
    return identidadValidada && estaDisponible();
  }

  @override
  ProfesionalDomain copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    TipoProfesional? tipo,
    String? telefono,
    String? fotoUrl,
    String? matriculaProfesional,
    int? nivel,
    String? especialidad,
    String? institucionEducativa,
    bool? identidadValidada,
    bool? disponibilidadManana,
    bool? disponibilidadTarde,
    bool? disponibilidadNoche,
    double? calificacionPromedio,
    int? cantidadResenas,
    String? zona,
    double? latitud,
    double? longitud,
    bool? esNuevoTalento,
    String? biografia,
    List<String>? etiquetas,
    String? fortaleza,
  }) {
    return ProfesionalDomain(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      tipo: tipo ?? this.tipo,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      matriculaProfesional: matriculaProfesional ?? this.matriculaProfesional,
      nivel: nivel ?? this.nivel,
      especialidad: especialidad ?? this.especialidad,
      institucionEducativa: institucionEducativa ?? this.institucionEducativa,
      identidadValidada: identidadValidada ?? this.identidadValidada,
      disponibilidadManana: disponibilidadManana ?? this.disponibilidadManana,
      disponibilidadTarde: disponibilidadTarde ?? this.disponibilidadTarde,
      disponibilidadNoche: disponibilidadNoche ?? this.disponibilidadNoche,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
      cantidadResenas: cantidadResenas ?? this.cantidadResenas,
      zona: zona ?? this.zona,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      esNuevoTalento: esNuevoTalento ?? this.esNuevoTalento,
      biografia: biografia ?? this.biografia,
      etiquetas: etiquetas ?? this.etiquetas,
      fortaleza: fortaleza ?? this.fortaleza,
    );
  }

  @override
  String toString() =>
    'ProfesionalDomain(id: $id, nombre: $nombre, tipo: $tipo)';
}
