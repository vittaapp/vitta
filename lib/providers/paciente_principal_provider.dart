import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paciente_firestore.dart';
import 'usuario_rol_provider.dart';

/// Primer paciente del familiar actual (`familiarId` == uid), o `null`.
final pacientePrincipalProvider =
    FutureProvider.autoDispose<PacienteFirestore?>((ref) async {
  ref.watch(authStateProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('pacientes')
      .where('familiarId', isEqualTo: uid)
      .limit(1)
      .get();

  if (snap.docs.isEmpty) return null;
  final doc = snap.docs.first;
  return PacienteFirestore.fromDoc(doc.id, doc.data());
});
