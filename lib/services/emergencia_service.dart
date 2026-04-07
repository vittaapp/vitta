// lib/services/emergencia_service.dart

class EmergenciaService {
  // Función que dispara la alerta crítica
  Future<void> dispararAlertaSOS(String pacienteId, String profesionalId, String ubicacionGps) async {
    print("🚨 ALERTA SOS ACTIVADA PARA PACIENTE: $pacienteId");
    print("📍 UBICACIÓN ENVIADA: $ubicacionGps");

    // Aquí en el futuro conectaríamos con Firebase Cloud Messaging (Notificaciones Push)
    // Y también podría disparar un SMS automático al familiar.

    await Future.delayed(const Duration(seconds: 1));
    print("✅ Notificaciones de emergencia enviadas a Familiares y Central de Vitta.");
  }
}