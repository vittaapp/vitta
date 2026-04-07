import 'package:flutter/foundation.dart';

/// Vista de una nota del cuidador en `historial_clinico` pendiente de validación médica.
@immutable
class NotaCuidadorPendiente {
  const NotaCuidadorPendiente({
    required this.id,
    required this.texto,
    required this.fecha,
    required this.profesionalId,
  });

  final String id;
  final String texto;
  final DateTime fecha;
  final String profesionalId;
}
