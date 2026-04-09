import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/domain/chat_message_domain.dart';
import 'package:vitta_app/models/entities/chat_message_entity.dart';
import 'package:vitta_app/models/ui/chat_message_ui.dart';

void main() {
  group('ChatMessageEntity', () {
    test('fromDoc crea entidad correctamente', () {
      final entity = ChatMessageEntity.fromDoc('msg-1', {
        'turnoId': 'turno-1',
        'remitenteId': 'uid-abc',
        'nombreRemitente': 'Juan',
        'texto': 'Hola',
        'leido': false,
      });

      expect(entity.id, 'msg-1');
      expect(entity.turnoId, 'turno-1');
      expect(entity.remitenteId, 'uid-abc');
      expect(entity.nombreRemitente, 'Juan');
      expect(entity.texto, 'Hola');
      expect(entity.leido, false);
    });

    test('fromDoc usa defaults cuando faltan campos', () {
      final entity = ChatMessageEntity.fromDoc('x', {});
      expect(entity.turnoId, '');
      expect(entity.remitenteId, '');
      expect(entity.nombreRemitente, 'Anónimo');
      expect(entity.texto, '');
      expect(entity.leido, false);
    });

    test('toMap incluye todos los campos requeridos', () {
      final entity = ChatMessageEntity(
        id: 'e1',
        turnoId: 't1',
        remitenteId: 'r1',
        nombreRemitente: 'Ana',
        texto: 'Test',
        timestamp: DateTime(2026, 4, 9, 14, 30),
      );

      final map = entity.toMap();
      expect(map['turnoId'], 't1');
      expect(map['remitenteId'], 'r1');
      expect(map['nombreRemitente'], 'Ana');
      expect(map['texto'], 'Test');
      expect(map['leido'], false);
    });

    test('copyWith actualiza solo el campo indicado', () {
      final original = ChatMessageEntity(
        id: 'e1',
        turnoId: 't1',
        remitenteId: 'r1',
        nombreRemitente: 'Ana',
        texto: 'Texto original',
        timestamp: DateTime(2026),
      );

      final copia = original.copyWith(texto: 'Texto nuevo');
      expect(copia.texto, 'Texto nuevo');
      expect(copia.id, original.id);
      expect(copia.remitenteId, original.remitenteId);
    });

    test('toString contiene id y turnoId', () {
      final entity = ChatMessageEntity(
        id: 'e1',
        turnoId: 't1',
        remitenteId: 'r1',
        nombreRemitente: 'X',
        texto: 'Y',
        timestamp: DateTime(2026),
      );
      expect(entity.toString(), contains('e1'));
      expect(entity.toString(), contains('t1'));
    });
  });

  group('ChatMessageDomain', () {
    ChatMessageDomain _make({
      DateTime? timestamp,
      String texto = 'Hola',
    }) {
      return ChatMessageDomain(
        id: 'd1',
        turnoId: 't1',
        remitenteId: 'r1',
        nombreRemitente: 'Luis',
        texto: texto,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    test('esReciente devuelve true para mensaje de ahora', () {
      expect(_make().esReciente(), isTrue);
    });

    test('esReciente devuelve false para mensaje de ayer', () {
      final ayer = DateTime.now().subtract(const Duration(hours: 25));
      expect(_make(timestamp: ayer).esReciente(), isFalse);
    });

    test('esValido devuelve true para texto normal', () {
      expect(_make(texto: 'Mensaje válido').esValido(), isTrue);
    });

    test('esValido devuelve false para texto vacío', () {
      expect(_make(texto: '   ').esValido(), isFalse);
    });

    test('esValido devuelve false para texto mayor a 1000 caracteres', () {
      expect(_make(texto: 'x' * 1001).esValido(), isFalse);
    });

    test('horaFormato devuelve HH:MM', () {
      final ts = DateTime(2026, 1, 1, 9, 5);
      expect(_make(timestamp: ts).horaFormato, '09:05');
    });

    test('fechaFormato devuelve D/M/YYYY', () {
      final ts = DateTime(2026, 4, 9);
      expect(_make(timestamp: ts).fechaFormato, '9/4/2026');
    });

    test('copyWith mantiene campos no modificados', () {
      final original = _make();
      final copia = original.copyWith(texto: 'Nuevo texto');
      expect(copia.id, original.id);
      expect(copia.texto, 'Nuevo texto');
    });
  });

  group('ChatMessageUI', () {
    ChatMessageDomain _makeDomain(String remitenteId) {
      return ChatMessageDomain(
        id: 'u1',
        turnoId: 't1',
        remitenteId: remitenteId,
        nombreRemitente: 'Carlos',
        texto: 'Mensaje',
        timestamp: DateTime(2026, 4, 9, 12, 0),
      );
    }

    test('esMio es true cuando el id coincide', () {
      final ui = ChatMessageUI.from(_makeDomain('user-1'), 'user-1');
      expect(ui.esMio, isTrue);
    });

    test('esMio es false cuando el id no coincide', () {
      final ui = ChatMessageUI.from(_makeDomain('user-2'), 'user-1');
      expect(ui.esMio, isFalse);
    });

    test('horaFormato se copia correctamente del domain', () {
      final ui = ChatMessageUI.from(_makeDomain('x'), 'x');
      expect(ui.horaFormato, '12:00');
    });

    test('colorBurbuja difiere según esMio', () {
      final mio = ChatMessageUI.from(_makeDomain('yo'), 'yo');
      final otro = ChatMessageUI.from(_makeDomain('otro'), 'yo');
      expect(mio.colorBurbuja, isNot(equals(otro.colorBurbuja)));
    });

    test('colorTexto es blanco para mensajes propios', () {
      const blanco = Color(0xFFFFFFFF);
      final ui = ChatMessageUI.from(_makeDomain('yo'), 'yo');
      expect(ui.colorTexto, equals(blanco));
    });
  });
}
