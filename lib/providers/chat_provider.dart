import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/chat_message_domain.dart';
import '../models/entities/chat_message_entity.dart';
import '../services/chat_service.dart';

/// Instancia única de ChatService inyectable.
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Stream tipado de mensajes para un turno específico.
final chatStreamProvider =
    StreamProvider.family<List<ChatMessageDomain>, String>((ref, turnoId) {
  final service = ref.watch(chatServiceProvider);
  return service.obtenerMensajes(turnoId).map((entities) => entities
      .map((e) => ChatMessageDomain(
            id: e.id,
            turnoId: e.turnoId,
            remitenteId: e.remitenteId,
            nombreRemitente: e.nombreRemitente,
            texto: e.texto,
            timestamp: e.timestamp,
            leido: e.leido,
          ))
      .toList());
});

/// Último mensaje de un turno (para previews/notificaciones).
final ultimoMensajeProvider =
    FutureProvider.family<ChatMessageEntity?, String>((ref, turnoId) {
  final service = ref.watch(chatServiceProvider);
  return service.obtenerUltimoMensaje(turnoId);
});
