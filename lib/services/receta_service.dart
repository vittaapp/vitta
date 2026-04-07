import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario_model.dart';

/// Indicaciones / recetas digitales — colección `indicaciones_medicas` (`vitta_rules.md`).
///
/// Solo el rol [RolesVitta.medico] puede escribir (validación en cliente + Firestore rules).
class RecetaService {
  RecetaService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccionIndicaciones = 'indicaciones_medicas';

  /// Crea una indicación médica firmada digitalmente (timestamp servidor).
  Future<String> crearRecetaDigital({
    required String medicoId,
    required String rolUsuario,
    required String pacienteId,
    required String medicamento,
    required String dosis,
    required String frecuencia,
    required String viaAdministracion,
  }) async {
    if (rolUsuario != RolesVitta.medico) {
      throw StateError(
        'Solo un médico puede crear indicaciones médicas.',
      );
    }

    final med = medicamento.trim();
    if (med.isEmpty) {
      throw ArgumentError('El medicamento no puede estar vacío.');
    }

    final docRef = _db.collection(coleccionIndicaciones).doc();
    final ts = FieldValue.serverTimestamp();

    await docRef.set({
      'medicoId': medicoId,
      'pacienteId': pacienteId,
      'medicamento': med,
      'dosis': dosis.trim(),
      'frecuencia': frecuencia.trim(),
      'viaAdministracion': viaAdministracion.trim(),
      'fechaInicio': ts,
      'fechaFin': null,
      'activa': true,
      'firmadoDigitalmenteAt': ts,
    });

    return docRef.id;
  }
}
