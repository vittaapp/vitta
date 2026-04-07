// lib/views/validacion_id_view.dart
import 'package:flutter/material.dart';

class ValidacionIdView extends StatefulWidget {
  const ValidacionIdView({super.key});

  @override
  State<ValidacionIdView> createState() => _ValidacionIdViewState();
}

class _ValidacionIdViewState extends State<ValidacionIdView> {
  int pasoActual = 1; // 1: DNI, 2: Rostro, 3: Finalizado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verificación de Identidad")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Barra de progreso para que el usuario no se canse
            LinearProgressIndicator(value: pasoActual / 3, backgroundColor: Colors.grey[200]),
            const SizedBox(height: 30),

            Expanded(
              child: pasoActual == 1 ? _seccionDNI() : (pasoActual == 2 ? _seccionRostro() : _seccionExito()),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (pasoActual < 3) pasoActual++;
                  else Navigator.pop(context); // Vuelve al inicio al terminar
                });
              },
              child: Text(pasoActual < 3 ? "CONTINUAR" : "FINALIZAR"),
            )
          ],
        ),
      ),
    );
  }

  Widget _seccionDNI() {
    return Column(
      children: [
        const Icon(Icons.badge_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text("Paso 1: Foto del DNI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("Asegurate de que se vean bien todos los datos", textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2, style: BorderStyle.solid),
          ),
          child: const Icon(Icons.camera_alt, size: 50, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _seccionRostro() {
    return Column(
      children: [
        const Icon(Icons.face_retouching_natural, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text("Paso 2: Validación Facial", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("Mirá a la cámara y mantené el rostro en el círculo", textAlign: TextAlign.center),
        const SizedBox(height: 40),
        const CircleAvatar(
          radius: 90,
          backgroundColor: Colors.blue,
          child: CircleAvatar(radius: 85, backgroundColor: Colors.white, child: Icon(Icons.person, size: 100, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _seccionExito() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 100, color: Colors.green),
        SizedBox(height: 20),
        Text("¡Datos recibidos!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("Nuestro equipo auditará tu identidad en las próximas 24hs.", textAlign: TextAlign.center),
      ],
    );
  }
}