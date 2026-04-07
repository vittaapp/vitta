import 'dart:math' as math;

import '../models/perfil_paciente_registro.dart';

/// Punto de referencia del familiar (Tucumán) según zona del registro; sin dirección exacta.
({double lat, double lon}) referenciaFamiliarTucuman(PerfilPacienteRegistro? perfil) {
  final u = perfil?.ubicacionServicio.toLowerCase().trim() ?? '';
  if (u.contains('yerba buena')) return (lat: -26.8167, lon: -65.3167);
  if (u.contains('tafí') || u.contains('tafi')) return (lat: -26.7333, lon: -65.2667);
  if (u.contains('barrio norte')) return (lat: -26.805, lon: -65.21);
  return (lat: -26.8241, lon: -65.2226);
}

double _rad(double deg) => deg * math.pi / 180;

/// Distancia en km (Haversine).
double distanciaKmHaversine(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthKm * c;
}
