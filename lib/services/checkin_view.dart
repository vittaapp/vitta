// lib/views/checkin_view.dart
import 'package:flutter/material.dart';

class CheckInView extends StatefulWidget {
  final String nombrePaciente;
  const CheckInView({super.key, required this.nombrePaciente});

  @override
  State<CheckInView> createState() => _CheckInViewState();
}

class _CheckInViewState extends State<CheckInView> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inicio de Servicio")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                "Llegada a lo de ${widget.nombrePaciente}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Presioná el botón para validar tu ubicación e iniciar el cuidado.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              _procesando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("VALIDAR LLEGADA (QR / GPS)"),
                onPressed: () async {
                  setState(() => _procesando = true);

                  // Simulamos la validación
                  await Future.delayed(const Duration(seconds: 2));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Ingreso validado. ¡Buen trabajo!"))
                    );
                    // Aquí lo mandamos a la pantalla de "Reporte Diario" que ya hicimos
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}