// lib/models/paciente_model.dart
import 'package:flutter/material.dart';

// 1. El Semáforo de Seguridad (Protocolo)
enum NivelRiesgo {
  rojo,     // Crítico / Post-operatorio
  amarillo, // Intermedio / Medicación
  verde     // Bajo / Acompañamiento
}

// 2. El Corazón de la App: La Historia Clínica
class HistoriaClinica {
  final List<String> medicamentos;
  final List<String> alergias;
  final String antecedentes;
  final List<String> registrosDiarios; // Lo que el enfermero anota cada día

  HistoriaClinica({
    this.medicamentos = const [],
    this.alergias = const [],
    this.antecedentes = "",
    this.registrosDiarios = const [],
  });
}

// 3. El Paciente Completo
class Paciente {
  final String id;
  final String nombre;
  final NivelRiesgo riesgo;
  final String diagnosticoBreve;
  final HistoriaClinica historia; // Aquí conectamos la historia con el paciente

  Paciente({
    required this.id,
    required this.nombre,
    required this.riesgo,
    required this.diagnosticoBreve,
    required this.historia,
  });

  // Función para obtener el color automático según el protocolo de seguridad
  Color get colorProtocolo {
    switch (riesgo) {
      case NivelRiesgo.rojo: return Colors.red;
      case NivelRiesgo.amarillo: return Colors.orange;
      case NivelRiesgo.verde: return Colors.green;
    }
  }
}