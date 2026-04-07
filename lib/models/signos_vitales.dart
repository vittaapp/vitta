import 'package:flutter/foundation.dart';

/// Signos vitales registrados en un turno — **inmutables** tras creación (Secc. 11 y 21).
///
/// Firestore: `signosVitales: { tension, temperatura, frecuenciaCardiaca }`
@immutable
class SignosVitales {
  const SignosVitales({
    this.tensionArterial,
    this.temperaturaCelsius,
    this.frecuenciaCardiacaLpm,
    this.saturacionOxigenoPct,
    this.frecuenciaRespiratoriaLpm,
    this.glucemiaMgDl,
  });

  /// Ej. `"120/80"` o formato acordado con el protocolo clínico.
  final String? tensionArterial;
  final double? temperaturaCelsius;
  final int? frecuenciaCardiacaLpm;
  final int? saturacionOxigenoPct;
  final int? frecuenciaRespiratoriaLpm;
  final int? glucemiaMgDl;

  bool get tieneAlguno =>
      tensionArterial != null ||
      temperaturaCelsius != null ||
      frecuenciaCardiacaLpm != null ||
      saturacionOxigenoPct != null ||
      frecuenciaRespiratoriaLpm != null ||
      glucemiaMgDl != null;

  Map<String, dynamic> toMap() => {
        if (tensionArterial != null) 'tension': tensionArterial,
        if (temperaturaCelsius != null) 'temperatura': temperaturaCelsius,
        if (frecuenciaCardiacaLpm != null) 'frecuenciaCardiaca': frecuenciaCardiacaLpm,
        if (saturacionOxigenoPct != null) 'saturacionOxigeno': saturacionOxigenoPct,
        if (frecuenciaRespiratoriaLpm != null) 'frecuenciaRespiratoria': frecuenciaRespiratoriaLpm,
        if (glucemiaMgDl != null) 'glucemia': glucemiaMgDl,
      };

  factory SignosVitales.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const SignosVitales();
    return SignosVitales(
      tensionArterial: map['tension'] as String?,
      temperaturaCelsius: (map['temperatura'] as num?)?.toDouble(),
      frecuenciaCardiacaLpm: (map['frecuenciaCardiaca'] as num?)?.toInt(),
      saturacionOxigenoPct: (map['saturacionOxigeno'] as num?)?.toInt(),
      frecuenciaRespiratoriaLpm: (map['frecuenciaRespiratoria'] as num?)?.toInt(),
      glucemiaMgDl: (map['glucemia'] as num?)?.toInt(),
    );
  }
}
