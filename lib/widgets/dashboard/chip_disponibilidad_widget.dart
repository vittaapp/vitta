import 'package:flutter/material.dart';

/// Widget que muestra un chip de disponibilidad con ícono y etiqueta.
class ChipDisponibilidadWidget extends StatelessWidget {
  const ChipDisponibilidadWidget({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
