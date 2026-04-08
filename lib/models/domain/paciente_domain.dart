import 'package:flutter/foundation.dart';
import '../entities/paciente_entity.dart';

/// Nivel de riesgo clínico del paciente.
enum NivelRiesgo {
  rojo,     // Crítico / Post-operatorio
  amarillo, // Intermedio / Medicación
  verde     // Bajo / Acompañamiento
}

/// Historia clínica del paciente (dominio).
@immutable
class HistoriaClinica {
  const HistoriaClinica({
    this.medicamentos = const [],
    this.alergias = const [],
    this.antecedentes = '',
    this.registrosDiarios = const [],
  });

  final List<String> medicamentos;
  final List<String> alergias;
  final String antecedentes;
  final List<String> registrosDiarios;

  HistoriaClinica copyWith({
    List<String>? medicamentos,
    List<String>? alergias,
    String? antecedentes,
    List<String>? registrosDiarios,
  }) {
    return HistoriaClinica(
      medicamentos: medicamentos ?? this.medicamentos,
      alergias: alergias ?? this.alergias,
      antecedentes: antecedentes ?? this.antecedentes,
      registrosDiarios: registrosDiarios ?? this.registrosDiarios,
    );
  }
}

/// Paciente como entidad de dominio con lógica de negocio.
/// Extiende PacienteEntity para heredar datos persistentes.
@immutable
class PacienteDomain extends PacienteEntity {
  const PacienteDomain({
    required super.id,
    required super.familiarId,
    required super.nombre,
    super.edad,
    super.nivelCuidado,
    super.planActivo,
    super.localidad,
    super.provincia,
    super.diagnostico,
    required this.riesgo,
    required this.historia,
  });

  /// Nivel de riesgo clínico del paciente
  final NivelRiesgo riesgo;

  /// Historia clínica con medicamentos, alergias, etc.
  final HistoriaClinica historia;

  /// Verificar si el paciente necesita seguimiento intensivo
  bool necesitaSeguimiento() {
    return riesgo == NivelRiesgo.rojo || riesgo == NivelRiesgo.amarillo;
  }

  /// Verificar si hay medicamentos registrados
  bool tieneMedicamentos() {
    return historia.medicamentos.isNotEmpty;
  }

  /// Verificar si hay alergias registradas
  bool tieneAlergias() {
    return historia.alergias.isNotEmpty;
  }

  /// Obtener descripción del riesgo
  String get descripcionRiesgo {
    switch (riesgo) {
      case NivelRiesgo.rojo:
        return 'Crítico - Requiere seguimiento intensivo';
      case NivelRiesgo.amarillo:
        return 'Intermedio - Requiere monitoreo regular';
      case NivelRiesgo.verde:
        return 'Bajo - Acompañamiento estándar';
    }
  }

  /// Crear una copia con algunos campos actualizados
  @override
  PacienteDomain copyWith({
    String? id,
    String? familiarId,
    String? nombre,
    int? edad,
    int? nivelCuidado,
    String? planActivo,
    String? localidad,
    String? provincia,
    String? diagnostico,
    NivelRiesgo? riesgo,
    HistoriaClinica? historia,
  }) {
    return PacienteDomain(
      id: id ?? this.id,
      familiarId: familiarId ?? this.familiarId,
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      nivelCuidado: nivelCuidado ?? this.nivelCuidado,
      planActivo: planActivo ?? this.planActivo,
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      diagnostico: diagnostico ?? this.diagnostico,
      riesgo: riesgo ?? this.riesgo,
      historia: historia ?? this.historia,
    );
  }

  @override
  String toString() =>
    'PacienteDomain(id: $id, nombre: $nombre, riesgo: $riesgo)';
}
