import 'package:flutter/material.dart';

import 'role_router.dart';

/// Navegación centralizada post-login / post-rol.
class AppNavigator {
  AppNavigator._();

  static void replaceWithRoleHome(BuildContext context, String rol) {
    final w = RoleRouter.widgetForRole(rol);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => w),
    );
  }

  /// Útil cuando no se puede navegar durante el build (p. ej. guardas en widgets).
  static void replaceWithRoleHomePostFrame(BuildContext context, String rol) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      replaceWithRoleHome(context, rol);
    });
  }
}
