import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_app/widgets/dashboard/onboarding_familiar_widget.dart';
import 'package:vitta_app/widgets/dashboard/dashboard_header_widget.dart';
import 'package:vitta_app/widgets/dashboard/emergency_button_widget.dart';
import 'package:vitta_app/widgets/dashboard/service_status_widget.dart';
import 'package:vitta_app/widgets/dashboard/daily_resumen_widget.dart';
import 'package:vitta_app/widgets/dashboard/recent_bitacora_widget.dart';
import 'package:vitta_app/widgets/dashboard/my_patients_card_widget.dart';
import 'package:vitta_app/widgets/dashboard/access_card_widget.dart';

import '../constants/contacto_vitta.dart';
import '../models/entities/paciente_entity.dart';
import '../models/usuario_model.dart';
import '../providers/paciente_principal_provider.dart';
import '../providers/usuario_rol_provider.dart';
import '../utils/plan_nivel_mapper.dart';
import 'lista_cuidadores_view.dart';
import 'login_view.dart';
import 'solicitar_turno_view.dart';
import 'area_profesional_view.dart';
import 'admin_aprobaciones_view.dart';
import 'medico_dashboard_view.dart';

/// Azul Vitta — `vitta_rules.md` / cursor rules.
const Color _kAzulVitta = Color(0xFF1A3E6F);

/// Centro de comando del familiar: confianza, seguimiento y seguridad.
class FamiliarDashboardView extends ConsumerStatefulWidget {
  const FamiliarDashboardView({super.key});

  @override
  ConsumerState<FamiliarDashboardView> createState() =>
      _FamiliarDashboardViewState();
}

class _FamiliarDashboardViewState extends ConsumerState<FamiliarDashboardView> {
  static const Color _fondo = Color(0xFFE8EEF5);
  bool _redireccionPorRolProgramada = false;

  @override
  Widget build(BuildContext context) {
    final usuarioActualAsync = ref.watch(usuarioActualProvider);
    final redireccionPorRol = usuarioActualAsync.when(
      data: (usuario) {
        final rol = usuario?.rol;
        if (rol == null) return null;
        if (rol == RolesVitta.profesional || rol == RolesVitta.enfermeroN3) {
          return const AreaProfesionalView();
        }
        if (rol == RolesVitta.medico) {
          return const MedicoDashboardView();
        }
        if (rol == RolesVitta.admin) {
          return const AdminAprobacionesView();
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    );

    if (redireccionPorRol != null) {
      if (!_redireccionPorRolProgramada) {
        _redireccionPorRolProgramada = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(builder: (_) => redireccionPorRol),
          );
        });
      }
      return const Scaffold(
        backgroundColor: _fondo,
        body: Center(
          child: CircularProgressIndicator(color: _kAzulVitta),
        ),
      );
    }
    _redireccionPorRolProgramada = false;

    final pacienteAsync = ref.watch(pacientePrincipalProvider);

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        title: const Text('Tu hogar en Vitta'),
        backgroundColor: _kAzulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: pacienteAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kAzulVitta),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  'No se pudieron cargar los datos del paciente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(pacientePrincipalProvider),
                  icon: const Icon(Icons.refresh_rounded, color: _kAzulVitta),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(
                      color: _kAzulVitta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (PacienteEntity? paciente) {
          if (paciente == null) {
            return OnboardingFamiliarBienvenidaWidget(
              onRegistroExitoso: () {
                ref.invalidate(pacientePrincipalProvider);
                ref.invalidate(usuarioActualProvider);
              },
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardHeaderWidget(),
                EmergencyButtonWidget(
                  onPressed: () => _snack(
                    context,
                    'Buscando enfermeros N3 disponibles cerca tuyo...',
                  ),
                ),
                const SizedBox(height: 16),
                ServiceStatusWidget(
                  onLlamarSoporte: () => _llamarSoporteVitta(context),
                  nombrePaciente: paciente.nombre,
                ),
                const SizedBox(height: 14),
                RecentBitacoraWidget(pacienteId: paciente.id),
                const SizedBox(height: 14),
                DailyResumenWidget(pacienteId: paciente.id),
                const SizedBox(height: 14),
                _Soporte247(
                  onTap: () => _snack(
                    context,
                    'Soporte Vitta 24/7: te ayudamos por chat o llamada con cualquier duda sobre el cuidador (demo).',
                  ),
                ),
                const SizedBox(height: 16),
                _TarjetaSuscripcion(
                  planActivo: paciente.planActivo,
                  onVerPlanes: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const ListaCuidadoresView(),
                      ),
                    );
                  },
                  onSolicitarTurno: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => SolicitarTurnoView(paciente: paciente),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _tituloSeccion('Mis pacientes'),
                const SizedBox(height: 10),
                Text(
                  'Patologías y necesidades actualizadas para el equipo de cuidado.',
                  style: TextStyle(fontSize: 13, height: 1.35, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                MyPatientsCardWidget(
                  paciente: paciente,
                  onRegistrado: () {
                    ref.invalidate(pacientePrincipalProvider);
                    ref.invalidate(usuarioActualProvider);
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 22),
                _tituloSeccion('Historial y facturación'),
                const SizedBox(height: 10),
                AccessCardWidget(
                  icono: Icons.payments_outlined,
                  titulo: 'Pagos realizados',
                  subtitulo:
                      'Los montos que ves ya incluyen el servicio de Vitta. Sin cálculos extra para vos.',
                  onTap: () => _snack(context, 'Historial de pagos (demo). Tu comisión ya está integrada al total.'),
                ),
                const SizedBox(height: 10),
                AccessCardWidget(
                  icono: Icons.receipt_long_rounded,
                  titulo: 'Facturas y comprobantes',
                  subtitulo: 'Descargá facturas y resúmenes cuando los necesites.',
                  onTap: () => _snack(context, 'Facturas y comprobantes (demo).'),
                ),
                const SizedBox(height: 22),
                _BotonPanicoFamiliar(onPressed: () {
                  _snack(
                    context,
                    'Tu reporte fue enviado al equipo de soporte de Vitta. Te contactamos a la brevedad.',
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'Contratar por Vitta es más seguro: todo queda registrado, con profesionales verificados y respaldo del equipo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _tituloSeccion(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _kAzulVitta,
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  static Future<void> _llamarSoporteVitta(BuildContext context) async {
    final digits = kTelefonoSoporteEmergenciaVitta.replaceAll(RegExp(r'\s'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(context, 'No se pudo abrir el marcador. Probá desde el teléfono.');
      }
    } catch (e, st) {
      debugPrint('Llamada soporte: $e\n$st');
      if (context.mounted) {
        _snack(context, 'No se pudo abrir el marcador.');
      }
    }
  }
}

class _BotonPanicoFamiliar extends StatelessWidget {
  const _BotonPanicoFamiliar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.emergency_share_rounded, size: 24),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Reportar irregularidad al equipo Vitta',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB71C1C),
        side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        backgroundColor: const Color(0xFFFFEBEE),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _Soporte247 extends StatelessWidget {
  const _Soporte247({required this.onTap});

  final VoidCallback onTap;

  static const Color _azul = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBDEFB)),
            boxShadow: [
              BoxShadow(
                color: _azul.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _azul.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: _azul, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soporte 24/7',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _azul,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cualquier duda con el cuidador o el servicio: estamos acá.',
                      style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

String _etiquetaPlanFirestore(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final t = raw.trim().toLowerCase();
  switch (t) {
    case 'acompañamiento':
    case 'acompanamiento':
      return 'Acompañamiento';
    case 'salud':
      return 'Salud';
    case 'clinico':
    case 'clínico':
      return 'Clínico';
    case 'trial':
      return 'Trial';
    case 'basico':
    case 'básico':
      return 'Básico';
    case 'completo':
      return 'Completo';
    case 'expirado':
      return 'Expirado';
    default:
      final s = raw.trim();
      return s.isEmpty ? '' : '${s[0].toUpperCase()}${s.length > 1 ? s.substring(1) : ''}';
  }
}

class _TarjetaSuscripcion extends StatelessWidget {
  const _TarjetaSuscripcion({
    required this.planActivo,
    required this.onVerPlanes,
    required this.onSolicitarTurno,
  });

  final String? planActivo;
  final VoidCallback onVerPlanes;
  final VoidCallback onSolicitarTurno;

  @override
  Widget build(BuildContext context) {
    final etiqueta = _etiquetaPlanFirestore(planActivo);
    final tienePlan = etiqueta.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _kAzulVitta.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu suscripción',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 10),
          if (tienePlan) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAzulVitta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAzulVitta, width: 1.5),
                ),
                child: Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kAzulVitta,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Plan actual: $etiqueta — accedé a perfiles según tu nivel.',
              style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              PlanNivelMapper.obtenerDescripcion(planActivo ?? 'acompañamiento'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: _kAzulVitta.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: planActivo == null
                  ? null
                  : onSolicitarTurno,
              icon: const Icon(Icons.add_circle_rounded, color: _kAzulVitta, size: 22),
              label: const Text(
                'Solicitar turno',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Text(
              'Sin plan activo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onVerPlanes,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Ver planes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
