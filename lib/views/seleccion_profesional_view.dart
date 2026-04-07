// lib/views/seleccion_profesional_view.dart
import 'package:flutter/material.dart';
import '../models/profesional_model.dart';
import '../models/paciente_model.dart';

class SeleccionProfesionalView extends StatelessWidget {
  final NivelRiesgo riesgoDelPaciente;

  const SeleccionProfesionalView({super.key, required this.riesgoDelPaciente});

  @override
  Widget build(BuildContext context) {
    // Simulamos una lista de profesionales que se postularon
    final List<Profesional> disponibles = [
      Profesional(id: "1", nombre: "Lic. Marcos Paz", tipo: TipoProfesional.enfermeroUniversitario, matricula: "1234"),
      Profesional(id: "2", nombre: "Ana Torres", tipo: TipoProfesional.cuidadorDomiciliario),
      Profesional(id: "3", nombre: "Sra. Betty", tipo: TipoProfesional.auxiliarEnfermeria, matricula: "5566"),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Profesionales Recomendados")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.amber[100],
            child: const Text("🛡️ Solo mostramos profesionales que cumplen con el nivel de seguridad requerido para este paciente."),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: disponibles.length,
              itemBuilder: (context, index) {
                final pro = disponibles[index];

                // AQUÍ USAMOS LA LÓGICA DE SEGURIDAD
                bool esApto = pro.puedeAtenderRiesgo(riesgoDelPaciente);

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                  title: Text(pro.nombre),
                  subtitle: Text(pro.tipo.name.replaceAll("TipoProfesional.", "")),
                  trailing: esApto
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.block, color: Colors.red),
                  enabled: esApto, // Si no es apto, no puede hacer click
                  onTap: esApto ? () {
                    print("Contratando a ${pro.nombre}");
                  } : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}