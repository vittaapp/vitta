import 'package:flutter/material.dart';

class CheckInView extends StatelessWidget {
  final String nombrePaciente;
  const CheckInView({super.key, required this.nombrePaciente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Check-In")),
      body: Center(child: Text("Iniciando visita para $nombrePaciente")),
    );
  }
}