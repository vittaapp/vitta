import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/core/navigation/role_router.dart';
import 'package:vitta_app/models/usuario_model.dart';
import 'package:vitta_app/views/admin_aprobaciones_view.dart';
import 'package:vitta_app/views/area_profesional_view.dart';
import 'package:vitta_app/views/familiar_dashboard_view.dart';
import 'package:vitta_app/views/medico_dashboard_view.dart';
import 'package:vitta_app/views/panel_control_view.dart';

void main() {
  group('RoleRouter.widgetForRole', () {
    test('médico → MedicoDashboardView', () {
      expect(
        RoleRouter.widgetForRole(RolesVitta.medico),
        isA<MedicoDashboardView>(),
      );
    });

    test('profesional y enfermero N3 → AreaProfesionalView', () {
      expect(
        RoleRouter.widgetForRole(RolesVitta.profesional),
        isA<AreaProfesionalView>(),
      );
      expect(
        RoleRouter.widgetForRole(RolesVitta.enfermeroN3),
        isA<AreaProfesionalView>(),
      );
    });

    test('familiar → FamiliarDashboardView', () {
      expect(
        RoleRouter.widgetForRole(RolesVitta.familiar),
        isA<FamiliarDashboardView>(),
      );
    });

    test('admin → AdminAprobacionesView', () {
      expect(
        RoleRouter.widgetForRole(RolesVitta.admin),
        isA<AdminAprobacionesView>(),
      );
    });

    test('Rol desconocido devuelve PanelControlView (fallback)', () {
      final widget = RoleRouter.widgetForRole('rol_inexistente');
      expect(widget, isNotNull,
          reason: 'Rol desconocido debe devolver un widget fallback');
      expect(
        widget.runtimeType.toString(),
        contains('PanelControlView'),
        reason: 'Rol desconocido debe devolver PanelControlView',
      );
    });
  });
}
