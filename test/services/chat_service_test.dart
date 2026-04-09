import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/entities/chat_message_entity.dart';

/// Tests unitarios de ChatService.
/// ChatService depende de Firebase en tiempo de construcción, por lo que estos
/// tests validan la lógica de datos (entidades) sin inicializar Firebase.
void main() {
  group('ChatService — contratos de datos y entidades', () {
    test('ChatMessageEntity se puede crear y serializar', () {
      final entity = ChatMessageEntity(
        id: 's1',
        turnoId: 'turno-abc',
        remitenteId: 'uid-xyz',
        nombreRemitente: 'Test User',
        texto: 'Mensaje de prueba',
        timestamp: DateTime(2026, 4, 9, 14, 0),
      );

      final map = entity.toMap();
      expect(map['turnoId'], 'turno-abc');
      expect(map['remitenteId'], 'uid-xyz');
      expect(map['texto'], 'Mensaje de prueba');
      expect(map['leido'], false);
    });

    test('ChatMessageEntity.fromDoc maneja campos null', () {
      final entity = ChatMessageEntity.fromDoc('x', {});
      expect(entity.turnoId, '');
      expect(entity.nombreRemitente, 'Anónimo');
      expect(entity.leido, false);
    });

    test('ChatMessageEntity.fromDoc lee texto correctamente', () {
      final entity = ChatMessageEntity.fromDoc('m1', {
        'turnoId': 'T1',
        'remitenteId': 'R1',
        'nombreRemitente': 'Carlos',
        'texto': 'Hola equipo',
        'leido': true,
      });
      expect(entity.texto, 'Hola equipo');
      expect(entity.nombreRemitente, 'Carlos');
      expect(entity.leido, true);
    });

    test('toMap → fromDoc es reversible', () {
      final original = ChatMessageEntity(
        id: 'round-trip',
        turnoId: 'T',
        remitenteId: 'R',
        nombreRemitente: 'X',
        texto: 'Round trip',
        timestamp: DateTime(2026, 1, 1),
        leido: true,
      );

      final map = original.toMap();
      final map2 = {'turnoId': map['turnoId'], 'remitenteId': map['remitenteId'], 'nombreRemitente': map['nombreRemitente'], 'texto': map['texto'], 'leido': map['leido']};
      final restored = ChatMessageEntity.fromDoc('round-trip', map2);

      expect(restored.texto, original.texto);
      expect(restored.remitenteId, original.remitenteId);
      expect(restored.nombreRemitente, original.nombreRemitente);
      expect(restored.leido, original.leido);
    });

    test('texto vacío en entidad se detecta', () {
      final entity = ChatMessageEntity.fromDoc('empty', {'texto': '   '});
      expect(entity.texto.trim().isEmpty, isTrue);
    });

    test('copyWith no muta el objeto original', () {
      final a = ChatMessageEntity(
        id: 'a',
        turnoId: 't',
        remitenteId: 'r',
        nombreRemitente: 'N',
        texto: 'Original',
        timestamp: DateTime(2026),
      );
      final b = a.copyWith(texto: 'Modificado');
      expect(a.texto, 'Original');
      expect(b.texto, 'Modificado');
    });

    test('leido por defecto es false', () {
      final entity = ChatMessageEntity(
        id: 'e',
        turnoId: 't',
        remitenteId: 'r',
        nombreRemitente: 'N',
        texto: 'T',
        timestamp: DateTime(2026),
      );
      expect(entity.leido, false);
    });

    test('toString incluye id', () {
      final entity = ChatMessageEntity(
        id: 'my-id',
        turnoId: 't',
        remitenteId: 'r',
        nombreRemitente: 'N',
        texto: 'T',
        timestamp: DateTime(2026),
      );
      expect(entity.toString(), contains('my-id'));
    });
  });
}
