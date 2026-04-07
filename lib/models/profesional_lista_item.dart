import 'bandeja_perfil_profesional.dart';

/// Datos de presentación para la lista y la ficha de detalle del profesional.
class ProfesionalListaItem {
  const ProfesionalListaItem({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.fotoUrl,
    required this.bandeja,
    required this.semaforoConfianzaVerde,
    required this.biografia,
    required this.etiquetas,
    required this.fuerte,
    required this.calificacionPromedio,
    required this.cantidadResenas,
    required this.zona,
    required this.latitud,
    required this.longitud,
    required this.esNuevoTalento,
    required this.disponibilidadManana,
    required this.disponibilidadTarde,
    required this.disponibilidadNoche,
  });

  final String id;
  final String nombre;
  final String especialidad;
  final String fotoUrl;
  final BandejaPerfilProfesional bandeja;
  final bool semaforoConfianzaVerde;
  final String biografia;
  final List<String> etiquetas;
  /// Una línea: fortaleza principal (tarjeta lista).
  final String fuerte;

  /// Promedio 1.0–5.0 (familias que calificaron).
  final double calificacionPromedio;

  /// Cuántas familias dejaron reseña.
  final int cantidadResenas;

  /// Zona aproximada en Tucumán (sin calle ni número).
  final String zona;

  /// Solo para calcular distancia respecto al familiar; no mostrar en UI.
  final double latitud;
  final double longitud;

  /// Perfil reciente: priorizar etiqueta «Nuevo Talento».
  final bool esNuevoTalento;

  /// Franjas habituales de contacto (demo / agenda).
  final bool disponibilidadManana;
  final bool disponibilidadTarde;
  final bool disponibilidadNoche;
}
