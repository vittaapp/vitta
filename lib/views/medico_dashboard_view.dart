import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_view.dart';

/// Colores semánticos — `vitta_rules.md` (cursor rules).
const Color _azulAppBar = Color(0xFF1A3E6F);
const Color _rojoEmergencia = Color(0xFFB71C1C);
const Color _amberMedio = Color(0xFFF57F17);
const Color _verdeConfianza = Color(0xFF2E7D32);

/// Tablero del médico director: semáforo clínico (rojo / amarillo / verde).
class MedicoDashboardView extends StatelessWidget {
  const MedicoDashboardView({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        backgroundColor: _azulAppBar,
        foregroundColor: Colors.white,
        title: const Text('Panel médico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TableroTarjeta(
            titulo: 'Signos vitales fuera de rango',
            subtitulo:
                'Pacientes que requieren revisión clínica prioritaria según últimos registros.',
            colorBarra: _rojoEmergencia,
            fondoSuave: Color(0xFFFFEBEE),
            icono: Icons.warning_amber_rounded,
          ),
          SizedBox(height: 14),
          _TableroTarjeta(
            titulo: 'Notas pendientes de validación',
            subtitulo:
                'Notas del cuidador sin registro oficial validado por médico.',
            colorBarra: _amberMedio,
            fondoSuave: Color(0xFFFFF8E1),
            icono: Icons.pending_actions_outlined,
          ),
          SizedBox(height: 14),
          _TableroTarjeta(
            titulo: 'Todo en orden',
            subtitulo:
                'Pacientes sin alertas de signos vitales ni notas pendientes de validación.',
            colorBarra: _verdeConfianza,
            fondoSuave: Color(0xFFE8F5E9),
            icono: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _TableroTarjeta extends StatelessWidget {
  const _TableroTarjeta({
    required this.titulo,
    required this.subtitulo,
    required this.colorBarra,
    required this.fondoSuave,
    required this.icono,
  });

  final String titulo;
  final String subtitulo;
  final Color colorBarra;
  final Color fondoSuave;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBarra.withValues(alpha: 0.35)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: colorBarra),
            Expanded(
              child: Container(
                color: fondoSuave,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icono, color: colorBarra, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorBarra,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
