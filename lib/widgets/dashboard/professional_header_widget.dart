import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _azulVitta = Color(0xFF0066CC);

/// Widget que muestra el encabezado del profesional con foto, nombre y email.
class ProfessionalHeaderWidget extends StatelessWidget {
  const ProfessionalHeaderWidget({
    Key? key,
    required this.user,
    required this.nombreFirestore,
  }) : super(key: key);

  final User? user;
  final String? nombreFirestore;

  @override
  Widget build(BuildContext context) {
    final nombre = (nombreFirestore != null && nombreFirestore!.trim().isNotEmpty)
        ? nombreFirestore!.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Profesional Vitta');

    final fotoUrl = user?.photoURL;

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: fotoUrl != null && fotoUrl.isNotEmpty
                ? Image.network(
                    fotoUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: _azulVitta,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: _azulVitta,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _azulVitta,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
