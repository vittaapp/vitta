import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/providers/chat_provider.dart';

void main() {
  group('chat_provider — providers expuestos', () {
    test('chatServiceProvider es un provider válido', () {
      expect(chatServiceProvider, isNotNull);
    });

    test('chatStreamProvider es un StreamProvider.family', () {
      expect(chatStreamProvider, isNotNull);
    });

    test('ultimoMensajeProvider es un FutureProvider.family', () {
      expect(ultimoMensajeProvider, isNotNull);
    });

    test('chatStreamProvider distingue turnoIds distintos', () {
      final p1 = chatStreamProvider('turno-A');
      final p2 = chatStreamProvider('turno-B');
      expect(p1, isNot(equals(p2)));
    });

    test('ultimoMensajeProvider distingue turnoIds distintos', () {
      final p1 = ultimoMensajeProvider('t1');
      final p2 = ultimoMensajeProvider('t2');
      expect(p1, isNot(equals(p2)));
    });

    test('chatStreamProvider con mismo turnoId devuelve misma referencia', () {
      final p1 = chatStreamProvider('mismo-id');
      final p2 = chatStreamProvider('mismo-id');
      expect(p1, equals(p2));
    });
  });
}
