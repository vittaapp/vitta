import 'package:flutter/material.dart';
import '../domain/chat_message_domain.dart';

/// View-model de ChatMessage para presentación en UI.
class ChatMessageUI {
  ChatMessageUI({
    required this.id,
    required this.remitenteId,
    required this.nombreRemitente,
    required this.texto,
    required this.horaFormato,
    required this.fechaFormato,
    required this.esMio,
    required this.leido,
  });

  final String id;
  final String remitenteId;
  final String nombreRemitente;
  final String texto;
  final String horaFormato;
  final String fechaFormato;
  final bool esMio;
  final bool leido;

  factory ChatMessageUI.from(
    ChatMessageDomain domain,
    String usuarioActualId,
  ) {
    return ChatMessageUI(
      id: domain.id,
      remitenteId: domain.remitenteId,
      nombreRemitente: domain.nombreRemitente,
      texto: domain.texto,
      horaFormato: domain.horaFormato,
      fechaFormato: domain.fechaFormato,
      esMio: domain.remitenteId == usuarioActualId,
      leido: domain.leido,
    );
  }

  Color get colorBurbuja =>
      esMio ? const Color(0xFF1A3E6F) : Colors.grey.shade200;

  Color get colorTexto => esMio ? Colors.white : Colors.black87;

  CrossAxisAlignment get alineacion =>
      esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start;

  @override
  String toString() => 'ChatMessageUI(id: $id, esMio: $esMio)';
}
