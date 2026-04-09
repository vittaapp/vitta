import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import 'chip_disponibilidad_widget.dart';

const Color _azulVitta = Color(0xFF0066CC);
const Color _verdeVerificado = Color(0xFF2E7D32);

/// Widget que muestra la tarjeta de perfil del profesional.
/// Displays nivel, especialidad, disponibilidad, y botón para editar.
class MyProfileCardWidget extends StatelessWidget {
  const MyProfileCardWidget({
    Key? key,
    required this.usuario,
    required this.minButtonHeight,
  }) : super(key: key);

  final Usuario usuario;
  final double minButtonHeight;

  bool get _verificado {
    final m = usuario.matriculaProfesional?.trim();
    return m != null && m.isNotEmpty;
  }

  Color _colorNivel(int? nivel) {
    switch (nivel) {
      case 1:
        return Colors.blue.shade600;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _etiquetaNivel(int? nivel) {
    switch (nivel) {
      case 1:
        return 'N1 - Auxiliar';
      case 2:
        return 'N2 - Técnico';
      case 3:
        return 'N3 - Universitario';
      default:
        return 'Sin nivel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivelColor = _colorNivel(usuario.nivel);
    final esp = usuario.especialidad?.trim();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(
                    _etiquetaNivel(usuario.nivel),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: nivelColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (_verificado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _verdeVerificado.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _verdeVerificado),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: _verdeVerificado),
                        SizedBox(width: 4),
                        Text(
                          'Verificado Vitta',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _verdeVerificado,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (esp != null && esp.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information_outlined, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      esp,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Disponibilidad',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _azulVitta,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (usuario.disponibilidadManana)
                  ChipDisponibilidadWidget(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Mañana',
                    color: Colors.orange.shade700,
                  ),
                if (usuario.disponibilidadTarde)
                  ChipDisponibilidadWidget(
                    icon: Icons.cloud_rounded,
                    label: 'Tarde',
                    color: Colors.blueGrey.shade600,
                  ),
                if (usuario.disponibilidadNoche)
                  ChipDisponibilidadWidget(
                    icon: Icons.nights_stay_rounded,
                    label: 'Noche',
                    color: Colors.indigo.shade700,
                  ),
                if (!usuario.disponibilidadManana &&
                    !usuario.disponibilidadTarde &&
                    !usuario.disponibilidadNoche)
                  Text(
                    'Sin horarios indicados',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Editar disponibilidad — próximamente.')),
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
                'Editar disponibilidad',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
