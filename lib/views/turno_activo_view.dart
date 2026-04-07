import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/signos_vitales.dart';
import '../models/turno_activo_parametros.dart';
import '../providers/usuario_rol_provider.dart';
import '../services/historial_service.dart';
import '../services/turno_service.dart';
import 'chat_turno_view.dart';

/// Colores — cursor_rules / vitta_rules.
const Color _azulVitta = Color(0xFF1A3E6F);
const Color _verdeConfianza = Color(0xFF2E7D32);
const Color _rojoEmergencia = Color(0xFFB71C1C);
const Color _fondoApp = Color(0xFFE8EEF5);

final _historialServiceProvider = Provider<HistorialService>((ref) {
  return HistorialService();
});

final _turnoServiceProvider = Provider<TurnoService>((ref) {
  return TurnoService();
});

/// Pantalla durante un turno domiciliario: check-in, signos, nota, cierre.
class TurnoActivoView extends ConsumerStatefulWidget {
  const TurnoActivoView({super.key, required this.parametros});

  final TurnoActivoParametros parametros;

  static const double alturaBotonMin = 56;

  @override
  ConsumerState<TurnoActivoView> createState() => _TurnoActivoViewState();
}

class _TurnoActivoViewState extends ConsumerState<TurnoActivoView> {
  late DateTime _inicioTurno;
  Timer? _timer;
  Duration _transcurrido = Duration.zero;

  bool _checkinHecho = false;
  bool _cargandoCheckin = false;
  bool _cargandoGpsCheckin = false;
  String? _checkinGpsTexto;
  final _codigoController = TextEditingController();
  int _intentosCodigo = 0;
  bool _codigoBloqueado = false;
  bool _cargandoSignos = false;
  bool _cargandoNota = false;
  bool _cargandoFin = false;

  final _tensionController = TextEditingController();
  final _tempController = TextEditingController();
  final _fcController = TextEditingController();
  final _satController = TextEditingController();
  final _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicioTurno = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _transcurrido = DateTime.now().difference(_inicioTurno);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tensionController.dispose();
    _tempController.dispose();
    _fcController.dispose();
    _satController.dispose();
    _notaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  String _formatDuracion(Duration d) {
    final t = d.inSeconds;
    final h = t ~/ 3600;
    final m = (t % 3600) ~/ 60;
    final s = t % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _snackRojo(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<GeoPoint?> _obtenerGpsCheckin() async {
    final permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _snack('Permiso de ubicación necesario para el check-in');
      return null;
    }

    if (!mounted) return null;
    setState(() => _cargandoGpsCheckin = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (e) {
      _snack('No se pudo obtener la ubicación. Continuamos sin GPS.');
      return null;
    } finally {
      if (mounted) setState(() => _cargandoGpsCheckin = false);
    }
  }

  Future<GeoPoint?> _obtenerGpsCheckout() async {
    final permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _snack('Permiso de ubicación necesario para el check-out');
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (e) {
      _snack('No se pudo obtener la ubicación. Continuamos sin GPS.');
      return null;
    }
  }

  Future<void> _confirmarLlegada() async {
    final uid = ref.read(uidActualProvider);
    if (uid == null) {
      _snack('Sesión no válida.');
      return;
    }
    if (_checkinHecho || _codigoBloqueado) return;

    final codigo = _codigoController.text.trim().replaceAll(RegExp(r'\s'), '');
    if (codigo.length != 6) {
      _snack('Ingresá el código de 6 dígitos.');
      return;
    }

    setState(() => _cargandoCheckin = true);
    try {
      final resultado = await ref.read(_turnoServiceProvider).validarCodigoCheckin(
            turnoId: widget.parametros.turnoId,
            codigo: codigo,
            profesionalUid: uid,
          );

      switch (resultado) {
        case CodigoCheckinResult.ok:
          await _completarCheckinConGps();
          break;
        case CodigoCheckinResult.vencido:
          if (mounted) {
            _snackRojo('El código expiró — el familiar debe solicitar un nuevo turno');
          }
          break;
        case CodigoCheckinResult.incorrecto:
          if (mounted) {
            _intentosCodigo++;
            _snackRojo('Código incorrecto — pedíselo al familiar');
            if (_intentosCodigo >= 3) {
              setState(() => _codigoBloqueado = true);
              _snackRojo('Límite de intentos alcanzado — contactá a Soporte Vitta');
            }
          }
          break;
        case CodigoCheckinResult.yaUsado:
          if (mounted) {
            _snackRojo('Este código ya fue utilizado.');
          }
          break;
        case CodigoCheckinResult.profesionalNoCoincide:
        case CodigoCheckinResult.turnoNoEncontrado:
        case CodigoCheckinResult.error:
          if (mounted) {
            _snack('No se pudo validar el código. Intentá de nuevo.');
          }
          break;
      }
    } finally {
      if (mounted) setState(() => _cargandoCheckin = false);
    }
  }

  Future<void> _completarCheckinConGps() async {
    final uid = ref.read(uidActualProvider);
    if (uid == null) {
      _snack('Sesión no válida.');
      return;
    }
    try {
      final gps = await _obtenerGpsCheckin();
      final gpsTexto = gps == null
          ? null
          : '${gps.latitude.toStringAsFixed(5)}, ${gps.longitude.toStringAsFixed(5)}';

      await ref.read(_turnoServiceProvider).registrarCheckin(
            turnoId: widget.parametros.turnoId,
            profesionalId: uid,
            pacienteId: widget.parametros.pacienteId,
            direccion: widget.parametros.direccionDomicilio,
            checkinGps: gps,
          );
      if (mounted) {
        setState(() => _checkinHecho = true);
        if (gpsTexto != null) setState(() => _checkinGpsTexto = gpsTexto);
        _snack('Llegada registrada.');
      }
    } catch (e) {
      if (mounted) _snack('No se pudo registrar: $e');
    }
  }

  Future<void> _guardarSignos() async {
    final uid = ref.read(uidActualProvider);
    final usuario = ref.read(usuarioActualProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    if (uid == null || usuario == null) {
      _snack('No se pudo cargar tu perfil.');
      return;
    }
    final sv = SignosVitales(
      tensionArterial: _tensionController.text.trim().isEmpty
          ? null
          : _tensionController.text.trim(),
      temperaturaCelsius: double.tryParse(
        _tempController.text.trim().replaceAll(',', '.'),
      ),
      frecuenciaCardiacaLpm: int.tryParse(_fcController.text.trim()),
      saturacionOxigenoPct: int.tryParse(_satController.text.trim()),
    );
    if (!sv.tieneAlguno) {
      _snack('Completá al menos un signo vital.');
      return;
    }
    setState(() => _cargandoSignos = true);
    try {
      await ref.read(_historialServiceProvider).crearRegistroConSignosVitales(
            pacienteId: widget.parametros.pacienteId,
            profesionalId: uid,
            turnoId: widget.parametros.turnoId,
            signosVitales: sv,
            nombreProfesional: usuario.nombre,
            matriculaProfesional: usuario.matriculaProfesional,
          );
      if (mounted) {
        _snack('Signos vitales guardados en historial.');
        _tensionController.clear();
        _tempController.clear();
        _fcController.clear();
        _satController.clear();
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _cargandoSignos = false);
    }
  }

  Future<void> _guardarNota() async {
    final uid = ref.read(uidActualProvider);
    final usuario = ref.read(usuarioActualProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    if (uid == null || usuario == null) {
      _snack('No se pudo cargar tu perfil.');
      return;
    }
    final texto = _notaController.text.trim();
    if (texto.isEmpty) {
      _snack('Escribí una nota del turno.');
      return;
    }
    setState(() => _cargandoNota = true);
    try {
      await ref.read(_historialServiceProvider).crearNotaCuidador(
            pacienteId: widget.parametros.pacienteId,
            profesionalId: uid,
            turnoId: widget.parametros.turnoId,
            texto: texto,
            nombreProfesional: usuario.nombre,
            matriculaProfesional: usuario.matriculaProfesional,
          );
      if (mounted) {
        _snack('Nota guardada.');
        _notaController.clear();
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _cargandoNota = false);
    }
  }

  Future<void> _finalizarTurno() async {
    final uid = ref.read(uidActualProvider);
    if (uid == null) {
      _snack('Sesión no válida.');
      return;
    }
    setState(() => _cargandoFin = true);
    try {
      final gps = await _obtenerGpsCheckout();
      await ref.read(_turnoServiceProvider).finalizarTurno(
            turnoId: widget.parametros.turnoId,
            profesionalId: uid,
            pacienteId: widget.parametros.pacienteId,
            checkoutGps: gps,
          );
      if (mounted) {
        _snack('Turno finalizado.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _snack('No se pudo finalizar: $e');
    } finally {
      if (mounted) setState(() => _cargandoFin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parametros;

    return Scaffold(
      backgroundColor: _fondoApp,
      appBar: AppBar(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Turno en curso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: const Color(0xFFE8F5E9),
              side: const BorderSide(color: _verdeConfianza),
              label: Text(
                _formatDuracion(_transcurrido),
                style: const TextStyle(
                  color: _verdeConfianza,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: _azulVitta,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Chat'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatTurnoView(
                turnoId: widget.parametros.turnoId,
                nombrePaciente: widget.parametros.nombrePaciente,
              ),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TarjetaPaciente(parametros: p),
            const SizedBox(height: 16),
            const _SeccionTitulo(titulo: 'Check-in'),
            const SizedBox(height: 8),
            _TarjetaCheckin(
              direccion: p.direccionDomicilio,
              codigoController: _codigoController,
              codigoBloqueado: _codigoBloqueado,
              checkinHecho: _checkinHecho,
              cargando: _cargandoCheckin,
              cargandoGps: _cargandoGpsCheckin,
              checkinGpsTexto: _checkinGpsTexto,
              onConfirmarLlegada: _confirmarLlegada,
            ),
            const SizedBox(height: 20),
            const _SeccionTitulo(titulo: 'Registrar signos vitales'),
            const SizedBox(height: 8),
            _CamposSignos(
              tension: _tensionController,
              temp: _tempController,
              fc: _fcController,
              sat: _satController,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cargandoSignos ? null : _guardarSignos,
              style: FilledButton.styleFrom(
                backgroundColor: _azulVitta,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(TurnoActivoView.alturaBotonMin),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _cargandoSignos
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Guardar en historial',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            const _SeccionTitulo(titulo: 'Nota del turno'),
            const SizedBox(height: 8),
            TextField(
              controller: _notaController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Observaciones, cuidados, incidencias…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cargandoNota ? null : _guardarNota,
              style: FilledButton.styleFrom(
                backgroundColor: _azulVitta,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(TurnoActivoView.alturaBotonMin),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _cargandoNota
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Guardar nota',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _cargandoFin ? null : _finalizarTurno,
              style: FilledButton.styleFrom(
                backgroundColor: _verdeConfianza,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(TurnoActivoView.alturaBotonMin),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _cargandoFin
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Finalizar turno',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _TarjetaPaciente extends StatelessWidget {
  const _TarjetaPaciente({required this.parametros});

  final TurnoActivoParametros parametros;

  @override
  Widget build(BuildContext context) {
    final alergias = parametros.alergiasImportantes.trim();

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
              children: [
                Icon(Icons.person_rounded, color: _azulVitta.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parametros.nombrePaciente,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _azulVitta,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${parametros.edad} años',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Diagnóstico principal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              parametros.diagnosticoPrincipal,
              style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xFF1A1A1A)),
            ),
            if (alergias.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Alergias importantes',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                alergias,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: _rojoEmergencia,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaCheckin extends StatelessWidget {
  const _TarjetaCheckin({
    required this.direccion,
    required this.codigoController,
    required this.codigoBloqueado,
    required this.checkinHecho,
    required this.cargando,
    required this.cargandoGps,
    required this.checkinGpsTexto,
    required this.onConfirmarLlegada,
  });

  final String direccion;
  final TextEditingController codigoController;
  final bool codigoBloqueado;
  final bool checkinHecho;
  final bool cargando;
  final bool cargandoGps;
  final String? checkinGpsTexto;
  final VoidCallback onConfirmarLlegada;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_rounded, color: _azulVitta.withValues(alpha: 0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Domicilio',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        direccion,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (cargandoGps)
              const Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (checkinGpsTexto != null && checkinGpsTexto!.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: _verdeConfianza,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación registrada: $checkinGpsTexto',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _verdeConfianza,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Se registrará tu ubicación al confirmar la llegada.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Código del familiar',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codigoController,
              enabled: !checkinHecho && !codigoBloqueado,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: Color(0xFF1A1A1A),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _azulVitta, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _azulVitta, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: checkinHecho || cargando || codigoBloqueado ? null : onConfirmarLlegada,
              style: FilledButton.styleFrom(
                backgroundColor: _azulVitta,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(TurnoActivoView.alturaBotonMin),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: cargando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      checkinHecho ? 'Llegada registrada ✓' : 'Confirmar llegada',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CamposSignos extends StatelessWidget {
  const _CamposSignos({
    required this.tension,
    required this.temp,
    required this.fc,
    required this.sat,
  });

  final TextEditingController tension;
  final TextEditingController temp;
  final TextEditingController fc;
  final TextEditingController sat;

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String hint) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Column(
      children: [
        TextField(controller: tension, decoration: deco('Tensión arterial (ej. 120/80)')),
        const SizedBox(height: 10),
        TextField(
          controller: temp,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: deco('Temperatura (°C)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fc,
          keyboardType: TextInputType.number,
          decoration: deco('Frecuencia cardíaca (lpm)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: sat,
          keyboardType: TextInputType.number,
          decoration: deco('Saturación O₂ (%)'),
        ),
      ],
    );
  }
}
