import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/turno_activo_parametros.dart';
import '../models/usuario_model.dart';
import '../providers/usuario_rol_provider.dart';
import '../services/auth_service.dart';
import '../services/turno_service.dart';
import 'login_view.dart';
import 'turno_activo_view.dart';

/// Colores — `vitta_rules.md` / cursor rules.
const Color _azulVitta = Color(0xFF1A3E6F);
const Color _rojoEmergencia = Color(0xFFB71C1C);
const Color _fondoRojoClaro = Color(0xFFFFEBEE);
const Color _fondoWallet = Color(0xFFE1F5EE);
const Color _fondoApp = Color(0xFFE8EEF5);
const Color _verdeVerificado = Color(0xFF2E7D32);
const Color _nivelN1 = Color(0xFF5DCAA5);
const Color _nivelN2 = Color(0xFFF57F17);
const Color _nivelN3 = Color(0xFF534AB7);

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

Color _colorNivel(int? nivel) {
  switch (nivel) {
    case 1:
      return _nivelN1;
    case 2:
      return _nivelN2;
    case 3:
      return _nivelN3;
    default:
      return _azulVitta;
  }
}

String _etiquetaNivel(int? nivel) {
  switch (nivel) {
    case 1:
      return 'N1 Cuidador';
    case 2:
      return 'N2 Estudiante de Enfermería';
    case 3:
      return 'N3 Enfermero Matriculado';
    default:
      return 'Nivel';
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
              return const _OnboardingProfesional();
            }
            final nombreFirestore = u.nombre;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderUsuario(
                    user: user,
                    nombreFirestore: nombreFirestore,
                  ),
                  const SizedBox(height: 20),
                  const _SeccionTitulo(texto: 'Mi próximo turno'),
                  const SizedBox(height: 10),
                  const _PanelTurnosProfesional(alturaBotonMin: _alturaBotonMin),
                  const SizedBox(height: 20),
                  const _SeccionTitulo(texto: 'Mi wallet'),
                  const SizedBox(height: 10),
                  const _TarjetaWallet(alturaBotonMin: _alturaBotonMin),
                  const SizedBox(height: 20),
                  const _SeccionTitulo(texto: 'Solicitudes pendientes'),
                  const SizedBox(height: 10),
                  const _TarjetaSolicitudesVacias(),
                  const SizedBox(height: 20),
                  const _SeccionTitulo(texto: 'Mi perfil'),
                  const SizedBox(height: 10),
                  _TarjetaMiPerfil(
                    usuario: u,
                    alturaBotonMin: _alturaBotonMin,
                  ),
                  const SizedBox(height: 24),
                  _BotonReportarIncidente(
                    alturaMin: _alturaBotonMin,
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

class _HeaderUsuario extends StatelessWidget {
  const _HeaderUsuario({
    required this.user,
    required this.nombreFirestore,
  });

  final User? user;
  final String? nombreFirestore;

  @override
  Widget build(BuildContext context) {
    final nombre = (nombreFirestore != null && nombreFirestore!.trim().isNotEmpty)
        ? nombreFirestore!.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Profesional Vitta');
    final fotoUrl = user?.photoURL;

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: fotoUrl != null && fotoUrl.isNotEmpty
                ? Image.network(
                    fotoUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: _azulVitta,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: _azulVitta,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _azulVitta,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _PanelTurnosProfesional extends ConsumerWidget {
  const _PanelTurnosProfesional({required this.alturaBotonMin});

  final double alturaBotonMin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final usuario = ref.watch(usuarioActualProvider).value;
    final nivel = TurnoService.nivelProfesionalDesdeRol(usuario?.rol);

    if (uid == null || nivel == 0) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tu perfil no está habilitado para gestionar turnos.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.35),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: TurnoService().obtenerTurnosProfesional(
        uid: uid,
        nivelProfesional: nivel,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No se pudieron cargar los turnos: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: _azulVitta),
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No tenés turnos pendientes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < docs.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _TarjetaTurnoProfesional(
                doc: docs[i],
                uid: uid,
                alturaBotonMin: alturaBotonMin,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaTurnoProfesional extends StatelessWidget {
  const _TarjetaTurnoProfesional({
    required this.doc,
    required this.uid,
    required this.alturaBotonMin,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  final double alturaBotonMin;

  static String _fecha(dynamic v) {
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  static String _tipoLabel(String? t) {
    switch (t) {
      case 'hospitalario':
        return 'hospitalario';
      case 'domicilio':
      default:
        return 'domicilio';
    }
  }

  static Color _colorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return const Color(0xFF5DCAA5);
      case 2:
        return const Color(0xFFF57F17); // amber
      case 3:
        return const Color(0xFF534AB7);
      default:
        return const Color(0xFF5DCAA5);
    }
  }

  static String _labelNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'N1';
      case 2:
        return 'N2';
      case 3:
        return 'N3';
      default:
        return 'N$nivel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = doc.data();
    final estado = m['estado'] as String? ?? '';
    final profId = m['profesionalId'] as String? ?? '';
    final nombrePac = m['nombrePaciente'] as String? ?? 'Paciente';
    final direccion = m['direccion'] as String? ?? '—';
    final tipo = m['tipoServicio'] as String? ?? 'domicilio';
    final nivelReq = (m['nivelRequerido'] as num?)?.toInt() ?? 0;
    final fechaSolicitada = m['fechaSolicitada'];

    final sinAsignar = profId.isEmpty;
    final puedeAceptar = estado == 'pendiente' && sinAsignar;
    final puedeIniciar = estado == 'aceptado' && profId == uid;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filaTurno(Icons.person_outline_rounded, 'Paciente', nombrePac),
            const SizedBox(height: 10),
            _filaTurno(Icons.location_on_outlined, 'Dirección', direccion),
            const SizedBox(height: 10),
            _filaTurno(Icons.schedule_rounded, 'Fecha solicitada', _fecha(fechaSolicitada)),
            const SizedBox(height: 10),
            _filaTurno(Icons.medical_services_outlined, 'Tipo', _tipoLabel(tipo)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, size: 22, color: _azulVitta),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nivel requerido',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        backgroundColor: _colorNivel(nivelReq),
                        label: Text(
                          _labelNivel(nivelReq),
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _filaTurno(Icons.flag_outlined, 'Estado', estado),
            const SizedBox(height: 16),
            if (puedeAceptar)
              FilledButton(
                onPressed: () async {
                  try {
                    await TurnoService().aceptarTurno(
                      turnoId: doc.id,
                      profesionalUid: uid,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Turno aceptado.'),
                        backgroundColor: _verdeVerificado,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo aceptar: $e')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _azulVitta,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(alturaBotonMin),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              )
            else if (puedeIniciar)
              FilledButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TurnoActivoView(
                        parametros: TurnoActivoParametros(
                          turnoId: doc.id,
                          pacienteId: m['pacienteId'] as String? ?? '',
                          nombrePaciente: nombrePac,
                          edad: '—',
                          diagnosticoPrincipal: '—',
                          alergiasImportantes: '—',
                          direccionDomicilio: direccion,
                        ),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _azulVitta,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(alturaBotonMin),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Iniciar turno',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _filaTurno(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 22, color: _azulVitta),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaWallet extends StatelessWidget {
  const _TarjetaWallet({required this.alturaBotonMin});

  final double alturaBotonMin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _fondoWallet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo disponible',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const Text(
                      '\$0.00',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _azulVitta,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo pendiente',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      '\$0.00',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial de pagos — próximamente.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _azulVitta,
                side: const BorderSide(color: _azulVitta, width: 1.5),
                minimumSize: Size.fromHeight(alturaBotonMin),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver historial de pagos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSolicitudesVacias extends StatelessWidget {
  const _TarjetaSolicitudesVacias();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No tenés solicitudes pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingProfesional extends ConsumerStatefulWidget {
  const _OnboardingProfesional();

  @override
  ConsumerState<_OnboardingProfesional> createState() =>
      _OnboardingProfesionalState();
}

class _OnboardingProfesionalState extends ConsumerState<_OnboardingProfesional> {
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _institucionController = TextEditingController();
  final _especialidadController = TextEditingController();

  int _nivel = 1;
  bool _manana = false;
  bool _tarde = false;
  bool _noche = false;
  bool _guardando = false;

  @override
  void dispose() {
    _matriculaController.dispose();
    _institucionController.dispose();
    _especialidadController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _guardando = true);
    try {
      final matricula = _matriculaController.text.trim();
      final institucion = _institucionController.text.trim();
      final especialidad = _especialidadController.text.trim();

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'nivel': _nivel,
        'matriculaProfesional': _nivel == 3 ? matricula : '',
        'institucionEducativa': _nivel == 2 ? institucion : '',
        'especialidad': especialidad,
        'disponibilidadManana': _manana,
        'disponibilidadTarde': _tarde,
        'disponibilidadNoche': _noche,
        'perfilCompleto': true,
      });

      ref.invalidate(usuarioActualProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _selectorNivel() {
    Widget tile(int nivel, String label, Color color) {
      final sel = _nivel == nivel;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _nivel = nivel),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: 0.22) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? color : Colors.grey.shade300,
                  width: sel ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: sel ? color : Colors.grey.shade700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(1, 'N1 Cuidador', _nivelN1),
        const SizedBox(width: 8),
        tile(2, 'N2 Estudiante de Enfermería', _nivelN2),
        const SizedBox(width: 8),
        tile(3, 'N3 Enfermero Matriculado', _nivelN3),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.medical_services_rounded,
              size: 80,
              color: _azulVitta,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Completá tu perfil profesional!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _azulVitta,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Para recibir solicitudes de turnos necesitamos verificar tus credenciales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nivel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _azulVitta,
              ),
            ),
            const SizedBox(height: 10),
            _selectorNivel(),
            const SizedBox(height: 20),
            if (_nivel == 3) ...[
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula profesional *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'La matrícula es obligatoria para N3';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_nivel == 2) ...[
              TextFormField(
                controller: _institucionController,
                decoration: InputDecoration(
                  labelText: 'Institución educativa *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Indicá tu institución';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _especialidadController,
              decoration: InputDecoration(
                labelText: 'Especialidad',
                hintText: 'Opcional — área de práctica',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Disponibilidad',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _azulVitta,
              ),
            ),
            CheckboxListTile(
              value: _manana,
              onChanged: (v) => setState(() => _manana = v ?? false),
              title: const Text('Mañana'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _tarde,
              onChanged: (v) => setState(() => _tarde = v ?? false),
              title: const Text('Tarde'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _noche,
              onChanged: (v) => setState(() => _noche = v ?? false),
              title: const Text('Noche'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: _azulVitta,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar perfil',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMiPerfil extends StatelessWidget {
  const _TarjetaMiPerfil({
    required this.usuario,
    required this.alturaBotonMin,
  });

  final Usuario usuario;
  final double alturaBotonMin;

  bool get _verificado {
    final m = usuario.matriculaProfesional?.trim();
    return m != null && m.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final nivelColor = _colorNivel(usuario.nivel);
    final esp = usuario.especialidad?.trim();
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(
                    _etiquetaNivel(usuario.nivel),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: nivelColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (_verificado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _verdeVerificado.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _verdeVerificado),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: _verdeVerificado),
                        SizedBox(width: 4),
                        Text(
                          'Verificado Vitta',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _verdeVerificado,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (esp != null && esp.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information_outlined, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      esp,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Disponibilidad',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _azulVitta,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (usuario.disponibilidadManana)
                  _ChipDisponibilidad(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Mañana',
                    color: Colors.orange.shade700,
                  ),
                if (usuario.disponibilidadTarde)
                  _ChipDisponibilidad(
                    icon: Icons.cloud_rounded,
                    label: 'Tarde',
                    color: Colors.blueGrey.shade600,
                  ),
                if (usuario.disponibilidadNoche)
                  _ChipDisponibilidad(
                    icon: Icons.nights_stay_rounded,
                    label: 'Noche',
                    color: Colors.indigo.shade700,
                  ),
                if (!usuario.disponibilidadManana &&
                    !usuario.disponibilidadTarde &&
                    !usuario.disponibilidadNoche)
                  Text(
                    'Sin horarios indicados',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Editar disponibilidad — próximamente.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _azulVitta,
                side: const BorderSide(color: _azulVitta, width: 1.5),
                minimumSize: Size.fromHeight(alturaBotonMin),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Editar disponibilidad',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipDisponibilidad extends StatelessWidget {
  const _ChipDisponibilidad({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

class _BotonReportarIncidente extends StatelessWidget {
  const _BotonReportarIncidente({
    required this.alturaMin,
    required this.onPressed,
  });

  final double alturaMin;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.emergency_share_rounded, size: 24),
      label: const Text(
        'Reportar incidente',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _rojoEmergencia,
        backgroundColor: _fondoRojoClaro,
        side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        minimumSize: Size.fromHeight(alturaMin),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
