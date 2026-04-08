import 'package:flutter/material.dart';

class EmergencyButtonWidget extends StatelessWidget {
  const EmergencyButtonWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const Color _rojoOscuro = Color(0xFFB71C1C);
  static const Color _fondoRojoClaro = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.emergency_rounded, size: 26),
        label: const Text(
          'Necesito un cuidador AHORA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _rojoOscuro,
          backgroundColor: _fondoRojoClaro,
          side: const BorderSide(color: _rojoOscuro, width: 1.5),
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
