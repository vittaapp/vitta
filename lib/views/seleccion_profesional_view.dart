// lib/views/seleccion_profesional_view.dart
import 'package:flutter/material.dart';
import '../models/domain/profesional_domain.dart';
import '../models/domain/paciente_domain.dart';
import '../models/entities/profesional_entity.dart';

class SeleccionProfesionalView extends StatelessWidget {
  final NivelRiesgo riesgoDelPaciente;

  const SeleccionProfesionalView({super.key, required this.riesgoDelPaciente});

  @override
  Widget build(BuildContext context) {
    // Simulamos una lista de profesionales que se postularon
    final List<ProfesionalDomain> disponibles = [
      ProfesionalDomain(id: "1", nombre: "Lic. Marcos Paz", email: "", rol: "profesional", tipo: TipoProfesional.enfermeroUniversitario, matriculaProfesional: "1234"),
      ProfesionalDomain(id: "2", nombre: "Ana Torres", email: "", rol: "profesional", tipo: TipoProfesional.cuidadorDomiciliario),
      ProfesionalDomain(id: "3", nombre: "Sra. Betty", email: "", rol: "profesional", tipo: TipoProfesional.auxiliarEnfermeria, matriculaProfesional: "5566"),
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
                bool esApto = pro.puedeAtenderRiesgo(riesgoDelPaciente.name);

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