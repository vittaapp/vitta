/// Valores del campo `rol` en Firestore — alineado a `vitta_rules.md` / cursor rules.
class RolesVitta {
  RolesVitta._();

  static const String familiar = 'familiar';
  static const String profesional = 'profesional';
  /// En documentos: `enfermero_n3`.
  static const String enfermeroN3 = 'enfermero_n3';
  static const String medico = 'medico';
  static const String admin = 'admin';
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String fotoUrl;
  /// Ver [RolesVitta].
  final String rol;
  /// Matrícula profesional (enfermero/a, médico/a, etc.) para trazabilidad legal en historial.
  final String? matriculaProfesional;
  /// 1 = N1, 2 = N2, 3 = N3 — perfil profesional (`usuarios/{uid}`).
  final int? nivel;
  final String? especialidad;
  final String? institucionEducativa;
  final bool disponibilidadManana;
  final bool disponibilidadTarde;
  final bool disponibilidadNoche;
  final bool? perfilCompleto;
  final List<String> pacientesIds;
  /// Solo en memoria (sesión); no se persiste en Firestore.
  final bool tienePacienteRegistrado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.fotoUrl = "",
    this.matriculaProfesional,
    this.nivel,
    this.especialidad,
    this.institucionEducativa,
    this.disponibilidadManana = false,
    this.disponibilidadTarde = false,
    this.disponibilidadNoche = false,
    this.perfilCompleto,
    this.pacientesIds = const [],
    this.tienePacienteRegistrado = false,
  });

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? fotoUrl,
    String? rol,
    String? matriculaProfesional,
    int? nivel,
    String? especialidad,
    String? institucionEducativa,
    bool? disponibilidadManana,
    bool? disponibilidadTarde,
    bool? disponibilidadNoche,
    bool? perfilCompleto,
    List<String>? pacientesIds,
    bool? tienePacienteRegistrado,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      rol: rol ?? this.rol,
      matriculaProfesional: matriculaProfesional ?? this.matriculaProfesional,
      nivel: nivel ?? this.nivel,
      especialidad: especialidad ?? this.especialidad,
      institucionEducativa: institucionEducativa ?? this.institucionEducativa,
      disponibilidadManana: disponibilidadManana ?? this.disponibilidadManana,
      disponibilidadTarde: disponibilidadTarde ?? this.disponibilidadTarde,
      disponibilidadNoche: disponibilidadNoche ?? this.disponibilidadNoche,
      perfilCompleto: perfilCompleto ?? this.perfilCompleto,
      pacientesIds: pacientesIds ?? this.pacientesIds,
      tienePacienteRegistrado:
          tienePacienteRegistrado ?? this.tienePacienteRegistrado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'fotoUrl': fotoUrl,
      'rol': rol,
      if (matriculaProfesional != null) 'matriculaProfesional': matriculaProfesional,
      if (nivel != null) 'nivel': nivel,
      if (especialidad != null) 'especialidad': especialidad,
      if (institucionEducativa != null) 'institucionEducativa': institucionEducativa,
      'disponibilidadManana': disponibilidadManana,
      'disponibilidadTarde': disponibilidadTarde,
      'disponibilidadNoche': disponibilidadNoche,
      if (perfilCompleto != null) 'perfilCompleto': perfilCompleto,
      'pacientesIds': pacientesIds,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] as String? ?? RolesVitta.familiar,
      telefono: map['telefono'],
      fotoUrl: map['fotoUrl'] ?? '',
      matriculaProfesional: map['matriculaProfesional'] as String?,
      nivel: (map['nivel'] as num?)?.toInt(),
      especialidad: map['especialidad'] as String?,
      institucionEducativa: map['institucionEducativa'] as String?,
      disponibilidadManana: map['disponibilidadManana'] as bool? ?? false,
      disponibilidadTarde: map['disponibilidadTarde'] as bool? ?? false,
      disponibilidadNoche: map['disponibilidadNoche'] as bool? ?? false,
      perfilCompleto: map['perfilCompleto'] as bool?,
      pacientesIds: List<String>.from(map['pacientesIds'] ?? []),
    );
  }
}