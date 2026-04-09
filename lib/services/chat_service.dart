import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/entities/chat_message_entity.dart';

/// Operaciones sobre `chats/{turnoId}/mensajes`.
class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String _colChats = 'chats';
  static const String _colMensajes = 'mensajes';

  /// Envía un mensaje. Obtiene el uid del usuario actual desde FirebaseAuth.
  Future<void> enviarMensaje({
    required String turnoId,
    required String texto,
    required String nombreRemitente,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    final t = texto.trim();
    if (t.isEmpty) throw Exception('Mensaje vacío');

    await _db
        .collection(_colChats)
        .doc(turnoId)
        .collection(_colMensajes)
        .add({
      'turnoId': turnoId,
      'remitenteId': uid,
      'nombreRemitente': nombreRemitente,
      'texto': t,
      'timestamp': FieldValue.serverTimestamp(),
      'leido': false,
    });
  }

  /// Stream tipado de mensajes ordenados por timestamp ascendente.
  Stream<List<ChatMessageEntity>> obtenerMensajes(String turnoId) {
    return _db
        .collection(_colChats)
        .doc(turnoId)
        .collection(_colMensajes)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessageEntity.fromDoc(d.id, d.data())).toList());
  }

  Future<void> marcarComoLeido(String turnoId, String mensajeId) async {
    await _db
        .collection(_colChats)
        .doc(turnoId)
        .collection(_colMensajes)
        .doc(mensajeId)
        .update({'leido': true});
  }

  Future<ChatMessageEntity?> obtenerUltimoMensaje(String turnoId) async {
    final snap = await _db
        .collection(_colChats)
        .doc(turnoId)
        .collection(_colMensajes)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return ChatMessageEntity.fromDoc(doc.id, doc.data());
  }

  /// Elimina todos los mensajes y el documento raíz del chat (solo admin).
  Future<void> eliminarChat(String turnoId) async {
    final snap = await _db
        .collection(_colChats)
        .doc(turnoId)
        .collection(_colMensajes)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    await _db.collection(_colChats).doc(turnoId).delete();
  }
}
