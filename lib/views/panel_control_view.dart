import 'package:flutter/material.dart';

import 'familiar_dashboard_view.dart';
import 'lista_cuidadores_view.dart';
import 'perfil_paciente_familiar_view.dart';

/// Panel principal exclusivo para el familiar / responsable.
class PanelControlView extends StatelessWidget {
  const PanelControlView({super.key});

  static const Color _azul = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        title: const Text('Panel de Control VITTA'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _azul),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestioná el cuidado y encontrá profesionales de confianza.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 28),
            _TarjetaAccion(
              icono: Icons.dashboard_customize_rounded,
              colorIcono: _azul,
              titulo: 'Centro de comando',
              subtitulo: 'Tu hogar, abuelos, pagos y seguridad en un solo lugar',
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const FamiliarDashboardView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _TarjetaAccion(
              icono: Icons.search_rounded,
              colorIcono: _azul,
              titulo: 'Buscar Profesionales',
              subtitulo: 'Enfermeros, estudiantes y cuidadores',
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ListaCuidadoresView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _TarjetaAccion(
              icono: Icons.favorite_border_rounded,
              colorIcono: _azul,
              titulo: 'Mi Familiar / Perfil del Paciente',
              subtitulo: 'Salud, cobertura y contactos de emergencia',
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const PerfilPacienteFamiliarView(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  const _TarjetaAccion({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBDEFB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, size: 32, color: colorIcono),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
