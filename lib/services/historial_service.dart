import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/registro_historial_clinico.dart';
import '../models/usuario_model.dart';
import '../models/signos_vitales.dart';

/// Servicio de historia clínica en Firestore.
///
/// Colección alineada a [firestore.rules]: `historial_clinico/{registroId}` — solo **create**,
/// sin actualización ni borrado (inmutabilidad).
class HistorialService {
  HistorialService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccionHistorial = 'historial_clinico';

  /// Datos del firmante en el documento (trazabilidad legal; historial auto-conclusivo).
  static Map<String, dynamic> _metadatosFirmante({
    required String nombreProfesional,
    String? matriculaProfesional,
  }) {
    final m = <String, dynamic>{
      'nombreProfesional': nombreProfesional,
    };
    final mat = matriculaProfesional?.trim();
    if (mat != null && mat.isNotEmpty) {
      m['matriculaProfesional'] = mat;
    }
    return m;
  }

  /// Crea un registro **nuevo** con signos vitales. No usa `update` ni `set` con merge sobre docs existentes.
  ///
  /// [pacienteId] se guarda en el documento para consultas; el modelo [RegistroHistorialClinico]
  /// sigue el esquema de la secc. 11 de `vitta_rules.md`.
  Future<String> crearRegistroConSignosVitales({
    required String pacienteId,
    required String profesionalId,
    required String turnoId,
    required SignosVitales signosVitales,
    required String nombreProfesional,
    String? matriculaProfesional,
    TipoRegistroHistorial tipoRegistro = TipoRegistroHistorial.turno,
    String? descripcion,
    String? estadoAnimo,
    bool requiereSeguimiento = false,
  }) async {
    if (!signosVitales.tieneAlguno) {
      throw ArgumentError(
        'Debe indicarse al menos un signo vital para registrar en historial.',
      );
    }

    final docRef = _db.collection(coleccionHistorial).doc();
    final ahora = DateTime.now();

    final registro = RegistroHistorialClinico(
      id: docRef.id,
      profesionalId: profesionalId,
      turnoId: turnoId,
      fecha: ahora,
      tipoRegistro: tipoRegistro,
      descripcion: descripcion,
      estadoAnimo: estadoAnimo,
      signosVitales: signosVitales,
      requiereSeguimiento: requiereSeguimiento,
    );

    await docRef.set({
      ...registro.toMap(),
      'pacienteId': pacienteId,
      ..._metadatosFirmante(
        nombreProfesional: nombreProfesional,
        matriculaProfesional: matriculaProfesional,
      ),
    });

    return docRef.id;
  }

  /// Nota redactada por el cuidador (N3), pendiente de validación médica — documento **nuevo**, inmutable.
  Future<String> crearNotaCuidador({
    required String pacienteId,
    required String profesionalId,
    required String turnoId,
    required String texto,
    required String nombreProfesional,
    String? matriculaProfesional,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) {
      throw ArgumentError('La nota del cuidador no puede estar vacía.');
    }

    final docRef = _db.collection(coleccionHistorial).doc();
    final ahora = DateTime.now();

    final registro = RegistroHistorialClinico(
      id: docRef.id,
      profesionalId: profesionalId,
      turnoId: turnoId,
      fecha: ahora,
      tipoRegistro: TipoRegistroHistorial.observacion,
      descripcion: t,
      signosVitales: null,
    );

    await docRef.set({
      ...registro.toMap(),
      'pacienteId': pacienteId,
      'esNotaCuidador': true,
      ..._metadatosFirmante(
        nombreProfesional: nombreProfesional,
        matriculaProfesional: matriculaProfesional,
      ),
    });

    return docRef.id;
  }

  /// El médico **no modifica** la nota original: crea un registro clínico oficial nuevo que referencia [registroOrigenId].
  Future<String> validarNotaComoRegistroOficial({
    required String rolUsuario,
    required String pacienteId,
    required String medicoId,
    required String turnoId,
    required String registroOrigenId,
    required String textoOficial,
    required String nombreProfesional,
    String? matriculaProfesional,
  }) async {
    if (rolUsuario != RolesVitta.medico) {
      throw StateError(
        'Solo un médico puede validar registros clínicos oficiales.',
      );
    }

    final t = textoOficial.trim();
    if (t.isEmpty) {
      throw ArgumentError('El texto del registro oficial no puede estar vacío.');
    }

    final origenRef =
        _db.collection(coleccionHistorial).doc(registroOrigenId);
    final origenSnap = await origenRef.get();
    if (!origenSnap.exists) {
      throw StateError('No existe la nota de origen.');
    }
    final om = origenSnap.data()!;
    if (om['pacienteId'] != pacienteId) {
      throw StateError('La nota no corresponde a este paciente.');
    }
    if (om['esNotaCuidador'] != true) {
      throw StateError('Solo se pueden validar notas marcadas como del cuidador.');
    }

    SignosVitales? sv;
    if (om['signosVitales'] != null) {
      sv = SignosVitales.fromMap(
        Map<String, dynamic>.from(om['signosVitales'] as Map),
      );
    }

    final docRef = _db.collection(coleccionHistorial).doc();
    final ahora = DateTime.now();

    final registro = RegistroHistorialClinico(
      id: docRef.id,
      profesionalId: medicoId,
      turnoId: turnoId,
      fecha: ahora,
      tipoRegistro: TipoRegistroHistorial.observacion,
      descripcion: t,
      signosVitales: sv != null && sv.tieneAlguno ? sv : null,
    );

    await docRef.set({
      ...registro.toMap(),
      'pacienteId': pacienteId,
      'validaRegistroId': registroOrigenId,
      'esRegistroOficialValidacionMedica': true,
      ..._metadatosFirmante(
        nombreProfesional: nombreProfesional,
        matriculaProfesional: matriculaProfesional,
      ),
    });

    return docRef.id;
  }
}
