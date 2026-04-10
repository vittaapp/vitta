import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_app/constants/contacto_vitta.dart';

const Color _rojoEmergencia = Color(0xFFB71C1C);

/// Widget secundario para contactar soporte en caso de emergencia.
class EmergencyContactWidget extends StatelessWidget {
  const EmergencyContactWidget({super.key});

  Future<void> _llamarSoporte(BuildContext context) async {
    final digits = kTelefonoSoporteEmergenciaVitta.replaceAll(RegExp(r'\s'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el marcador. Llamá desde tu teléfono.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el marcador.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _rojoEmergencia.withValues(alpha: 0.07),
        border: Border.all(color: _rojoEmergencia.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: _rojoEmergencia.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Emergencia?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _rojoEmergencia,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contactá a Soporte Vitta 24/7',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _llamarSoporte(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _rojoEmergencia,
                side: BorderSide(color: _rojoEmergencia.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.phone_rounded, size: 20),
              label: const Text(
                'Llamar ahora',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
