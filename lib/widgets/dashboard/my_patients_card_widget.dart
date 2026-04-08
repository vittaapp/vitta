import 'package:flutter/material.dart';
import '../../models/paciente_firestore.dart';
import '../../views/perfil_paciente_familiar_view.dart';
import '../../views/registro_paciente_view.dart';

// Color constante
const Color _kAzulVitta = Color(0xFF0066CC);

/// Widget que muestra el paciente registrado o botón para registrar uno.
///
/// Si no hay paciente, muestra un botón para registrar.
/// Si hay paciente, muestra su tarjeta con foto, datos y botón para editar.
///
/// Parámetros:
/// - `paciente`: Datos del paciente registrado (null si no hay)
/// - `onRegistrado`: Callback cuando se registra/edita un paciente
class MyPatientsCardWidget extends StatelessWidget {
  const MyPatientsCardWidget({
    Key? key,
    required this.paciente,
    required this.onRegistrado,
  }) : super(key: key);

  final PacienteFirestore? paciente;
  final VoidCallback onRegistrado;

  @override
  Widget build(BuildContext context) {
    if (paciente == null) {
      return OutlinedButton.icon(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (context) => const RegistroPacienteView(),
            ),
          );
          if (ok == true) onRegistrado();
        },
        icon: const Icon(Icons.person_add_rounded, color: _kAzulVitta),
        label: const Text(
          'Registrar mi familiar',
          style: TextStyle(
            color: _kAzulVitta,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kAzulVitta,
          side: const BorderSide(color: _kAzulVitta, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
    final p = paciente!;
    final nombre = p.nombre.trim().isNotEmpty ? p.nombre.trim() : 'Paciente';
    final subtitulo = [
      if (p.edad != null) '${p.edad} años',
      if (p.localidad != null && p.localidad!.trim().isNotEmpty) p.localidad!.trim(),
      if (p.provincia != null && p.provincia!.trim().isNotEmpty) p.provincia!.trim(),
    ].join(' · ');
    final fotoUrl = nombre.isNotEmpty
        ? 'https://i.pravatar.cc/200?u=${Uri.encodeComponent(nombre)}'
        : 'https://i.pravatar.cc/200?img=68';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _kAzulVitta.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fotoUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFFE3F2FD),
                alignment: Alignment.center,
                child: Icon(
                  Icons.elderly_rounded,
                  size: 40,
                  color: _kAzulVitta.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _kAzulVitta,
                  ),
                ),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
                if (p.diagnostico != null && p.diagnostico!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.diagnostico!.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const PerfilPacienteFamiliarView(),
                      ),
                    );
                    onRegistrado();
                  },
                  icon: const Icon(Icons.medical_information_outlined, size: 20),
                  label: const Text('Editar patologías y necesidades'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAzulVitta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
