import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Mensaje de chat — entidad persistente en Firestore.
/// Colección: `chats/{turnoId}/mensajes/{messageId}`
@immutable
class ChatMessageEntity {
  const ChatMessageEntity({
    required this.id,
    required this.turnoId,
    required this.remitenteId,
    required this.nombreRemitente,
    required this.texto,
    required this.timestamp,
    this.leido = false,
  });

  final String id;
  final String turnoId;
  final String remitenteId;
  final String nombreRemitente;
  final String texto;
  final DateTime timestamp;
  final bool leido;

  factory ChatMessageEntity.fromDoc(String id, Map<String, dynamic> data) {
    return ChatMessageEntity(
      id: id,
      turnoId: data['turnoId'] as String? ?? '',
      remitenteId: data['remitenteId'] as String? ?? '',
      nombreRemitente: data['nombreRemitente'] as String? ?? 'Anónimo',
      texto: data['texto'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      leido: data['leido'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'turnoId': turnoId,
      'remitenteId': remitenteId,
      'nombreRemitente': nombreRemitente,
      'texto': texto,
      'timestamp': timestamp,
      'leido': leido,
    };
  }

  ChatMessageEntity copyWith({
    String? id,
    String? turnoId,
    String? remitenteId,
    String? nombreRemitente,
    String? texto,
    DateTime? timestamp,
    bool? leido,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      turnoId: turnoId ?? this.turnoId,
      remitenteId: remitenteId ?? this.remitenteId,
      nombreRemitente: nombreRemitente ?? this.nombreRemitente,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      leido: leido ?? this.leido,
    );
  }

  @override
  String toString() => 'ChatMessageEntity(id: $id, turnoId: $turnoId)';
}
