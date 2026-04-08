import 'package:flutter/foundation.dart';

/// Tipo de profesional sanitario.
enum TipoProfesional {
  enfermeroUniversitario,
  auxiliarEnfermeria,
  cuidadorDomiciliario
}

/// Documento `usuarios/{id}` para profesionales en Firestore.
/// Fuente única de datos persistentes para profesionales.
@immutable
class ProfesionalEntity {
  const ProfesionalEntity({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.tipo,
    this.telefono,
    this.fotoUrl = '',
    this.matriculaProfesional,
    this.nivel,
    this.especialidad = 'General',
    this.institucionEducativa,
    this.identidadValidada = false,
    this.disponibilidadManana = false,
    this.disponibilidadTarde = false,
    this.disponibilidadNoche = false,
    this.calificacionPromedio = 0.0,
    this.cantidadResenas = 0,
    this.zona,
    this.latitud,
    this.longitud,
    this.esNuevoTalento = false,
    this.biografia,
    this.etiquetas = const [],
    this.fortaleza,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol; // De RolesVitta
  final TipoProfesional tipo;
  final String? telefono;
  final String fotoUrl;
  final String? matriculaProfesional;

  /// 1 = N1, 2 = N2, 3 = N3
  final int? nivel;

  final String especialidad;
  final String? institucionEducativa;
  final bool identidadValidada;
  final bool disponibilidadManana;
  final bool disponibilidadTarde;
  final bool disponibilidadNoche;

  // Reputación y ubicación
  final double calificacionPromedio;
  final int cantidadResenas;
  final String? zona;
  final double? latitud;
  final double? longitud;
  final bool esNuevoTalento;
  final String? biografia;
  final List<String> etiquetas;
  final String? fortaleza;

  /// Crear desde documento de Firestore
  factory ProfesionalEntity.fromDoc(String id, Map<String, dynamic> m) {
    return ProfesionalEntity(
      id: id,
      nombre: m['nombre'] as String? ?? '',
      email: m['email'] as String? ?? '',
      rol: m['rol'] as String? ?? 'profesional',
      tipo: _tipoDeProfesional(m['tipo'] as String?),
      telefono: m['telefono'] as String?,
      fotoUrl: m['fotoUrl'] as String? ?? '',
      matriculaProfesional: m['matriculaProfesional'] as String?,
      nivel: (m['nivel'] as num?)?.toInt(),
      especialidad: m['especialidad'] as String? ?? 'General',
      institucionEducativa: m['institucionEducativa'] as String?,
      identidadValidada: m['identidadValidada'] as bool? ?? false,
      disponibilidadManana: m['disponibilidadManana'] as bool? ?? false,
      disponibilidadTarde: m['disponibilidadTarde'] as bool? ?? false,
      disponibilidadNoche: m['disponibilidadNoche'] as bool? ?? false,
      calificacionPromedio: (m['calificacionPromedio'] as num?)?.toDouble() ?? 0.0,
      cantidadResenas: (m['cantidadResenas'] as num?)?.toInt() ?? 0,
      zona: m['zona'] as String?,
      latitud: (m['latitud'] as num?)?.toDouble(),
      longitud: (m['longitud'] as num?)?.toDouble(),
      esNuevoTalento: m['esNuevoTalento'] as bool? ?? false,
      biografia: m['biografia'] as String?,
      etiquetas: List<String>.from(m['etiquetas'] as List? ?? []),
      fortaleza: m['fortaleza'] as String?,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'tipo': tipo.toString().split('.').last,
      'telefono': telefono,
      'fotoUrl': fotoUrl,
      'matriculaProfesional': matriculaProfesional,
      'nivel': nivel,
      'especialidad': especialidad,
      'institucionEducativa': institucionEducativa,
      'identidadValidada': identidadValidada,
      'disponibilidadManana': disponibilidadManana,
      'disponibilidadTarde': disponibilidadTarde,
      'disponibilidadNoche': disponibilidadNoche,
      'calificacionPromedio': calificacionPromedio,
      'cantidadResenas': cantidadResenas,
      'zona': zona,
      'latitud': latitud,
      'longitud': longitud,
      'esNuevoTalento': esNuevoTalento,
      'biografia': biografia,
      'etiquetas': etiquetas,
      'fortaleza': fortaleza,
    };
  }

  /// Crear copia con algunos campos actualizados
  ProfesionalEntity copyWith({
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
    return ProfesionalEntity(
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
  String toString() => 'ProfesionalEntity(id: $id, nombre: $nombre, tipo: $tipo)';
}

/// Helper para convertir string a TipoProfesional
TipoProfesional _tipoDeProfesional(String? value) {
  switch (value) {
    case 'enfermeroUniversitario':
      return TipoProfesional.enfermeroUniversitario;
    case 'auxiliarEnfermeria':
      return TipoProfesional.auxiliarEnfermeria;
    case 'cuidadorDomiciliario':
      return TipoProfesional.cuidadorDomiciliario;
    default:
      return TipoProfesional.cuidadorDomiciliario;
  }
}
