// lib/views/widgets/sos_button.dart
import 'package:flutter/material.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  void _confirmarSOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🚨 ¿CONFIRMAR EMERGENCIA?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Se notificará de inmediato a los familiares y a la central de Vitta con tu ubicación actual."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Aquí llamamos al EmergenciaService
              print("¡SOS ACTIVADO!");
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ALERTA SOS ENVIADA. Mantené la calma, la ayuda está en camino."), backgroundColor: Colors.red)
              );
            },
            child: const Text("SÍ, ENVIAR SOS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _confirmarSOS(context),
      backgroundColor: Colors.red,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: const Text("BOTÓN SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}