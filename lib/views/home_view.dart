import 'package:flutter/material.dart';

import 'area_profesional_view.dart';
import 'panel_control_view.dart';
import 'registro_familiar_view.dart';
import 'registro_profesional_view.dart';

/// Pantalla de inicio: accesos rápidos y enlaces de registro.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final azul = Colors.blue.shade900;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Icon(Icons.health_and_safety_rounded, size: 72, color: azul),
              const SizedBox(height: 12),
              Text(
                'VITTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: azul,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuidado de adultos mayores con profesionales de confianza',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Acceso rápido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: azul,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _AccesoRapidoCard(
                icon: Icons.family_restroom_rounded,
                titulo: 'Entrar como Familiar',
                subtitulo: 'Panel de cuidado y búsqueda de ayuda',
                colorIcono: azul,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const PanelControlView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AccesoRapidoCard(
                icon: Icons.medical_services_rounded,
                titulo: 'Entrar como Profesional',
                subtitulo: 'Área para equipo de salud y cuidadores',
                colorIcono: Colors.teal.shade700,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AreaProfesionalView(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.blue.shade100, thickness: 1),
              const SizedBox(height: 20),

              Text(
                '¿Todavía no tenés cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: azul,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elegí cómo querés sumarte a Vitta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),

              _RegistroLink(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Registrarme como Familiar',
                azul: azul,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const RegistroFamiliarView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _RegistroLink(
                icon: Icons.badge_outlined,
                label: 'Unirme como Profesional',
                azul: azul,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const RegistroProfesionalView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  const _AccesoRapidoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.colorIcono,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color colorIcono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.blue.shade100,
      borderRadius: BorderRadius.circular(14),
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
                  color: colorIcono.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: colorIcono),
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
    );
  }
}

class _RegistroLink extends StatelessWidget {
  const _RegistroLink({
    required this.icon,
    required this.label,
    required this.azul,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color azul;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: azul,
        side: BorderSide(color: azul.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: azul.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
