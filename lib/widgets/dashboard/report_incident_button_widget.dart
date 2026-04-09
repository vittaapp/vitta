import 'package:flutter/material.dart';

const Color _rojoEmergencia = Color(0xFFD32F2F);
const Color _fondoRojoClaro = Color(0xFFFFF5F5);

/// Widget que muestra el botón para reportar incidentes.
class ReportIncidentButtonWidget extends StatelessWidget {
  const ReportIncidentButtonWidget({
    Key? key,
    required this.minHeight,
    required this.onPressed,
  }) : super(key: key);

  final double minHeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.emergency_share_rounded, size: 24),
      label: const Text(
        'Reportar incidente',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _rojoEmergencia,
        backgroundColor: _fondoRojoClaro,
        side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        minimumSize: Size.fromHeight(minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
