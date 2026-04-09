import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usuario_rol_provider.dart';

const Color _azulVitta = Color(0xFF0066CC);
const Color _nivelN1 = Color(0xFF5DCAA5);
const Color _nivelN2 = Color(0xFFF57F17);
const Color _nivelN3 = Color(0xFF534AB7);

/// Widget de onboarding para completar perfil profesional.
/// ConsumerStatefulWidget para acceder a providers y mantener estado local.
class ProfessionalOnboardingWidget extends ConsumerStatefulWidget {
  const ProfessionalOnboardingWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfessionalOnboardingWidget> createState() =>
      _ProfessionalOnboardingWidgetState();
}

class _ProfessionalOnboardingWidgetState
    extends ConsumerState<ProfessionalOnboardingWidget> {
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

  /// Guardar datos del perfil profesional en Firestore
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

      // Invalidar provider para refrescar datos
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

  /// Selector visual de nivel profesional con animación
  Widget _selectorNivel() {
    Widget tile(int nivel, String label, Color color) {
      final isSelected = _nivel == nivel;
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
                color: isSelected ? color.withValues(alpha: 0.22) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
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
                      color: isSelected ? color : Colors.grey.shade700,
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
            // Campo matrícula (solo para N3)
            if (_nivel == 3) ...[
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula profesional *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La matrícula es obligatoria para N3';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            // Campo institución (solo para N2)
            if (_nivel == 2) ...[
              TextFormField(
                controller: _institucionController,
                decoration: InputDecoration(
                  labelText: 'Institución educativa *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indicá tu institución';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            // Campo especialidad (todos)
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
              onChanged: (value) => setState(() => _manana = value ?? false),
              title: const Text('Mañana'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _tarde,
              onChanged: (value) => setState(() => _tarde = value ?? false),
              title: const Text('Tarde'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _noche,
              onChanged: (value) => setState(() => _noche = value ?? false),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
