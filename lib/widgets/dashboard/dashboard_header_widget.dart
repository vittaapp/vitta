import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _kAzulVittaHeader = Color(0xFF1A3E6F);

class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  static const Color _azulBanner = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombreUsuario = user?.displayName?.trim() ?? '';
    final photoUrl = user?.photoURL;
    final saludo = nombreUsuario.isNotEmpty ? 'Hola, $nombreUsuario' : 'Hola';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBDEFB)),
            boxShadow: [
              BoxShadow(
                color: _kAzulVittaHeader.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFE3F2FD),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 48,
                            color: _kAzulVittaHeader.withValues(alpha: 0.9),
                          ),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFFE3F2FD),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.account_circle_rounded,
                          size: 48,
                          color: _kAzulVittaHeader.withValues(alpha: 0.9),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saludo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade300.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                            color: Colors.green.shade800,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Hogar Protegido por Vitta',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5FE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF81D4FA).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _azulBanner.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 30, height: 1.1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Garantía Vitta activa: Ante cualquier inasistencia del cuidador, te enviamos un suplente verificado en menos de 2 horas.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
