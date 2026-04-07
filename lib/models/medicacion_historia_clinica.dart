import 'package:flutter/foundation.dart';

/// Una línea de medicación **administrada en el turno** — inmutable (Secc. 11 y 21).
///
/// Firestore: `medicacionAdministrada: [{ nombre, dosis, hora }]`
@immutable
class MedicacionAdministradaItem {
  const MedicacionAdministradaItem({
    required this.nombre,
    required this.dosis,
    required this.hora,
  });

  final String nombre;
  final String dosis;
  /// ISO-8601 o `HH:mm` según convención del backend.
  final String hora;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'dosis': dosis,
        'hora': hora,
      };

  factory MedicacionAdministradaItem.fromMap(Map<String, dynamic> map) {
    return MedicacionAdministradaItem(
      nombre: map['nombre'] as String? ?? '',
      dosis: map['dosis'] as String? ?? '',
      hora: map['hora'] as String? ?? '',
    );
  }
}

/// Medicación **habitual** cargada por la familia — baseline editable por ellos,
/// modelada como inmutable por snapshot al leer/guardar (Secc. 21).
@immutable
class MedicacionHabitualItem {
  const MedicacionHabitualItem({
    required this.nombre,
    required this.dosis,
    this.frecuencia,
    this.observaciones,
  });

  final String nombre;
  final String dosis;
  final String? frecuencia;
  final String? observaciones;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'dosis': dosis,
        if (frecuencia != null) 'frecuencia': frecuencia,
        if (observaciones != null) 'observaciones': observaciones,
      };

  factory MedicacionHabitualItem.fromMap(Map<String, dynamic> map) {
    return MedicacionHabitualItem(
      nombre: map['nombre'] as String? ?? '',
      dosis: map['dosis'] as String? ?? '',
      frecuencia: map['frecuencia'] as String?,
      observaciones: map['observaciones'] as String?,
    );
  }
}
