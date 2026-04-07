import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Azul Vitta y verde éxito — cursor_rules.
const Color _kAzulVitta = Color(0xFF1A3E6F);
const Color _kVerdeExito = Color(0xFF2E7D32);

const double _kAlturaBotonMin = 56;

const List<String> _kDiagnosticos = [
  'Adulto Mayor',
  'Diabetes',
  'Hipertensión',
  'Alzheimer',
  'Post-operatorio',
  'EPOC',
  'Otro',
];

const List<String> _kGruposSanguineos = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

/// N1 → acompañamiento, N2 → salud, N3 → clinico (vitta_rules).
String _planActivoDesdeNivel(String nivelNx) {
  switch (nivelNx) {
    case 'N1':
      return 'acompañamiento';
    case 'N2':
      return 'salud';
    case 'N3':
      return 'clinico';
    default:
      return 'acompañamiento';
  }
}

/// Registro de paciente en Firestore (`pacientes`) por el familiar.
class RegistroPacienteView extends StatefulWidget {
  const RegistroPacienteView({super.key});

  @override
  State<RegistroPacienteView> createState() => _RegistroPacienteViewState();
}

class _RegistroPacienteViewState extends State<RegistroPacienteView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _otrasPatologiasController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _obraSocialController = TextEditingController();
  final _localidadController = TextEditingController(text: 'San Miguel de Tucumán');
  final _provinciaController = TextEditingController(text: 'Tucumán');

  String? _diagnosticoPrincipal;
  String? _grupoSanguineo;
  String _nivelSeleccionado = 'N1';

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _otrasPatologiasController.dispose();
    _alergiasController.dispose();
    _obraSocialController.dispose();
    _localidadController.dispose();
    _provinciaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('No hay sesión activa.', error: true);
      return;
    }

    final edad = int.tryParse(_edadController.text.trim());
    if (edad == null || edad < 0 || edad > 130) {
      _snack('Indicá una edad válida.', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      final planActivo = _planActivoDesdeNivel(_nivelSeleccionado);
      final nivelCuidado = _nivelSeleccionado == 'N1'
          ? 1
          : _nivelSeleccionado == 'N2'
              ? 2
              : 3;

      await FirebaseFirestore.instance.collection('pacientes').add({
        'familiarId': uid,
        'nombre': _nombreController.text.trim(),
        'edad': edad,
        'diagnosticoPrincipal': _diagnosticoPrincipal,
        'otrasPatologias': _otrasPatologiasController.text.trim(),
        'alergias': _alergiasController.text.trim(),
        'grupoSanguineo': _grupoSanguineo ?? '',
        'obraSocialPrepaga': _obraSocialController.text.trim(),
        'nivelCuidado': nivelCuidado,
        'nivelCuidadoEtiqueta': _nivelSeleccionado,
        'localidad': _localidadController.text.trim(),
        'provincia': _provinciaController.text.trim(),
        'planActivo': planActivo,
        'diagnostico': _diagnosticoPrincipal,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paciente registrado correctamente.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _kVerdeExito,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _snack('No se pudo guardar: $e', error: true);
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        backgroundColor: _kAzulVitta,
        foregroundColor: Colors.white,
        title: const Text(
          'Registrar paciente',
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
              Text(
                'Datos del familiar a cuidar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Nombre completo *', Icons.person_outline_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Completá el nombre';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _edadController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Edad *', Icons.cake_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Completá la edad';
                  if (int.tryParse(v.trim()) == null) return 'Solo números';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _diagnosticoPrincipal,
                decoration: _decoration('Diagnóstico principal *', Icons.healing_outlined),
                hint: const Text('Seleccioná una opción'),
                items: _kDiagnosticos
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _diagnosticoPrincipal = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Elegí un diagnóstico' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otrasPatologiasController,
                maxLines: 2,
                decoration: _decoration('Otras patologías', Icons.list_alt_rounded),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alergiasController,
                maxLines: 2,
                decoration: _decoration('Alergias', Icons.warning_amber_rounded),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _grupoSanguineo,
                decoration: _decoration('Grupo sanguíneo', Icons.bloodtype_rounded),
                hint: const Text('Opcional'),
                items: _kGruposSanguineos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _grupoSanguineo = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obraSocialController,
                decoration: _decoration('Obra social / prepaga', Icons.health_and_safety_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localidadController,
                decoration: _decoration('Localidad', Icons.place_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _provinciaController,
                decoration: _decoration('Provincia', Icons.map_outlined),
              ),
              const SizedBox(height: 20),
              Text(
                'Nivel de cuidado requerido *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _SelectorNivelCuidado(
                seleccionado: _nivelSeleccionado,
                onChanged: (n) => setState(() => _nivelSeleccionado = n),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAzulVitta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(_kAlturaBotonMin),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Guardar paciente',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kAzulVitta.withValues(alpha: 0.85)),
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

class _SelectorNivelCuidado extends StatelessWidget {
  const _SelectorNivelCuidado({
    required this.seleccionado,
    required this.onChanged,
  });

  final String seleccionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NivelOpcion(
            titulo: 'N1',
            subtitulo: 'Cuidador',
            icono: Icons.front_hand_outlined,
            seleccionado: seleccionado == 'N1',
            onTap: () => onChanged('N1'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NivelOpcion(
            titulo: 'N2',
            subtitulo: 'Estudiante',
            icono: Icons.school_outlined,
            seleccionado: seleccionado == 'N2',
            onTap: () => onChanged('N2'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NivelOpcion(
            titulo: 'N3',
            subtitulo: 'Enfermero',
            icono: Icons.medical_services_outlined,
            seleccionado: seleccionado == 'N3',
            onTap: () => onChanged('N3'),
          ),
        ),
      ],
    );
  }
}

class _NivelOpcion extends StatelessWidget {
  const _NivelOpcion({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: seleccionado ? _kAzulVitta : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _kAzulVitta,
            width: seleccionado ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? Colors.white : _kAzulVitta,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: seleccionado ? Colors.white : _kAzulVitta,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: seleccionado ? Colors.white70 : _kAzulVitta.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
