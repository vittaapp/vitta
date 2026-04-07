import 'package:flutter/material.dart';

import '../models/perfil_paciente_registro.dart';

/// Registro de familiar responsable (quien contrata) + datos del paciente a cuidar.
class RegistroFamiliarView extends StatefulWidget {
  const RegistroFamiliarView({super.key});

  @override
  State<RegistroFamiliarView> createState() => _RegistroFamiliarViewState();
}

class _RegistroFamiliarViewState extends State<RegistroFamiliarView> {
  static const Color _azulVitta = Color(0xFF0D47A1);
  static const Color _azulVittaClaro = Color(0xFF1565C0);

  final _nombreFamiliarController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nombrePacienteController = TextEditingController();
  final _edadPacienteController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _obraSocialPacienteController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();

  String? _necesidadPrincipal;
  bool _ocultarPassword = true;
  bool _autorizaEmergenciasDesdeApp = false;

  final List<String> _necesidades = [
    'Acompañamiento',
    'Post-operatorio',
    'Adulto Mayor',
    'Pediatría',
    'Discapacidad',
  ];

  @override
  void dispose() {
    _nombreFamiliarController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombrePacienteController.dispose();
    _edadPacienteController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _obraSocialPacienteController.dispose();
    _telefonoEmergenciaController.dispose();
    super.dispose();
  }

  Future<void> _crearCuentaYGuardarPerfilPaciente() async {
    final perfil = PerfilPacienteRegistro(
      nombrePaciente: _nombrePacienteController.text.trim(),
      edadPaciente: _edadPacienteController.text.trim(),
      necesidadPrincipal: _necesidadPrincipal,
      descripcionNecesidad: _descripcionController.text.trim(),
      ubicacionServicio: _ubicacionController.text.trim(),
      obraSocialPrepaga: _obraSocialPacienteController.text.trim(),
      telefonoEmergencia: _telefonoEmergenciaController.text.trim().isEmpty
          ? ''
          : '+54${_telefonoEmergenciaController.text.trim()}',
      autorizaContactoEmergenciaDesdeApp: _autorizaEmergenciasDesdeApp,
    );
    await PerfilPacienteRegistro.guardar(perfil);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil del paciente guardado. El cuidador podrá ver cobertura y emergencias desde la app.',
          style: TextStyle(color: Colors.grey.shade900),
        ),
        backgroundColor: Colors.lightGreen.shade100,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _campo({
    required String label,
    String? hint,
    IconData? icon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _azulVittaClaro, width: 1.5),
      ),
      prefixIcon: icon != null ? Icon(icon, color: _azulVitta) : null,
      prefix: prefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro familiar responsable'),
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE8EEF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Creá tu cuenta y contanos a quién vamos a acompañar',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // —— Sección 1 ——
            _SeccionCard(
              titulo: 'Datos del familiar',
              subtitulo: 'El que contrata el servicio',
              icono: Icons.person_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombreFamiliarController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _campo(
                      label: 'Nombre completo',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: _campo(
                      label: 'Teléfono de contacto',
                      hint: '9 11 1234 5678',
                    ).copyWith(
                      prefixIcon: const Icon(Icons.phone_outlined, color: _azulVitta),
                      prefixText: '+54 ',
                      prefixStyle: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _campo(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _ocultarPassword,
                    decoration: _campo(
                      label: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _azulVitta,
                        ),
                        onPressed: () {
                          setState(() => _ocultarPassword = !_ocultarPassword);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // —— Sección 2 ——
            _SeccionCard(
              titulo: 'Datos del paciente',
              subtitulo: 'A quién vamos a cuidar',
              icono: Icons.volunteer_activism_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombrePacienteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _campo(
                      label: 'Nombre del paciente',
                      hint: 'Ej: Mi abuelo, Mi hijo, Yo mismo',
                      icon: Icons.face_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _edadPacienteController,
                    keyboardType: TextInputType.number,
                    decoration: _campo(
                      label: 'Edad del paciente',
                      hint: 'Años',
                      icon: Icons.cake_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownMenu<String>(
                    width: MediaQuery.sizeOf(context).width - 40 - 36,
                    label: const Text('Necesidad principal'),
                    leadingIcon: const Icon(Icons.health_and_safety_outlined, color: _azulVitta),
                    hintText: 'Elegí una opción',
                    initialSelection: _necesidadPrincipal,
                    dropdownMenuEntries: [
                      for (final n in _necesidades)
                        DropdownMenuEntry<String>(value: n, label: n),
                    ],
                    onSelected: (v) => setState(() => _necesidadPrincipal = v),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descripcionController,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _campo(
                      label: 'Breve descripción',
                      hint:
                          'Contanos qué asistencia necesita, medicamentos, movilidad, etc.',
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _ubicacionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _campo(
                      label: 'Ubicación del servicio',
                      hint: 'Barrio o localidad en Tucumán',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.blue.shade100, thickness: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.emergency_outlined, color: _azulVittaClaro, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Contacto de emergencia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _azulVitta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Datos visibles para el profesional durante la guardia (un toque en la ficha del paciente).',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _obraSocialPacienteController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _campo(
                      label: 'Obra Social / Prepaga del paciente',
                      hint: 'Ej: OSDE, Swiss Medical, PAMI…',
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _telefonoEmergenciaController,
                    keyboardType: TextInputType.phone,
                    decoration: _campo(
                      label: 'Teléfono de emergencia',
                      hint: 'Médico, SAME, ambulancia u otro contacto',
                    ).copyWith(
                      prefixIcon: const Icon(Icons.phone_in_talk_outlined, color: _azulVitta),
                      prefixText: '+54 ',
                      prefixStyle: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _autorizaEmergenciasDesdeApp,
                    onChanged: (v) {
                      setState(() => _autorizaEmergenciasDesdeApp = v ?? false);
                    },
                    fillColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected) ? _azulVitta : null,
                    ),
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Autorizo al profesional a contactar a emergencias desde la app en caso de necesidad',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _azulVitta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _crearCuentaYGuardarPerfilPaciente,
                child: const Text(
                  'Crear Cuenta y Buscar Cuidador',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'El registro es gratuito. Solo pagás cuando decidís contratar un profesional verificado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.child,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: const Color(0xFF0D47A1), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
