import 'package:flutter/material.dart';
import 'package:vitta_app/views/registro_paciente_view.dart';

// Color constante (deberás definir esto en tu app o importarlo de un archivo de constantes)
const Color _kAzulVitta = Color(0xFF0066CC); // Ajusta según tu color real

/// Widget de bienvenida para familiares en el dashboard.
/// 
/// Muestra un onboarding inicial que guía al familiar a registrar a su paciente.
/// 
/// Parámetro:
/// - `onRegistroExitoso`: Callback invocado cuando el registro se completa exitosamente.
class OnboardingFamiliarBienvenidaWidget extends StatelessWidget {
  /// Callback cuando el registro de paciente se completa exitosamente.
  final VoidCallback onRegistroExitoso;

  const OnboardingFamiliarBienvenidaWidget({
    Key? key,
    required this.onRegistroExitoso,
  }) : super(key: key);

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
