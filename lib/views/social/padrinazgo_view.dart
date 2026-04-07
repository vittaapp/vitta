// lib/views/social/padrinazgo_view.dart
import 'package:flutter/material.dart';

class PadrinazgoView extends StatelessWidget {
  const PadrinazgoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Programa de Padrinos"),
        backgroundColor: Colors.teal[700], // Un color más "social" para diferenciar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ESPACIO PARA CO-BRANDING
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cuando tengas el PNG: añadir assets/logo_vitta.png y `assets:` en pubspec, luego:
                // Image.asset('assets/logo_vitta.png', height: 60),
                const Icon(Icons.health_and_safety, size: 60, color: Colors.blue),
                const Icon(Icons.add, color: Colors.grey),
                const Icon(Icons.foundation, size: 60, color: Colors.teal), // Logo de la ONG (Ej: Fundación Fuente)
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              "Tu aporte va 100% al Profesional",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Vitta dona la plataforma y la gestión para que este abuelo esté siempre protegido.",
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 40),

            // Tarjeta del "Ahijado"
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
                    const SizedBox(height: 15),
                    const Text("Doña Rosa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text("Barrio San Martín - Vulnerabilidad Alta"),
                    const Divider(height: 30),
                    _itemInfo("Estado:", "Controlado", Colors.green),
                    _itemInfo("Última Visita:", "Hoy 10:30 hs", Colors.black),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () {},
                      child: const Text("VER REPORTE DIARIO", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemInfo(String label, String valor, Color colorValor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(valor, style: TextStyle(color: colorValor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}