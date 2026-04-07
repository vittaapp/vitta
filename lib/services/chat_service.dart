import 'package:cloud_firestore/cloud_firestore.dart';

/// Operaciones sobre `chats/{turnoId}/mensajes`.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccionChats = 'chats';
  static const String subcoleccionMensajes = 'mensajes';

  Future<void> enviarMensaje({
    required String turnoId,
    required String texto,
    required String remitenteId,
    required String nombreRemitente,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) return;

    await _db
        .collection(coleccionChats)
        .doc(turnoId)
        .collection(subcoleccionMensajes)
        .add({
      'texto': t,
      'remitenteId': remitenteId,
      'nombreRemitente': nombreRemitente,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerMensajes(
    String turnoId,
  ) {
    return _db
        .collection(coleccionChats)
        .doc(turnoId)
        .collection(subcoleccionMensajes)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

