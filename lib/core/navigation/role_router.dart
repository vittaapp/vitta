import 'package:flutter/material.dart';

import '../../models/usuario_model.dart';
import '../../views/admin_aprobaciones_view.dart';
import '../../views/area_profesional_view.dart';
import '../../views/familiar_dashboard_view.dart';
import '../../views/medico_dashboard_view.dart';
import '../../views/panel_control_view.dart';

/// Pantalla raíz según el campo `rol` en Firestore (`usuarios/{uid}.rol`).
/// Alineado a [RolesVitta] en `lib/models/usuario_model.dart` y a `LoginView._navegarSegunRol`.
class RoleRouter {
  RoleRouter._();

  /// Devuelve el widget de inicio para el rol dado. Desconocidos → [PanelControlView].
  static Widget widgetForRole(String rol) {
    if (rol == RolesVitta.medico) {
      return const MedicoDashboardView();
    }
    if (rol == RolesVitta.enfermeroN3 || rol == RolesVitta.profesional) {
      return const AreaProfesionalView();
    }
    if (rol == RolesVitta.familiar) {
      return const FamiliarDashboardView();
    }
    if (rol == RolesVitta.admin) {
      return const AdminAprobacionesView();
    }
    return const PanelControlView();
  }
}
