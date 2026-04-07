import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/registro_historial_clinico.dart';
import '../models/signos_vitales.dart';
import '../providers/bitacora_provider.dart';

const Color _kAzulVitta = Color(0xFF1A3E6F);

/// Historial clínico completo del paciente (tiempo real).
class HistorialCompletoView extends ConsumerWidget {
  const HistorialCompletoView({
    super.key,
    required this.pacienteId,
  });

  final String pacienteId;

  static String _fmtFechaCompleta(DateTime d) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }

  static String _fmtHora(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _tipoEtiqueta(TipoRegistroHistorial t) {
    switch (t) {
      case TipoRegistroHistorial.turno:
        return 'Signos vitales / turno';
      case TipoRegistroHistorial.observacion:
        return 'Observación';
      case TipoRegistroHistorial.medicacion:
        return 'Medicación';
      case TipoRegistroHistorial.emergencia:
        return 'Emergencia';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historialClinicoCompletoProvider(pacienteId));

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        backgroundColor: _kAzulVitta,
        foregroundColor: Colors.white,
        title: const Text(
          'Historial clínico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kAzulVitta),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  'No se pudo cargar el historial. Probá de nuevo más tarde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sin registros aún — los registros del cuidador aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = lista[i];
              return _FilaHistorialCompleto(
                registro: r,
                fechaTxt: _fmtFechaCompleta(r.fecha),
                horaTxt: _fmtHora(r.fecha),
                tipoTxt: _tipoEtiqueta(r.tipoRegistro),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilaHistorialCompleto extends StatelessWidget {
  const _FilaHistorialCompleto({
    required this.registro,
    required this.fechaTxt,
    required this.horaTxt,
    required this.tipoTxt,
  });

  final RegistroHistorialClinico registro;
  final String fechaTxt;
  final String horaTxt;
  final String tipoTxt;

  static Widget? _bloqueSignos(SignosVitales? sv) {
    if (sv == null || !sv.tieneAlguno) return null;
    final lineas = <String>[];
    if (sv.tensionArterial != null) lineas.add('Presión: ${sv.tensionArterial}');
    if (sv.temperaturaCelsius != null) {
      lineas.add('Temperatura: ${sv.temperaturaCelsius} °C');
    }
    if (sv.frecuenciaCardiacaLpm != null) {
      lineas.add('Frecuencia cardíaca: ${sv.frecuenciaCardiacaLpm} lpm');
    }
    if (sv.saturacionOxigenoPct != null) {
      lineas.add('Saturación O₂: ${sv.saturacionOxigenoPct} %');
    }
    if (sv.frecuenciaRespiratoriaLpm != null) {
      lineas.add('Frecuencia respiratoria: ${sv.frecuenciaRespiratoriaLpm} rpm');
    }
    if (sv.glucemiaMgDl != null) lineas.add('Glucemia: ${sv.glucemiaMgDl} mg/dL');
    if (lineas.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Signos vitales',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        ...lineas.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(l, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade900)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreProf =
        registro.nombreProfesional?.trim().isNotEmpty == true
            ? registro.nombreProfesional!.trim()
            : 'Profesional';
    final desc = registro.descripcion?.trim();
    final descripcionMostrar =
        desc != null && desc.isNotEmpty ? desc : '—';
    final bloqueSv = _bloqueSignos(registro.signosVitales);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fechaTxt,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kAzulVitta,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                horaTxt,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tipoTxt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcionMostrar,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.badge_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Registrado por: $nombreProf',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          if (bloqueSv != null) bloqueSv,
        ],
      ),
    );
  }
}
