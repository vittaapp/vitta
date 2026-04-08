import '../models/domain/profesional_domain.dart';
import '../models/entities/profesional_entity.dart';
import '../models/ui/profesional_ui.dart';

/// Mapper para convertir entre capas de Profesional.
/// Responsable de transformar datos entre Entity → Domain → UI
class ProfesionalMapper {
  /// Convertir ProfesionalEntity → ProfesionalDomain
  static ProfesionalDomain toDomain(ProfesionalEntity entity) {
    return ProfesionalDomain(
      id: entity.id,
      nombre: entity.nombre,
      email: entity.email,
      rol: entity.rol,
      tipo: entity.tipo,
      telefono: entity.telefono,
      fotoUrl: entity.fotoUrl,
      matriculaProfesional: entity.matriculaProfesional,
      nivel: entity.nivel,
      especialidad: entity.especialidad,
      institucionEducativa: entity.institucionEducativa,
      identidadValidada: entity.identidadValidada,
      disponibilidadManana: entity.disponibilidadManana,
      disponibilidadTarde: entity.disponibilidadTarde,
      disponibilidadNoche: entity.disponibilidadNoche,
      calificacionPromedio: entity.calificacionPromedio,
      cantidadResenas: entity.cantidadResenas,
      zona: entity.zona,
      latitud: entity.latitud,
      longitud: entity.longitud,
      esNuevoTalento: entity.esNuevoTalento,
      biografia: entity.biografia,
      etiquetas: entity.etiquetas,
      fortaleza: entity.fortaleza,
    );
  }

  /// Convertir ProfesionalDomain → ProfesionalUI (para presentación)
  static ProfesionalUI toUI(ProfesionalDomain domain) {
    return ProfesionalUI.from(domain);
  }

  /// Convertir ProfesionalEntity → ProfesionalUI directamente (sin dominio)
  static ProfesionalUI toUIFromEntity(ProfesionalEntity entity) {
    final domain = toDomain(entity);
    return toUI(domain);
  }

  /// Convertir ProfesionalDomain → ProfesionalEntity (para persistencia)
  static ProfesionalEntity toPersistence(ProfesionalDomain domain) {
    return ProfesionalEntity(
      id: domain.id,
      nombre: domain.nombre,
      email: domain.email,
      rol: domain.rol,
      tipo: domain.tipo,
      telefono: domain.telefono,
      fotoUrl: domain.fotoUrl,
      matriculaProfesional: domain.matriculaProfesional,
      nivel: domain.nivel,
      especialidad: domain.especialidad,
      institucionEducativa: domain.institucionEducativa,
      identidadValidada: domain.identidadValidada,
      disponibilidadManana: domain.disponibilidadManana,
      disponibilidadTarde: domain.disponibilidadTarde,
      disponibilidadNoche: domain.disponibilidadNoche,
      calificacionPromedio: domain.calificacionPromedio,
      cantidadResenas: domain.cantidadResenas,
      zona: domain.zona,
      latitud: domain.latitud,
      longitud: domain.longitud,
      esNuevoTalento: domain.esNuevoTalento,
      biografia: domain.biografia,
      etiquetas: domain.etiquetas,
      fortaleza: domain.fortaleza,
    );
  }
}
