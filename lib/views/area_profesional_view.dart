import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario_model.dart';
import '../providers/usuario_rol_provider.dart';
import '../services/auth_service.dart';
import '../widgets/common/section_title_widget.dart';
import '../widgets/dashboard/empty_requests_card_widget.dart';
import '../widgets/dashboard/my_profile_card_widget.dart';
import '../widgets/dashboard/professional_header_widget.dart';
import '../widgets/dashboard/professional_onboarding_widget.dart';
import '../widgets/dashboard/professional_turnos_panel_widget.dart';
import '../widgets/dashboard/professional_wallet_card_widget.dart';
import '../widgets/dashboard/report_incident_button_widget.dart';
import 'login_view.dart';

/// Colores — `vitta_rules.md` / cursor rules.
const Color _azulVitta = Color(0xFF1A3E6F);
const Color _fondoApp = Color(0xFFE8EEF5);

bool _esRolAreaProfesional(String rol) =>
    rol == RolesVitta.profesional ||
    rol == RolesVitta.enfermeroN3 ||
    rol == RolesVitta.medico;

/// Onboarding si falta nivel o datos requeridos; [perfilCompleto] true también libera el dashboard.
bool _necesitaOnboardingProfesional(Usuario u) {
  if (!_esRolAreaProfesional(u.rol)) return false;
  if (u.perfilCompleto == true) return false;
  if (u.nivel == null) return true;
  switch (u.nivel) {
    case 3:
      final m = u.matriculaProfesional?.trim();
      return m == null || m.isEmpty;
    case 2:
      final i = u.institucionEducativa?.trim();
      return i == null || i.isEmpty;
    case 1:
    default:
      return false;
  }
}

/// Dashboard profesional: enfermeros y cuidadores Vitta.
class AreaProfesionalView extends ConsumerWidget {
  const AreaProfesionalView({super.key});

  static const double _alturaBotonMin = 56;

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final usuarioPerfil = ref.watch(usuarioActualProvider);

    return Scaffold(
      backgroundColor: _fondoApp,
      appBar: AppBar(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi Panel Vitta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: authAsync.when(
        data: (user) => usuarioPerfil.when(
          data: (u) {
            if (u == null) {
              return const Center(
                child: Text('No se encontró tu perfil de usuario.'),
              );
            }
            if (_necesitaOnboardingProfesional(u)) {
              return const ProfessionalOnboardingWidget();
            }
            final nombreFirestore = u.nombre;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfessionalHeaderWidget(
                    user: user,
                    nombreFirestore: nombreFirestore,
                  ),
                  const SizedBox(height: 20),
                  const SectionTitleWidget(text: 'Mi próximo turno'),
                  const SizedBox(height: 10),
                  const ProfessionalTurnosPanelWidget(
                    minButtonHeight: _alturaBotonMin,
                  ),
                  const SizedBox(height: 20),
                  const SectionTitleWidget(text: 'Mi wallet'),
                  const SizedBox(height: 10),
                  const ProfessionalWalletCardWidget(
                    minButtonHeight: _alturaBotonMin,
                  ),
                  const SizedBox(height: 20),
                  const SectionTitleWidget(text: 'Solicitudes pendientes'),
                  const SizedBox(height: 10),
                  const EmptyRequestsCardWidget(),
                  const SizedBox(height: 20),
                  const SectionTitleWidget(text: 'Mi perfil'),
                  const SizedBox(height: 10),
                  MyProfileCardWidget(
                    usuario: u,
                    minButtonHeight: _alturaBotonMin,
                  ),
                  const SizedBox(height: 24),
                  ReportIncidentButtonWidget(
                    minHeight: _alturaBotonMin,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Reporte recibido. El equipo Vitta será notificado.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: _azulVitta),
          ),
          error: (_, __) => const Center(
            child: Text('No se pudo cargar el perfil.'),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _azulVitta),
        ),
        error: (_, __) => const Center(
          child: Text('No se pudo cargar la sesión.'),
        ),
      ),
    );
  }
}
