import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/entities/paciente_entity.dart';
import '../services/turno_service.dart';
import '../utils/plan_nivel_mapper.dart';

const Color _kAzulVitta = Color(0xFF1A3E6F);
const double _kAlturaBotonMin = 56;

final _turnoServiceProvider = Provider<TurnoService>((ref) => TurnoService());

/// Pantalla para que el familiar solicite un turno real (`turnos` en Firestore).
class SolicitarTurnoView extends ConsumerStatefulWidget {
  const SolicitarTurnoView({
    super.key,
    required this.paciente,
  });

  final PacienteEntity paciente;

  @override
  ConsumerState<SolicitarTurnoView> createState() => _SolicitarTurnoViewState();
}

class _SolicitarTurnoViewState extends ConsumerState<SolicitarTurnoView> {
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController(
    text: 'San Miguel de Tucumán',
  );
  final _notasController = TextEditingController();

  String _tipoServicio = 'domicilio';
  DateTime _fechaHora = DateTime.now().add(const Duration(days: 1));
  bool _guardando = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _elegirFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _enviar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('No hay sesión activa.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final paciente = widget.paciente;
    final nivel = PlanNivelMapper.obtenerNivelSegunPlan(
      paciente.planActivo ?? 'acompañamiento',
    );

    setState(() => _guardando = true);
    try {
      GeoPoint? domicilioGps;
      try {
        final permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.always ||
            permiso == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
          domicilioGps = GeoPoint(pos.latitude, pos.longitude);
        }
      } catch (_) {
        // Sin GPS el turno igual se crea; el mapa usará solo check-in si existe.
      }

      await ref.read(_turnoServiceProvider).solicitarTurno(
            familiarId: uid,
            pacienteId: paciente.id,
            nivelRequerido: nivel,
            tipoServicio: _tipoServicio,
            fechaSolicitada: _fechaHora,
            direccion: _direccionController.text.trim(),
            notasAdicionales: _notasController.text.trim(),
            nombrePaciente: paciente.nombre.trim(),
            domicilioGps: domicilioGps,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turno solicitado correctamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack('No se pudo solicitar el turno: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade800 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.paciente;
    final nivel = PlanNivelMapper.obtenerNivelSegunPlan(
      paciente.planActivo ?? 'acompañamiento',
    );
    final descripcionNivel = PlanNivelMapper.obtenerDescripcion(
      paciente.planActivo ?? 'acompañamiento',
    );
    final diagnostico = paciente.diagnostico?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        backgroundColor: _kAzulVitta,
        foregroundColor: Colors.white,
        title: const Text(
          'Solicitar turno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TarjetaResumenPaciente(
                paciente: paciente,
                nivel: nivel,
                diagnostico: diagnostico,
                descripcionNivel: descripcionNivel,
              ),
              const SizedBox(height: 18),
              Text(
                'Tipo de servicio',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _SelectorTipoServicio(
                valor: _tipoServicio,
                onChanged: (v) => setState(() => _tipoServicio = v),
              ),
              const SizedBox(height: 20),
              Text(
                'Fecha y hora',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _elegirFechaHora,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAzulVitta,
                  side: const BorderSide(color: _kAzulVitta, width: 1.4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  minimumSize: const Size.fromHeight(_kAlturaBotonMin),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  _formatFechaHora(_fechaHora),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                maxLines: 2,
                decoration: _inputDeco(
                  'Dirección / lugar de atención *',
                  Icons.place_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Completá la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasController,
                maxLines: 3,
                decoration: _inputDeco(
                  'Notas adicionales (opcional)',
                  Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _enviar,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAzulVitta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(_kAlturaBotonMin),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Solicitar turno',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatFechaHora(DateTime d) {
    final wd = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'][d.weekday - 1];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$wd ${d.day}/${d.month}/${d.year} · $h:$m';
  }

  static InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kAzulVitta.withValues(alpha: 0.9)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAzulVitta, width: 2),
      ),
    );
  }
}

class _SelectorTipoServicio extends StatelessWidget {
  const _SelectorTipoServicio({
    required this.valor,
    required this.onChanged,
  });

  final String valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OpcionTipo(
            titulo: 'Domicilio',
            icono: Icons.home_work_outlined,
            seleccionado: valor == 'domicilio',
            onTap: () => onChanged('domicilio'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OpcionTipo(
            titulo: 'Sanatorio',
            icono: Icons.local_hospital_outlined,
            seleccionado: valor == 'hospitalario',
            onTap: () => onChanged('hospitalario'),
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumenPaciente extends StatelessWidget {
  const _TarjetaResumenPaciente({
    required this.paciente,
    required this.nivel,
    required this.diagnostico,
    required this.descripcionNivel,
  });

  final PacienteEntity paciente;
  final int nivel;
  final String? diagnostico;
  final String descripcionNivel;

  static String _nivelTexto(int nivel) {
    switch (nivel) {
      case 1:
        return 'N1 — Cuidador';
      case 2:
        return 'N2 — Estudiante';
      case 3:
        return 'N3 — Enfermero';
      default:
        return 'N1 — Cuidador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final edad = paciente.edad;
    final d = diagnostico?.trim();
    final diag = (d != null && d.isNotEmpty) ? d : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2DFDB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3E6F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Solicitando para:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paciente.nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _kAzulVitta,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (edad != null) '$edad años',
              _nivelTexto(nivel),
            ].join(' · '),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buscando: $descripcionNivel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kAzulVitta.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.healing_rounded, size: 18, color: _kAzulVitta.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diagnóstico: $diag',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcionTipo extends StatelessWidget {
  const _OpcionTipo({
    required this.titulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: seleccionado ? _kAzulVitta : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAzulVitta, width: seleccionado ? 2.5 : 1),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? Colors.white : _kAzulVitta,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seleccionado ? Colors.white : _kAzulVitta,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
