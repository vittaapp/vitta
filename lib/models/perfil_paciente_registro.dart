import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Datos del paciente + cobertura y emergencias, listos para persistir y mostrar al cuidador.
class PerfilPacienteRegistro {
  /// Clave en [SharedPreferences] para que el cuidador u otras pantallas lean el perfil con un solo acceso.
  static const String prefsKey = 'vitta_perfil_paciente_registro';

  static Future<PerfilPacienteRegistro?> cargarGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    return fromPrefsString(prefs.getString(prefsKey));
  }

  static Future<void> guardar(PerfilPacienteRegistro perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(perfil.toJson()));
  }

  const PerfilPacienteRegistro({
    required this.nombrePaciente,
    required this.edadPaciente,
    this.necesidadPrincipal,
    required this.descripcionNecesidad,
    required this.ubicacionServicio,
    required this.obraSocialPrepaga,
    required this.telefonoEmergencia,
    required this.autorizaContactoEmergenciaDesdeApp,
  });

  final String nombrePaciente;
  final String edadPaciente;
  final String? necesidadPrincipal;
  final String descripcionNecesidad;
  final String ubicacionServicio;
  /// Cobertura médica del paciente (OS / prepaga).
  final String obraSocialPrepaga;
  /// Distinto al teléfono del familiar; ej. médico, SAME, familiar cercano.
  final String telefonoEmergencia;
  final bool autorizaContactoEmergenciaDesdeApp;

  Map<String, dynamic> toJson() => {
        'nombrePaciente': nombrePaciente,
        'edadPaciente': edadPaciente,
        'necesidadPrincipal': necesidadPrincipal,
        'descripcionNecesidad': descripcionNecesidad,
        'ubicacionServicio': ubicacionServicio,
        'obraSocialPrepaga': obraSocialPrepaga,
        'telefonoEmergencia': telefonoEmergencia,
        'autorizaContactoEmergenciaDesdeApp': autorizaContactoEmergenciaDesdeApp,
      };

  factory PerfilPacienteRegistro.fromJson(Map<String, dynamic> j) {
    return PerfilPacienteRegistro(
      nombrePaciente: j['nombrePaciente'] as String? ?? '',
      edadPaciente: j['edadPaciente'] as String? ?? '',
      necesidadPrincipal: j['necesidadPrincipal'] as String?,
      descripcionNecesidad: j['descripcionNecesidad'] as String? ?? '',
      ubicacionServicio: j['ubicacionServicio'] as String? ?? '',
      obraSocialPrepaga: j['obraSocialPrepaga'] as String? ?? '',
      telefonoEmergencia: j['telefonoEmergencia'] as String? ?? '',
      autorizaContactoEmergenciaDesdeApp:
          j['autorizaContactoEmergenciaDesdeApp'] as bool? ?? false,
    );
  }

  static PerfilPacienteRegistro? fromPrefsString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PerfilPacienteRegistro.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
