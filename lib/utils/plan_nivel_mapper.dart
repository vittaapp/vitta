/// Mapeo de plan de suscripción a nivel de cuidador permitido.
class PlanNivelMapper {
  /// Obtener nivel máximo de cuidador según plan de suscripción.
  static int obtenerNivelSegunPlan(String planActivo) {
    switch (planActivo.toLowerCase()) {
      case 'acompañamiento':
      case 'acompanamiento':
        return 1;
      case 'salud':
        return 2;
      case 'clínico':
      case 'clinico':
        return 3;
      default:
        return 1;
    }
  }

  /// Obtener descripción legible del plan.
  static String obtenerDescripcion(String planActivo) {
    switch (planActivo.toLowerCase()) {
      case 'acompañamiento':
      case 'acompanamiento':
        return 'Cuidadores N1 (básico)';
      case 'salud':
        return 'Cuidadores N1 y N2';
      case 'clínico':
      case 'clinico':
        return 'Cuidadores N1, N2 y N3 + Médico';
      default:
        return 'Plan no reconocido';
    }
  }

  /// Validar si profesional está habilitado para plan.
  static bool esProfesionalValido(int nivelProfesional, String planActivo) {
    final nivelMaximo = obtenerNivelSegunPlan(planActivo);
    return nivelProfesional <= nivelMaximo;
  }

  /// Obtener etiqueta legible de nivel.
  static String obtenerEtiquetaNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'N1 - Cuidador';
      case 2:
        return 'N2 - Estudiante';
      case 3:
        return 'N3 - Enfermero';
      default:
        return 'Desconocido';
    }
  }
}
