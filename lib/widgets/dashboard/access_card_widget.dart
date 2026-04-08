import 'package:flutter/material.dart';

/// Widget tarjeta de acceso rápido a secciones de la app.
///
/// Muestra un ícono, título y subtítulo con efecto ripple.
/// Reutilizable para diferentes accesos en el dashboard.
///
/// Parámetros:
/// - `icono`: IconData a mostrar
/// - `titulo`: Título de la sección
/// - `subtitulo`: Descripción breve
/// - `onTap`: Callback cuando se presiona
class AccessCardWidget extends StatelessWidget {
  const AccessCardWidget({
    Key? key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  }) : super(key: key);

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  static const Color _azul = Color(0xFF0D47A1);

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
              color: _azul.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 28, color: _azul),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _azul,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.grey.shade700,
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
