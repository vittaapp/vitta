// lib/models/profesional_model.dart
import 'package:flutter/material.dart';

enum TipoProfesional {
  enfermeroUniversitario,
  auxiliarEnfermeria,
  cuidadorDomiciliario
}

class Profesional {
  final String id;
  final String nombre;
  final TipoProfesional tipo;
  final String matricula; // Solo obligatoria para enfermeros
  final bool identidadValidada; // Lo que sacamos del DNI y Rostro
  final String especialidad; // Ej: Pediatría, Geriatría, Post-operatorio

  Profesional({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.matricula = "",
    this.identidadValidada = false,
    this.especialidad = "General",
  });

  // Esta función es MAGIA: te dice qué colores de pacientes puede atender
  bool puedeAtenderRiesgo(dynamic nivelRiesgo) {
    if (tipo == TipoProfesional.enfermeroUniversitario) return true; // Atiende a todos
    if (tipo == TipoProfesional.auxiliarEnfermeria && nivelRiesgo != "Rojo") return true;
    if (tipo == TipoProfesional.cuidadorDomiciliario && nivelRiesgo == "Verde") return true;
    return false;
  }
}