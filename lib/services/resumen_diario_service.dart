import 'package:cloud_firestore/cloud_firestore.dart';

import 'historial_service.dart';

/// Genera y persiste resúmenes diarios para el familiar (`resumenes_diarios`).
class ResumenDiarioService {
  ResumenDiarioService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccionResumenes = 'resumenes_diarios';

  String _idDocumento(DateTime diaLocal, String pacienteId) {
    return '${diaLocal.year.toString().padLeft(4, '0')}'
        '${diaLocal.month.toString().padLeft(2, '0')}'
        '${diaLocal.day.toString().padLeft(2, '0')}_$pacienteId';
  }

  /// Id de documento `resumenes_diarios/{id}` para el día calendario actual.
  static String documentoIdHoy(String pacienteId) {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}_$pacienteId';
  }

  bool _esMismoDiaCalendario(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _timestampADate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  /// Consulta turnos completados hoy, historial del paciente hoy, arma texto y guarda
  /// en [resumenes_diarios/{yyyyMMdd}_{pacienteId}]. Errores: silenciosos.
  Future<void> generarResumenDelDia(String pacienteId, String familiarId) async {
    try {
      final ahora = DateTime.now();
      final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      final turnosSnap = await _db
          .collection('turnos')
          .where('familiarId', isEqualTo: familiarId)
          .get();

      Map<String, dynamic>? turnoHoy;
      for (final d in turnosSnap.docs) {
        final m = d.data();
        if ((m['estado'] as String?) != 'completado') continue;
        if ((m['pacienteId'] as String?) != pacienteId) continue;
        final co = m['checkoutTime'];
        final dt = _timestampADate(co);
        if (dt == null) continue;
        if (dt.isBefore(inicioDia) || !dt.isBefore(finDia)) continue;
        turnoHoy = {...m, '_id': d.id};
        break;
      }

      if (turnoHoy == null) return;

      final turnoId = turnoHoy['_id'] as String;
      final profId = (turnoHoy['profesionalId'] as String?)?.trim() ?? '';
      String nombreProfesional = 'Profesional';
      if (profId.isNotEmpty) {
        final u = await _db.collection('usuarios').doc(profId).get();
        final n = u.data()?['nombre'] as String?;
        if (n != null && n.trim().isNotEmpty) nombreProfesional = n.trim();
      }

      final ci = _timestampADate(turnoHoy['checkinTime']);
      final co = _timestampADate(turnoHoy['checkoutTime']);
      String fmtH(DateTime? d) {
        if (d == null) return '—';
        final h = d.hour.toString().padLeft(2, '0');
        final m = d.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }

      final histSnap = await _db
          .collection(HistorialService.coleccionHistorial)
          .where('pacienteId', isEqualTo: pacienteId)
          .get();

      var signosVitalesCount = 0;
      var notasTurnoCount = 0;
      for (final d in histSnap.docs) {
        final m = d.data();
        final fechaStr = m['fecha'] as String?;
        final fecha = DateTime.tryParse(fechaStr ?? '');
        if (fecha == null || !_esMismoDiaCalendario(fecha, ahora)) continue;

        final tid = m['turnoId'] as String? ?? '';
        if (tid != turnoId) continue;

        final sv = m['signosVitales'];
        if (sv is Map && sv.isNotEmpty) {
          final tiene = sv.values.any((v) => v != null && '$v'.trim().isNotEmpty);
          if (tiene) signosVitalesCount++;
        }
        final esNota = m['esNotaCuidador'] == true;
        final tipo = m['tipoRegistro'] as String? ?? '';
        if (esNota || tipo == 'observacion') {
          notasTurnoCount++;
        }
      }

      final textoResumen = [
        'Turno con $nombreProfesional.',
        'Check-in: ${fmtH(ci)} · Check-out: ${fmtH(co)}.',
        'Signos vitales registrados en el día: $signosVitalesCount.',
        'Notas / observaciones del turno: $notasTurnoCount.',
      ].join(' ');

      final docId = _idDocumento(ahora, pacienteId);
      await _db.collection(coleccionResumenes).doc(docId).set({
        'pacienteId': pacienteId,
        'familiarId': familiarId,
        'fecha': _idDocumento(ahora, pacienteId).split('_').first,
        'turnoId': turnoId,
        'nombreProfesional': nombreProfesional,
        'horaCheckin': fmtH(ci),
        'horaCheckOut': fmtH(co),
        'cantidadSignosVitales': signosVitalesCount,
        'cantidadNotasTurno': notasTurnoCount,
        'textoResumen': textoResumen,
        'tieneTurnoCompletadoHoy': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silencioso: no interrumpir el dashboard.
    }
  }
}
