import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/turno_activo_parametros.dart';
import '../../services/turno_service.dart';
import '../../views/turno_activo_view.dart';

const Color _azulVitta = Color(0xFF0066CC);
const Color _verdeVerificado = Color(0xFF2E7D32);

/// Widget que muestra una tarjeta individual de turno para el profesional.
/// Permite aceptar turnos pendientes o iniciar turnos aceptados.
class TurnoCardWidget extends StatelessWidget {
  const TurnoCardWidget({
    Key? key,
    required this.doc,
    required this.uid,
    required this.minButtonHeight,
  }) : super(key: key);

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  final double minButtonHeight;

  static String _formatFecha(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  static String _tipoServicioLabel(String? tipo) {
    switch (tipo) {
      case 'hospitalario':
        return 'Hospitalario';
      case 'domicilio':
      default:
        return 'Domicilio';
    }
  }

  static Color _nivelColor(int nivel) {
    switch (nivel) {
      case 1:
        return const Color(0xFF5DCAA5);
      case 2:
        return const Color(0xFFF57F17);
      case 3:
        return const Color(0xFF534AB7);
      default:
        return const Color(0xFF5DCAA5);
    }
  }

  static String _nivelLabel(int nivel) {
    return 'N$nivel';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final estado = data['estado'] as String? ?? '';
    final profesionalId = data['profesionalId'] as String? ?? '';
    final nombrePaciente = data['nombrePaciente'] as String? ?? 'Paciente';
    final direccion = data['direccion'] as String? ?? '—';
    final tipoServicio = data['tipoServicio'] as String? ?? 'domicilio';
    final nivelRequerido = (data['nivelRequerido'] as num?)?.toInt() ?? 0;
    final fechaSolicitada = data['fechaSolicitada'];

    final sinAsignar = profesionalId.isEmpty;
    final puedeAceptar = estado == 'pendiente' && sinAsignar;
    final puedeIniciar = estado == 'aceptado' && profesionalId == uid;

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
            _filaTurno(Icons.person_outline_rounded, 'Paciente', nombrePaciente),
            const SizedBox(height: 10),
            _filaTurno(Icons.location_on_outlined, 'Dirección', direccion),
            const SizedBox(height: 10),
            _filaTurno(Icons.schedule_rounded, 'Fecha solicitada', _formatFecha(fechaSolicitada)),
            const SizedBox(height: 10),
            _filaTurno(Icons.medical_services_outlined, 'Tipo', _tipoServicioLabel(tipoServicio)),
            const SizedBox(height: 10),
            _filaConChip(
              'Nivel requerido',
              _nivelLabel(nivelRequerido),
              _nivelColor(nivelRequerido),
            ),
            const SizedBox(height: 10),
            _filaTurno(Icons.flag_outlined, 'Estado', estado),
            const SizedBox(height: 16),
            if (puedeAceptar)
              _botonAceptar(context)
            else if (puedeIniciar)
              _botonIniciarTurno(context, data),
          ],
        ),
      ),
    );
  }

  /// Fila estándar: ícono + etiqueta + valor
  static Widget _filaTurno(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: _azulVitta),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fila con chip de color: para nivel
  Widget _filaConChip(String label, String chipLabel, Color chipColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_outlined, size: 22, color: _azulVitta),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Chip(
                backgroundColor: chipColor,
                label: Text(
                  chipLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botón para aceptar turno
  Widget _botonAceptar(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        try {
          await TurnoService().aceptarTurno(
            turnoId: doc.id,
            profesionalUid: uid,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turno aceptado.'),
              backgroundColor: _verdeVerificado,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo aceptar: $e')),
          );
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Aceptar',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  /// Botón para iniciar turno
  Widget _botonIniciarTurno(BuildContext context, Map<String, dynamic> data) {
    return FilledButton(
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TurnoActivoView(
              parametros: TurnoActivoParametros(
                turnoId: doc.id,
                pacienteId: data['pacienteId'] as String? ?? '',
                nombrePaciente: data['nombrePaciente'] as String? ?? 'Paciente',
                edad: '—',
                diagnosticoPrincipal: '—',
                alergiasImportantes: '—',
                direccionDomicilio: data['direccion'] as String? ?? '—',
              ),
            ),
          ),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: _azulVitta,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Iniciar turno',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
