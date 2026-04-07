import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nota_cuidador_pendiente.dart';
import '../models/usuario_model.dart';
import '../models/signos_vitales.dart';
import '../providers/usuario_rol_provider.dart';
import '../services/historial_service.dart';

/// Colores — secc. 13 `vitta_rules.md`
const Color _azulVitta = Color(0xFF1A3E6F);
const Color _purpuraNivel3 = Color(0xFF534AB7);

final _historialServiceProvider = Provider<HistorialService>((ref) {
  return HistorialService();
});

/// Historia clínica con pestañas: Notas familiares (azul) y Evolución médica (púrpura).
///
/// La evolución médica solo es editable si el rol es `enfermero_n3` o `medico` (secc. 21 + reglas).
class HistorialPestanasView extends ConsumerStatefulWidget {
  const HistorialPestanasView({
    super.key,
    required this.pacienteId,
    this.nombrePaciente,
    this.turnoId = '',
  });

  final String pacienteId;
  final String? nombrePaciente;

  /// Turno activo; si está vacío se usa placeholder al guardar.
  final String turnoId;

  @override
  ConsumerState<HistorialPestanasView> createState() =>
      _HistorialPestanasViewState();
}

class _HistorialPestanasViewState extends ConsumerState<HistorialPestanasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _notasController = TextEditingController();

  final _tensionController = TextEditingController();
  final _tempController = TextEditingController();
  final _fcController = TextEditingController();
  final _satController = TextEditingController();
  final _frController = TextEditingController();
  final _glucemiaController = TextEditingController();
  final _evoDescripcionController = TextEditingController();
  final _notaCuidadorController = TextEditingController();

  bool _guardando = false;
  bool _guardandoNotaCuidador = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notasController.dispose();
    _tensionController.dispose();
    _tempController.dispose();
    _fcController.dispose();
    _satController.dispose();
    _frController.dispose();
    _glucemiaController.dispose();
    _evoDescripcionController.dispose();
    _notaCuidadorController.dispose();
    super.dispose();
  }

  Future<void> _guardarSignosVitales() async {
    final uid = ref.read(uidActualProvider);
    if (uid == null) {
      _snack('Iniciá sesión para registrar signos vitales.');
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
      frecuenciaRespiratoriaLpm: int.tryParse(_frController.text.trim()),
      glucemiaMgDl: int.tryParse(_glucemiaController.text.trim()),
    );

    if (!sv.tieneAlguno) {
      _snack('Completá al menos un signo vital.');
      return;
    }

    final usuario = _usuarioFirma();
    if (usuario == null) {
      _snack('No se pudo cargar tu perfil. Reintentá.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final svc = ref.read(_historialServiceProvider);
      await svc.crearRegistroConSignosVitales(
        pacienteId: widget.pacienteId,
        profesionalId: uid,
        turnoId: widget.turnoId.isEmpty ? 'sin_turno' : widget.turnoId,
        signosVitales: sv,
        nombreProfesional: usuario.nombre,
        matriculaProfesional: usuario.matriculaProfesional,
        descripcion: _evoDescripcionController.text.trim().isEmpty
            ? null
            : _evoDescripcionController.text.trim(),
      );
      if (mounted) {
        _snack('Signos vitales registrados (historial inmutable).');
        _tensionController.clear();
        _tempController.clear();
        _fcController.clear();
        _satController.clear();
        _frController.clear();
        _glucemiaController.clear();
        _evoDescripcionController.clear();
      }
    } catch (e) {
      if (mounted) {
        _snack('No se pudo guardar: $e');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarNotaCuidador() async {
    final uid = ref.read(uidActualProvider);
    if (uid == null) {
      _snack('Iniciá sesión para guardar la nota.');
      return;
    }
    final texto = _notaCuidadorController.text.trim();
    if (texto.isEmpty) {
      _snack('Escribí la nota del turno.');
      return;
    }

    final usuario = _usuarioFirma();
    if (usuario == null) {
      _snack('No se pudo cargar tu perfil. Reintentá.');
      return;
    }

    setState(() => _guardandoNotaCuidador = true);
    try {
      await ref.read(_historialServiceProvider).crearNotaCuidador(
            pacienteId: widget.pacienteId,
            profesionalId: uid,
            turnoId: widget.turnoId.isEmpty ? 'sin_turno' : widget.turnoId,
            texto: texto,
            nombreProfesional: usuario.nombre,
            matriculaProfesional: usuario.matriculaProfesional,
          );
      if (mounted) {
        _snack('Nota registrada. Un médico podrá validarla como registro oficial.');
        _notaCuidadorController.clear();
      }
    } catch (e) {
      if (mounted) _snack('No se pudo guardar la nota: $e');
    } finally {
      if (mounted) setState(() => _guardandoNotaCuidador = false);
    }
  }

  Future<void> _mostrarValidarNota(NotaCuidadorPendiente nota) async {
    final medicoId = ref.read(uidActualProvider);
    if (medicoId == null) return;

    final oficialController = TextEditingController(text: nota.texto);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validar nota como registro clínico'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nota del cuidador (${_fmtFecha(nota.fecha)})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                nota.texto,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('Texto del registro clínico oficial (editable):'),
              const SizedBox(height: 8),
              TextField(
                controller: oficialController,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Validar nota'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) {
      oficialController.dispose();
      return;
    }

    final textoOficial = oficialController.text.trim();
    oficialController.dispose();
    if (textoOficial.isEmpty) {
      _snack('El texto oficial no puede estar vacío.');
      return;
    }

    final usuario = _usuarioFirma();
    if (usuario == null) {
      _snack('No se pudo cargar tu perfil. Reintentá.');
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(_historialServiceProvider).validarNotaComoRegistroOficial(
            rolUsuario: usuario.rol,
            pacienteId: widget.pacienteId,
            medicoId: medicoId,
            turnoId: widget.turnoId.isEmpty ? 'sin_turno' : widget.turnoId,
            registroOrigenId: nota.id,
            textoOficial: textoOficial,
            nombreProfesional: usuario.nombre,
            matriculaProfesional: usuario.matriculaProfesional,
          );
      if (mounted) {
        _snack('Registro clínico oficial creado. La nota original permanece en el historial.');
      }
    } catch (e) {
      if (mounted) _snack('No se pudo validar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _fmtFecha(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// Perfil Firestore para firmar registros clínicos (nombre + matrícula).
  Usuario? _usuarioFirma() {
    return ref.read(usuarioActualProvider).value;
  }

  void _irTab(int i) {
    _tabController.animateTo(i);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final puedeEvo = ref.watch(puedeEditarEvolucionMedicaProvider);
    final puedeNotas = ref.watch(puedeEditarNotasFamiliaresProvider);
    final esMedico = ref.watch(esMedicoProvider);
    final esEnfermeroN3 = ref.watch(esEnfermeroN3Provider);
    final titulo = widget.nombrePaciente != null
        ? 'Historial — ${widget.nombrePaciente}'
        : 'Historial clínico';
    final idx = _tabController.index;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        title: Text(titulo),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Row(
            children: [
              Expanded(
                child: _PestanaCabecera(
                  seleccionada: idx == 0,
                  color: _azulVitta,
                  icono: Icons.family_restroom,
                  etiqueta: 'Notas familiares',
                  onTap: () => _irTab(0),
                ),
              ),
              Expanded(
                child: _PestanaCabecera(
                  seleccionada: idx == 1,
                  color: _purpuraNivel3,
                  icono: Icons.monitor_heart,
                  etiqueta: 'Evolución médica',
                  onTap: () => _irTab(1),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotasFamiliaresTab(
            color: _azulVitta,
            controller: _notasController,
            readOnly: !puedeNotas,
          ),
          _EvolucionMedicaTab(
            pacienteId: widget.pacienteId,
            color: _purpuraNivel3,
            readOnly: !puedeEvo,
            guardando: _guardando,
            guardandoNotaCuidador: _guardandoNotaCuidador,
            onGuardar: puedeEvo ? _guardarSignosVitales : null,
            esMedico: esMedico,
            esEnfermeroN3: esEnfermeroN3,
            onGuardarNotaCuidador:
                esEnfermeroN3 && puedeEvo ? _guardarNotaCuidador : null,
            onValidarNota: esMedico && puedeEvo ? _mostrarValidarNota : null,
            tensionController: _tensionController,
            tempController: _tempController,
            fcController: _fcController,
            satController: _satController,
            frController: _frController,
            glucemiaController: _glucemiaController,
            descripcionController: _evoDescripcionController,
            notaCuidadorController: _notaCuidadorController,
          ),
        ],
      ),
    );
  }
}

class _PestanaCabecera extends StatelessWidget {
  const _PestanaCabecera({
    required this.seleccionada,
    required this.color,
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  final bool seleccionada;
  final Color color;
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = seleccionada ? color : color.withValues(alpha: 0.45);
    return Material(
      color: base,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotasFamiliaresTab extends StatelessWidget {
  const _NotasFamiliaresTab({
    required this.color,
    required this.controller,
    required this.readOnly,
  });

  final Color color;
  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6F1FB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (readOnly)
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: _azulVitta),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solo lectura. Las notas familiares las edita el perfil familiar.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Observaciones y contexto del hogar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: readOnly
                  ? 'Sin permiso de edición'
                  : 'Escribí rutinas, preferencias, alertas para el equipo...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolucionMedicaTab extends ConsumerWidget {
  const _EvolucionMedicaTab({
    required this.pacienteId,
    required this.color,
    required this.readOnly,
    required this.guardando,
    required this.guardandoNotaCuidador,
    required this.onGuardar,
    required this.esMedico,
    required this.esEnfermeroN3,
    required this.onGuardarNotaCuidador,
    required this.onValidarNota,
    required this.tensionController,
    required this.tempController,
    required this.fcController,
    required this.satController,
    required this.frController,
    required this.glucemiaController,
    required this.descripcionController,
    required this.notaCuidadorController,
  });

  final String pacienteId;
  final Color color;
  final bool readOnly;
  final bool guardando;
  final bool guardandoNotaCuidador;
  final VoidCallback? onGuardar;
  final bool esMedico;
  final bool esEnfermeroN3;
  final Future<void> Function()? onGuardarNotaCuidador;
  final Future<void> Function(NotaCuidadorPendiente)? onValidarNota;
  final TextEditingController tensionController;
  final TextEditingController tempController;
  final TextEditingController fcController;
  final TextEditingController satController;
  final TextEditingController frController;
  final TextEditingController glucemiaController;
  final TextEditingController descripcionController;
  final TextEditingController notaCuidadorController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientesAsync =
        ref.watch(notasCuidadorPendientesProvider(pacienteId));

    return Container(
      color: const Color(0xFFF3F0FF),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (esMedico && onValidarNota != null) ...[
            Text(
              'Notas del cuidador pendientes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            pendientesAsync.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No hay notas de cuidador pendientes de validación.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                }
                return Column(
                  children: lista.map((n) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: color.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              n.texto,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: guardando
                                    ? null
                                    : () => onValidarNota!(n),
                                icon: const Icon(Icons.verified_outlined, size: 20),
                                label: const Text('Validar nota'),
                                style: FilledButton.styleFrom(
                                  foregroundColor: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error al cargar notas: $e'),
            ),
            const SizedBox(height: 20),
          ],
          if (esEnfermeroN3 && onGuardarNotaCuidador != null && !readOnly) ...[
            Text(
              'Nota de turno (cuidador)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const Text(
              'Quedará pendiente hasta que un médico la valide como registro clínico oficial.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notaCuidadorController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Observaciones del turno, cuidados, incidencias…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: guardandoNotaCuidador ? null : onGuardarNotaCuidador,
              icon: guardandoNotaCuidador
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.note_add_outlined),
              label: Text(
                guardandoNotaCuidador ? 'Guardando…' : 'Guardar nota del cuidador',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (readOnly)
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solo personal con rol enfermero N3 o médico puede cargar evolución y signos vitales.',
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Signos vitales',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _campo('Tensión arterial (ej. 120/80)', tensionController, readOnly),
          _campo('Temperatura (°C)', tempController, readOnly),
          _campo('Frecuencia cardíaca (lpm)', fcController, readOnly),
          _campo('Saturación O₂ (%)', satController, readOnly),
          _campo('Frecuencia respiratoria (rpm)', frController, readOnly),
          _campo('Glucemia (mg/dL)', glucemiaController, readOnly),
          const SizedBox(height: 12),
          Text(
            'Observación clínica',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descripcionController,
            readOnly: readOnly,
            maxLines: 4,
            decoration: _inputDeco('Opcional', color, readOnly),
          ),
          if (!readOnly) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: guardando ? null : onGuardar,
              icon: guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(guardando ? 'Guardando…' : 'Registrar en historial'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _campo(
    String label,
    TextEditingController c,
    bool readOnly,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        readOnly: readOnly,
        keyboardType: TextInputType.text,
        decoration: _inputDeco(label, _purpuraNivel3, readOnly),
      ),
    );
  }

  static InputDecoration _inputDeco(String hint, Color color, bool readOnly) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }
}
