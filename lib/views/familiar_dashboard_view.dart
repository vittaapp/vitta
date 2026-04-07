import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/contacto_vitta.dart';
import '../models/paciente_firestore.dart';
import '../models/registro_historial_clinico.dart';
import '../models/usuario_model.dart';
import '../providers/bitacora_provider.dart';
import '../providers/paciente_principal_provider.dart';
import '../providers/usuario_rol_provider.dart';
import 'lista_cuidadores_view.dart';
import 'login_view.dart';
import 'perfil_paciente_familiar_view.dart';
import 'historial_completo_view.dart';
import 'registro_paciente_view.dart';
import 'solicitar_turno_view.dart';
import 'area_profesional_view.dart';
import 'admin_aprobaciones_view.dart';
import 'medico_dashboard_view.dart';
import '../services/turno_service.dart';
import '../services/resumen_diario_service.dart';
import '../widgets/mapa_turno_activo_card.dart';
import 'chat_turno_view.dart';

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
        data: (PacienteFirestore? paciente) {
          if (paciente == null) {
            return _OnboardingFamiliarBienvenida(
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
                const _HeaderConfianza(),
                const SizedBox(height: 16),
                _BotonEmergenciaCuidador(
                  onPressed: () => _snack(
                    context,
                    'Buscando enfermeros N3 disponibles cerca tuyo...',
                  ),
                ),
                const SizedBox(height: 16),
                _EstadoServicioActivo(
                  onLlamarSoporte: () => _llamarSoporteVitta(context),
                  nombrePaciente: paciente.nombre,
                ),
                const SizedBox(height: 14),
                _BitacoraReciente(pacienteId: paciente.id),
                const SizedBox(height: 14),
                _ResumenDeHoy(pacienteId: paciente.id),
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
                _TarjetaMisPacientes(
                  paciente: paciente,
                  onRegistrado: () {
                    ref.invalidate(pacientePrincipalProvider);
                    ref.invalidate(usuarioActualProvider);
                  },
                ),
                const SizedBox(height: 16),
                _BannerGarantia(),
                const SizedBox(height: 22),
                _tituloSeccion('Historial y facturación'),
                const SizedBox(height: 10),
                _TarjetaAcceso(
                  icono: Icons.payments_outlined,
                  titulo: 'Pagos realizados',
                  subtitulo:
                      'Los montos que ves ya incluyen el servicio de Vitta. Sin cálculos extra para vos.',
                  onTap: () => _snack(context, 'Historial de pagos (demo). Tu comisión ya está integrada al total.'),
                ),
                const SizedBox(height: 10),
                _TarjetaAcceso(
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

/// Onboarding obligatorio: sin paciente en `pacientePrincipalProvider` no se muestra el dashboard completo.
class _OnboardingFamiliarBienvenida extends StatelessWidget {
  const _OnboardingFamiliarBienvenida({required this.onRegistroExitoso});

  final VoidCallback onRegistroExitoso;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.health_and_safety_rounded,
              size: 80,
              color: _kAzulVitta,
            ),
            const SizedBox(height: 28),
            const Text(
              '¡Bienvenido a Vitta!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _kAzulVitta,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Para encontrar el cuidador ideal, primero necesitamos conocer a tu familiar. Solo toma 2 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => const RegistroPacienteView(),
                  ),
                );
                if (ok == true) onRegistroExitoso();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kAzulVitta,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Registrar a mi familiar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Podés editarlo cuando quieras',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderConfianza extends StatelessWidget {
  const _HeaderConfianza();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombreUsuario = user?.displayName?.trim() ?? '';
    final photoUrl = user?.photoURL;
    final saludo = nombreUsuario.isNotEmpty ? 'Hola, $nombreUsuario' : 'Hola';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _kAzulVitta.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(
                    photoUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFFE3F2FD),
                      alignment: Alignment.center,
                      child: Icon(Icons.account_circle_rounded, size: 48, color: _kAzulVitta.withValues(alpha: 0.9)),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFE3F2FD),
                    alignment: Alignment.center,
                    child: Icon(Icons.account_circle_rounded, size: 48, color: _kAzulVitta.withValues(alpha: 0.9)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 18, color: Colors.green.shade800),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Hogar Protegido por Vitta',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerGarantia extends StatelessWidget {
  static const Color _azul = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81D4FA).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🛡️', style: TextStyle(fontSize: 30, height: 1.1)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Garantía Vitta activa: Ante cualquier inasistencia del cuidador, te enviamos un suplente verificado en menos de 2 horas.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonEmergenciaCuidador extends StatelessWidget {
  const _BotonEmergenciaCuidador({required this.onPressed});

  final VoidCallback onPressed;

  static const Color _rojoOscuro = Color(0xFFB71C1C);
  static const Color _fondoRojoClaro = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.emergency_rounded, size: 26),
        label: const Text(
          'Necesito un cuidador AHORA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _rojoOscuro,
          backgroundColor: _fondoRojoClaro,
          side: const BorderSide(color: _rojoOscuro, width: 1.5),
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Demo: `false` muestra próxima guardia (verde). Conectar con backend en producción.
class _EstadoServicioActivo extends StatelessWidget {
  const _EstadoServicioActivo({
    required this.onLlamarSoporte,
    required this.nombrePaciente,
  });

  final VoidCallback onLlamarSoporte;
  final String nombrePaciente;

  static DateTime? _timestampToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static String _fmtHHmm(dynamic v) {
    final d = _timestampToDate(v);
    if (d == null) return '—';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _fmtFechaHora(dynamic v) {
    final d = _timestampToDate(v);
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} · ${_fmtHHmm(v)}';
  }

  /// Muestra el código de 6 dígitos con espacio entre cifras (estilo Uber).
  static String _codigoEspaciado(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return '— — — — — —';
    return digits.split('').join(' ');
  }

  static Widget _card({
    required Color background,
    required Color borde,
    required Widget cuerpo,
    required VoidCallback? onCancelar,
    required VoidCallback? onChat,
    required VoidCallback? onSoporte,
    required bool mostrarBotonCancelar,
    required bool mostrarBotonChat,
    required bool mostrarBotonSoporte,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 2),
        boxShadow: [
          BoxShadow(
            color: _kAzulVitta.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estado del servicio',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          cuerpo,
          if (mostrarBotonCancelar) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onCancelar,
              icon: const Icon(Icons.cancel_rounded, size: 20),
              label: const Text(
                'Cancelar turno',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFB71C1C),
                side: const BorderSide(color: Color(0xFFB71C1C), width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (mostrarBotonChat) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: const Text(
                'Chat con el cuidador',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (mostrarBotonSoporte) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSoporte,
              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
              label: const Text(
                'Llamar a Soporte Vitta',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAzulVitta,
                side: const BorderSide(color: _kAzulVitta, width: 1.6),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: const Text(
          'Estado del servicio',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TurnoService().obtenerTurnosFamiliar(uid),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final estado = (d.data()['estado'] as String?) ?? '';
          return estado == 'pendiente' || estado == 'aceptado' || estado == 'activo';
        }).toList();

        QueryDocumentSnapshot<Map<String, dynamic>>? buscar(String estado) {
          for (final d in docs) {
            final e = (d.data()['estado'] as String?) ?? '';
            if (e == estado) return d;
          }
          return null;
        }

        final pendienteDoc = buscar('pendiente');
        final aceptadoDoc = buscar('aceptado');
        final activoDoc = buscar('activo');

        if (activoDoc != null) {
          final m = activoDoc.data();
          final rawCheck = m['checkinGps'];
          final GeoPoint? checkGps = rawCheck is GeoPoint ? rawCheck : null;
          final rawDom = m['domicilioGps'];
          final GeoPoint? domGps = rawDom is GeoPoint ? rawDom : null;
          final profId = (m['profesionalId'] as String?) ?? '';
          final nombreProfesionalFuture =
              FirebaseFirestore.instance.collection('usuarios').doc(profId).get();
          final fechaInicio = m['checkinTime'] ?? m['fechaSolicitada'];

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: nombreProfesionalFuture,
            builder: (context, profSnap) {
              final nombre = profSnap.data?.data()?['nombre'] as String?;
              final nombreProfesional =
                  (nombre != null && nombre.trim().isNotEmpty) ? nombre.trim() : 'Profesional';

              return _card(
                background: const Color(0xFFE3F2FD),
                borde: const Color(0xFF1A3E6F),
                cuerpo: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconoRadioPulso(color: const Color(0xFFB71C1C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'En curso ahora',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: _kAzulVitta,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$nombreProfesional · Inicio: ${_fmtHHmm(fechaInicio)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: _kAzulVitta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MapaTurnoActivoCard(
                      checkinGps: checkGps,
                      domicilioGps: domGps,
                    ),
                  ],
                ),
                onCancelar: null,
                onChat: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatTurnoView(
                        turnoId: activoDoc.id,
                        nombrePaciente: nombrePaciente,
                      ),
                    ),
                  );
                },
                onSoporte: onLlamarSoporte,
                mostrarBotonCancelar: false,
                mostrarBotonChat: true,
                mostrarBotonSoporte: true,
              );
            },
          );
        }

        if (aceptadoDoc != null) {
          final m = aceptadoDoc.data();
          final profId = (m['profesionalId'] as String?) ?? '';
          final fechaEstimada = m['fechaSolicitada'];
          final direccion = m['direccion'] as String? ?? '';
          final tipo = m['tipoServicio'] as String? ?? '';

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance.collection('usuarios').doc(profId).get(),
            builder: (context, profSnap) {
              final nombre = profSnap.data?.data()?['nombre'] as String?;
              final nombreProfesional =
                  (nombre != null && nombre.trim().isNotEmpty) ? nombre.trim() : 'Profesional';

              return _card(
                background: const Color(0xFFE8F5E9),
                borde: const Color(0xFF2E7D32),
                cuerpo: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profesional confirmado',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$nombreProfesional · Llegada estimada: ${_fmtHHmm(fechaEstimada)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A3E6F), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFF1A3E6F), size: 26),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tu código de seguridad',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A3E6F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _codigoEspaciado(m['codigoVerificacion'] as String?),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dáselo al cuidador cuando llegue a tu puerta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Detalles del turno'),
                            content: Text(
                              [
                                'Profesional: $nombreProfesional',
                                'Llegada estimada: ${_fmtHHmm(fechaEstimada)}',
                                if (tipo.trim().isNotEmpty)
                                  'Tipo de servicio: $tipo',
                                if (direccion.trim().isNotEmpty) 'Dirección: $direccion',
                              ].join('\n'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_rounded, size: 20),
                      label: const Text(
                        'Ver detalles',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kAzulVitta,
                        side: const BorderSide(color: _kAzulVitta, width: 1.6),
                        minimumSize: const Size.fromHeight(56),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                onCancelar: null,
                onChat: null,
                onSoporte: null,
                mostrarBotonCancelar: false,
                mostrarBotonChat: false,
                mostrarBotonSoporte: false,
              );
            },
          );
        }

        if (pendienteDoc != null) {
          final m = pendienteDoc.data();
          final fechaSolicitada = m['fechaSolicitada'];
          final direccion = m['direccion'] as String? ?? '';
          final notas = m['notasAdicionales'] as String? ?? '';

          return _card(
            background: const Color(0xFFFFF8E1),
            borde: const Color(0xFFF57F17),
            cuerpo: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFF57F17), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscando profesional...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fecha y hora solicitada: ${_fmtFechaHora(fechaSolicitada)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (direccion.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Dirección: $direccion',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                      if (notas.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Notas: $notas',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            onCancelar: () async {
              try {
                await TurnoService().cancelarTurno(
                  turnoId: pendienteDoc.id,
                  familiarUid: uid,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Turno cancelado.'),
                    backgroundColor: Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo cancelar: $e'),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onChat: null,
            onSoporte: null,
            mostrarBotonCancelar: true,
            mostrarBotonChat: false,
            mostrarBotonSoporte: false,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: _kAzulVitta.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Estado del servicio',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded, color: _kAzulVitta, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sin servicio activo — solicitá un turno',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: _kAzulVitta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onLlamarSoporte,
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                label: const Text(
                  'Llamar a Soporte Vitta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAzulVitta,
                  side: const BorderSide(color: _kAzulVitta, width: 1.6),
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconoRadioPulso extends StatefulWidget {
  const _IconoRadioPulso({required this.color});

  final Color color;

  @override
  State<_IconoRadioPulso> createState() => _IconoRadioPulsoState();
}

class _IconoRadioPulsoState extends State<_IconoRadioPulso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.92 + (t * 0.18);
        final opacity = 0.75 + (t * 0.25);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.radio_button_checked_rounded,
              color: widget.color,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

/// Resumen del día (solo si hubo turno completado hoy). Errores silenciosos.
class _ResumenDeHoy extends StatefulWidget {
  const _ResumenDeHoy({required this.pacienteId});

  final String pacienteId;

  @override
  State<_ResumenDeHoy> createState() => _ResumenDeHoyState();
}

class _ResumenDeHoyState extends State<_ResumenDeHoy> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _future = _cargar(widget.pacienteId, uid);
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _cargar(
    String pacienteId,
    String uid,
  ) async {
    await ResumenDiarioService().generarResumenDelDia(pacienteId, uid);
    return FirebaseFirestore.instance
        .collection(ResumenDiarioService.coleccionResumenes)
        .doc(ResumenDiarioService.documentoIdHoy(pacienteId))
        .get();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final doc = snap.data;
        if (doc == null || !doc.exists) return const SizedBox.shrink();
        final data = doc.data()!;
        if (data['tieneTurnoCompletadoHoy'] != true) {
          return const SizedBox.shrink();
        }
        final texto = (data['textoResumen'] as String?)?.trim() ?? '';
        if (texto.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen de hoy',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _kAzulVitta,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
              ),
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BitacoraReciente extends ConsumerWidget {
  const _BitacoraReciente({required this.pacienteId});

  final String pacienteId;

  static const Color _azul = Color(0xFF0D47A1);

  static String _fmtHora(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _textoRegistro(RegistroHistorialClinico r) {
    final d = r.descripcion?.trim();
    if (d != null && d.isNotEmpty) return d;
    switch (r.tipoRegistro) {
      case TipoRegistroHistorial.turno:
        return 'Registro de turno';
      case TipoRegistroHistorial.observacion:
        return 'Observación';
      case TipoRegistroHistorial.medicacion:
        return 'Medicación';
      case TipoRegistroHistorial.emergencia:
        return 'Emergencia';
    }
  }

  static (IconData, Color) _icono(RegistroHistorialClinico r) {
    if (r.tipoRegistro == TipoRegistroHistorial.observacion) {
      return (Icons.note_rounded, const Color(0xFF1565C0));
    }
    if (r.signosVitales?.tieneAlguno == true) {
      return (Icons.favorite_rounded, Colors.red.shade700);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.turno) {
      return (Icons.favorite_rounded, Colors.red.shade700);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.medicacion) {
      return (Icons.medication_rounded, Colors.orange.shade800);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.emergencia) {
      return (Icons.warning_amber_rounded, Colors.deepOrange);
    }
    return (Icons.article_rounded, Colors.grey.shade700);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pacienteId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBDEFB)),
          boxShadow: [
            BoxShadow(
              color: _azul.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitácora reciente',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _azul,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Registrá un paciente para ver la bitácora en tiempo real.',
              style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    final async = ref.watch(bitacoraProvider(pacienteId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bitácora reciente',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _azul,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _kAzulVitta),
              ),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se pudo cargar la bitácora. Probá de nuevo más tarde.',
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.red.shade800),
                ),
                const SizedBox(height: 6),
                Text(
                  '$e',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            data: (lista) {
              if (lista.isEmpty) {
                return Text(
                  'Sin registros aún — los registros del cuidador aparecerán aquí.',
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.grey.shade700),
                );
              }
              final visibles = lista.take(5).toList();
              final hayMas = lista.length > 5;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...visibles.map((r) {
                    final (iconData, colorData) = _icono(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 8),
                            child: Icon(iconData, size: 20, color: colorData),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              _fmtHora(r.fecha),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: _azul.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _textoRegistro(r),
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (hayMas) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HistorialCompletoView(pacienteId: pacienteId),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver historial completo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kAzulVitta,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TarjetaMisPacientes extends StatelessWidget {
  const _TarjetaMisPacientes({
    required this.paciente,
    required this.onRegistrado,
  });

  final PacienteFirestore? paciente;
  final VoidCallback onRegistrado;

  @override
  Widget build(BuildContext context) {
    if (paciente == null) {
      return OutlinedButton.icon(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (context) => const RegistroPacienteView(),
            ),
          );
          if (ok == true) onRegistrado();
        },
        icon: const Icon(Icons.person_add_rounded, color: _kAzulVitta),
        label: const Text(
          'Registrar mi familiar',
          style: TextStyle(
            color: _kAzulVitta,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kAzulVitta,
          side: const BorderSide(color: _kAzulVitta, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    final p = paciente!;
    final nombre = p.nombre.trim().isNotEmpty ? p.nombre.trim() : 'Paciente';
    final subtitulo = [
      if (p.edad != null) '${p.edad} años',
      if (p.localidad != null && p.localidad!.trim().isNotEmpty) p.localidad!.trim(),
      if (p.provincia != null && p.provincia!.trim().isNotEmpty) p.provincia!.trim(),
    ].join(' · ');

    final fotoUrl = nombre.isNotEmpty
        ? 'https://i.pravatar.cc/200?u=${Uri.encodeComponent(nombre)}'
        : 'https://i.pravatar.cc/200?img=68';

    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fotoUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFFE3F2FD),
                alignment: Alignment.center,
                child: Icon(Icons.elderly_rounded, size: 40, color: _kAzulVitta.withValues(alpha: 0.85)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _kAzulVitta,
                  ),
                ),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                  ),
                ],
                if (p.diagnostico != null && p.diagnostico!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.diagnostico!.trim(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const PerfilPacienteFamiliarView(),
                      ),
                    );
                    onRegistrado();
                  },
                  icon: const Icon(Icons.medical_information_outlined, size: 20),
                  label: const Text('Editar patologías y necesidades'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAzulVitta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaAcceso extends StatelessWidget {
  const _TarjetaAcceso({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  static const Color _azul = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 28, color: _azul),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _azul,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSolicitarTurno,
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
