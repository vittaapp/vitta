import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nota_cuidador_pendiente.dart';
import '../models/usuario_model.dart' show RolesVitta, Usuario;
import '../services/historial_service.dart';

/// Sesión Firebase Auth.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Perfil en `usuarios/{uid}` con campo `rol` (p. ej. familiar, profesional, enfermero_n3, medico).
/// [Usuario.tienePacienteRegistrado] se calcula en memoria (no está en Firestore).
final usuarioActualProvider = StreamProvider<Usuario?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) {
      return Stream<Usuario?>.value(null);
    }
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .asyncMap((s) async {
      if (!s.exists) return null;
      final u = Usuario.fromMap(s.data()!, s.id);
      final tiene = await FirebaseFirestore.instance
          .collection('pacientes')
          .where('familiarId', isEqualTo: user.uid)
          .limit(1)
          .get();
      return u.copyWith(tienePacienteRegistrado: tiene.docs.isNotEmpty);
    });
  });
});

/// Pestaña «Evolución Médica»: editable solo para roles clínicos (alineado a `firestore.rules`).
final puedeEditarEvolucionMedicaProvider = Provider<bool>((ref) {
  final async = ref.watch(usuarioActualProvider);
  return async.when(
    data: (u) =>
        u != null &&
        (u.rol == RolesVitta.enfermeroN3 || u.rol == RolesVitta.medico),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// «Notas familiares» (secc. 21): carga típica del familiar.
final puedeEditarNotasFamiliaresProvider = Provider<bool>((ref) {
  final async = ref.watch(usuarioActualProvider);
  return async.when(
    data: (u) => u?.rol == RolesVitta.familiar,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// UID del usuario autenticado (útil para `profesionalId` al crear historial).
final uidActualProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (u) => u?.uid,
        orElse: () => null,
      );
});

final esMedicoProvider = Provider<bool>((ref) {
  final async = ref.watch(usuarioActualProvider);
  return async.when(
    data: (u) => u?.rol == RolesVitta.medico,
    loading: () => false,
    error: (_, __) => false,
  );
});

final esEnfermeroN3Provider = Provider<bool>((ref) {
  final async = ref.watch(usuarioActualProvider);
  return async.when(
    data: (u) => u?.rol == RolesVitta.enfermeroN3,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Notas del cuidador (`esNotaCuidador`) sin registro de validación médica asociado.
final notasCuidadorPendientesProvider =
    StreamProvider.family<List<NotaCuidadorPendiente>, String>((ref, pacienteId) {
  return FirebaseFirestore.instance
      .collection(HistorialService.coleccionHistorial)
      .where('pacienteId', isEqualTo: pacienteId)
      .snapshots()
      .map((snap) {
    final validados = <String>{};
    for (final d in snap.docs) {
      final v = d.data()['validaRegistroId'] as String?;
      if (v != null && v.isNotEmpty) {
        validados.add(v);
      }
    }
    final lista = <NotaCuidadorPendiente>[];
    for (final d in snap.docs) {
      final m = d.data();
      if (m['esNotaCuidador'] != true) continue;
      if (validados.contains(d.id)) continue;
      final fecha = DateTime.tryParse(m['fecha'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      lista.add(
        NotaCuidadorPendiente(
          id: d.id,
          texto: m['descripcion'] as String? ?? '',
          fecha: fecha,
          profesionalId: m['profesionalId'] as String? ?? '',
        ),
      );
    }
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  });
});
