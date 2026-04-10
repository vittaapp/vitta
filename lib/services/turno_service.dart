import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario_model.dart' show RolesVitta;

/// Resultado de [TurnoService.validarCodigoCheckin].
enum CodigoCheckinResult {
  ok,
  incorrecto,
  yaUsado,
  vencido,
  turnoNoEncontrado,
  profesionalNoCoincide,
  error,
}

/// Operaciones sobre `turnos/{turnoId}` (solicitudes, aceptación, check-in / check-out).
class TurnoService {
  TurnoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccionTurnos = 'turnos';
  static const String coleccionNotificacionesPendientes = 'notificaciones_pendientes';

  Future<void> _guardarNotificacionPendiente({
    required String destinatarioId,
    required String token,
    required String titulo,
    required String cuerpo,
    required String tipo,
    String? turnoId,
  }) async {
    await _db.collection(coleccionNotificacionesPendientes).doc().set({
      'destinatarioId': destinatarioId,
      'token': token,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'tipo': tipo,
      if (turnoId != null && turnoId.isNotEmpty) 'turnoId': turnoId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mapea `usuarios.rol` → nivel 1..3 (coincide con `pacientes.nivelCuidado`).
  static int nivelProfesionalDesdeRol(String? rol) {
    switch (rol) {
      case RolesVitta.profesional:
        return 1;
      case RolesVitta.medico:
        return 2;
      case RolesVitta.enfermeroN3:
        return 3;
      default:
        return 0;
    }
  }

  /// Solicitud del familiar: `profesionalId` vacío hasta que un profesional acepte.
  Future<String> solicitarTurno({
    required String familiarId,
    required String pacienteId,
    required int nivelRequerido,
    required String tipoServicio,
    required DateTime fechaSolicitada,
    required String direccion,
    String notasAdicionales = '',
    String nombrePaciente = '',
    GeoPoint? domicilioGps,
  }) async {
    final rnd = Random();
    final codigoVerificacion = (100000 + rnd.nextInt(900000)).toString();
    final codigoVenceAt = fechaSolicitada.add(const Duration(hours: 3));

    final doc = await _db.collection(coleccionTurnos).add({
      'familiarId': familiarId,
      'pacienteId': pacienteId,
      'profesionalId': '',
      'nivelRequerido': nivelRequerido,
      'tipoServicio': tipoServicio,
      'fechaSolicitada': Timestamp.fromDate(fechaSolicitada),
      'estado': 'pendiente',
      'direccion': direccion,
      'monto': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'codigoVerificacion': codigoVerificacion,
      'codigoUsado': false,
      'codigoVenceAt': Timestamp.fromDate(codigoVenceAt),
      if (notasAdicionales.trim().isNotEmpty)
        'notasAdicionales': notasAdicionales.trim(),
      if (nombrePaciente.trim().isNotEmpty) 'nombrePaciente': nombrePaciente.trim(),
      if (domicilioGps != null) 'domicilioGps': domicilioGps,
    });
    return doc.id;
  }

  /// Valida el código de check-in (Uber-style): correcto, no usado, no vencido,
  /// y [profesionalUid] coincide con [profesionalId] del turno. Si es válido,
  /// marca [codigoUsado] en `true` en una transacción.
  Future<CodigoCheckinResult> validarCodigoCheckin({
    required String turnoId,
    required String codigo,
    required String profesionalUid,
  }) async {
    try {
      late CodigoCheckinResult resultado;
      await _db.runTransaction((transaction) async {
        final ref = _db.collection(coleccionTurnos).doc(turnoId);
        final snap = await transaction.get(ref);
        if (!snap.exists) {
          resultado = CodigoCheckinResult.turnoNoEncontrado;
          return;
        }
        final data = snap.data()!;
        final profId = (data['profesionalId'] as String?)?.trim() ?? '';
        if (profId != profesionalUid) {
          resultado = CodigoCheckinResult.profesionalNoCoincide;
          return;
        }
        final usado = data['codigoUsado'] as bool? ?? false;
        if (usado) {
          resultado = CodigoCheckinResult.yaUsado;
          return;
        }
        final venceRaw = data['codigoVenceAt'];
        DateTime? venceDt;
        if (venceRaw is Timestamp) {
          venceDt = venceRaw.toDate();
        }
        final ahora = DateTime.now();
        if (venceDt != null && !ahora.isBefore(venceDt)) {
          resultado = CodigoCheckinResult.vencido;
          return;
        }
        final esperado = (data['codigoVerificacion'] as String?)?.trim() ?? '';
        final ingresado = codigo.trim().replaceAll(RegExp(r'\s'), '');
        if (esperado.length != 6 || ingresado.length != 6 || esperado != ingresado) {
          resultado = CodigoCheckinResult.incorrecto;
          return;
        }
        transaction.update(ref, {'codigoUsado': true});
        resultado = CodigoCheckinResult.ok;
      });
      return resultado;
    } catch (_) {
      return CodigoCheckinResult.error;
    }
  }

  /// Turnos visibles para el profesional: asignados a él (pendiente/activo/aceptado)
  /// o sin asignar, pendientes, con su [nivelProfesional].
  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerTurnosProfesional({
    required String uid,
    required int nivelProfesional,
  }) {
    return _db
        .collection(coleccionTurnos)
        .where(
          Filter.or(
            Filter.and(
              Filter('profesionalId', isEqualTo: uid),
              Filter('estado', whereIn: ['pendiente', 'activo', 'aceptado']),
            ),
            Filter.and(
              Filter('estado', isEqualTo: 'pendiente'),
              Filter('profesionalId', isEqualTo: ''),
              Filter('nivelRequerido', isEqualTo: nivelProfesional),
            ),
          ),
        )
        .snapshots();
  }

  /// Turnos activos/pendientes/aceptados del familiar.
  /// Sin orderBy para evitar índice compuesto en Firestore.
  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerTurnosFamiliar(String familiarId) {
    return _db
        .collection(coleccionTurnos)
        .where('familiarId', isEqualTo: familiarId)
        .snapshots();
  }

  /// Acepta una solicitud pendiente sin profesional asignado.
  Future<void> aceptarTurno({
    required String turnoId,
    required String profesionalUid,
  }) async {
    // Guardamos el estado del turno primero para no bloquear el flujo principal.
    await _db.collection(coleccionTurnos).doc(turnoId).update({
      'profesionalId': profesionalUid,
      'estado': 'aceptado',
    });

    // Notificación pendiente al familiar (mejor esfuerzo, errores silenciosos).
    try {
      final turnoSnap = await _db.collection(coleccionTurnos).doc(turnoId).get();
      final turnoData = turnoSnap.data();
      final familiarId = (turnoData?['familiarId'] as String?)?.trim() ?? '';
      if (familiarId.isEmpty) return;

      final profesionalSnap =
          await _db.collection('usuarios').doc(profesionalUid).get();
      final nombreProfesional =
          (profesionalSnap.data()?['nombre'] as String?)?.trim() ?? '';
      final nombreProfesionalSafe = nombreProfesional.isNotEmpty ? nombreProfesional : 'Profesional';

      final familiarSnap = await _db.collection('usuarios').doc(familiarId).get();
      final token = (familiarSnap.data()?['fcmToken'] as String?)?.trim() ?? '';
      if (token.isEmpty) return;

      await _guardarNotificacionPendiente(
        destinatarioId: familiarId,
        token: token,
        titulo: 'Turno confirmado',
        cuerpo: 'Tu turno fue aceptado por $nombreProfesionalSafe',
        tipo: 'turno_aceptado',
        turnoId: turnoId,
      );
    } catch (_) {
      // Silencioso.
    }
  }

  /// Cancela una solicitud pendiente. Solo el familiar dueño del turno
  /// puede cancelar y únicamente si el turno está en estado `pendiente`.
  Future<void> cancelarTurno({
    required String turnoId,
    required String familiarUid,
  }) async {
    final docRef = _db.collection(coleccionTurnos).doc(turnoId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data();
      if (data == null) {
        throw StateError('Turno no encontrado.');
      }
      final estadoActual = data['estado'] as String? ?? '';
      final familiarId = data['familiarId'] as String? ?? '';
      if (estadoActual != 'pendiente') {
        throw StateError('Solo podés cancelar turnos pendientes.');
      }
      if (familiarId != familiarUid) {
        throw StateError('No tenés permiso para cancelar este turno.');
      }

      tx.update(docRef, {
        'estado': 'cancelado',
      });
    });
  }

  /// Registra llegada: [checkinTime] servidor y [estado] `activo`.
  Future<void> registrarCheckin({
    required String turnoId,
    required String profesionalId,
    required String pacienteId,
    String? direccion,
    GeoPoint? checkinGps,
  }) async {
    await _db.collection(coleccionTurnos).doc(turnoId).set(
      {
        'profesionalId': profesionalId,
        'pacienteId': pacienteId,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
        if (checkinGps != null) 'checkinGps': checkinGps,
        'checkinTime': FieldValue.serverTimestamp(),
        'estado': 'activo',
      },
      SetOptions(merge: true),
    );

    // Notificación pendiente al familiar (mejor esfuerzo, errores silenciosos).
    try {
      final turnoSnap = await _db.collection(coleccionTurnos).doc(turnoId).get();
      final turnoData = turnoSnap.data();
      final familiarId = (turnoData?['familiarId'] as String?)?.trim() ?? '';
      if (familiarId.isEmpty) return;

      final profesionalSnap = await _db.collection('usuarios').doc(profesionalId).get();
      final nombreProfesional =
          (profesionalSnap.data()?['nombre'] as String?)?.trim() ?? '';
      final nombreProfesionalSafe =
          nombreProfesional.isNotEmpty ? nombreProfesional : 'Cuidador';

      final familiarSnap = await _db.collection('usuarios').doc(familiarId).get();
      final token = (familiarSnap.data()?['fcmToken'] as String?)?.trim() ?? '';
      if (token.isEmpty) return;

      await _guardarNotificacionPendiente(
        destinatarioId: familiarId,
        token: token,
        titulo: 'El cuidador llegó',
        cuerpo: '$nombreProfesionalSafe registró su llegada',
        tipo: 'checkin',
        turnoId: turnoId,
      );
    } catch (_) {
      // Silencioso.
    }
  }

  /// Cierra el turno con [checkoutTime] y [estado] `completado`.
  Future<void> finalizarTurno({
    required String turnoId,
    required String profesionalId,
    required String pacienteId,
    GeoPoint? checkoutGps,
  }) async {
    await _db.collection(coleccionTurnos).doc(turnoId).set(
      {
        'profesionalId': profesionalId,
        'pacienteId': pacienteId,
        if (checkoutGps != null) 'checkoutGps': checkoutGps,
        'checkoutTime': FieldValue.serverTimestamp(),
        'estado': 'completado',
      },
      SetOptions(merge: true),
    );
  }
}
