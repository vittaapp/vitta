import 'package:flutter/material.dart';

const Color _azulVitta = Color(0xFF0066CC);
const Color _fondoWallet = Color(0xFFF0F8FF);

/// Widget que muestra la tarjeta de saldo/wallet del profesional.
/// Displays available balance, pending balance, y botón de historial.
class ProfessionalWalletCardWidget extends StatelessWidget {
  const ProfessionalWalletCardWidget({
    Key? key,
    required this.minButtonHeight,
  }) : super(key: key);

  final double minButtonHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _fondoWallet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo disponible',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const Text(
                      '\$0.00',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _azulVitta,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo pendiente',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      '\$0.00',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial de pagos — próximamente.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _azulVitta,
                side: const BorderSide(color: _azulVitta, width: 1.5),
                minimumSize: Size.fromHeight(minButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver historial de pagos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
