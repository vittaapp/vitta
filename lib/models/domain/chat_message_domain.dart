import 'package:flutter/foundation.dart';
import '../entities/chat_message_entity.dart';

/// Mensaje de chat con lógica de negocio.
/// Extiende ChatMessageEntity para heredar datos persistentes.
@immutable
class ChatMessageDomain extends ChatMessageEntity {
  const ChatMessageDomain({
    required super.id,
    required super.turnoId,
    required super.remitenteId,
    required super.nombreRemitente,
    required super.texto,
    required super.timestamp,
    super.leido,
  });

  /// Mensaje reciente si fue enviado hace menos de 1 hora.
  bool esReciente() {
    return DateTime.now().difference(timestamp).inHours < 1;
  }

  /// Texto no vacío y dentro del límite de 1000 caracteres.
  bool esValido() {
    return texto.trim().isNotEmpty && texto.length <= 1000;
  }

  String get horaFormato {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get fechaFormato {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  ChatMessageDomain copyWith({
    String? id,
    String? turnoId,
    String? remitenteId,
    String? nombreRemitente,
    String? texto,
    DateTime? timestamp,
    bool? leido,
  }) {
    return ChatMessageDomain(
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
  String toString() => 'ChatMessageDomain(id: $id, texto: $texto)';
}
