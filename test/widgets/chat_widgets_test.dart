import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/ui/chat_message_ui.dart';
import 'package:vitta_app/widgets/chat/chat_bubble.dart';
import 'package:vitta_app/widgets/chat/chat_input.dart';
import 'package:vitta_app/widgets/chat/chat_list.dart';
import 'package:vitta_app/models/domain/chat_message_domain.dart';

void main() {
  group('ChatBubbleWidget', () {
    ChatMessageUI _mensajeMio() => ChatMessageUI(
          id: 'b1',
          remitenteId: 'yo',
          nombreRemitente: 'Yo',
          texto: 'Hola mundo',
          horaFormato: '14:30',
          fechaFormato: '09/04/2026',
          esMio: true,
          leido: false,
        );

    ChatMessageUI _mensajeOtro() => ChatMessageUI(
          id: 'b2',
          remitenteId: 'otro',
          nombreRemitente: 'Carlos',
          texto: 'Respuesta',
          horaFormato: '14:35',
          fechaFormato: '09/04/2026',
          esMio: false,
          leido: true,
        );

    testWidgets('renderiza texto del mensaje', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatBubbleWidget(mensaje: _mensajeMio())),
      ));
      expect(find.text('Hola mundo'), findsOneWidget);
    });

    testWidgets('renderiza hora del mensaje', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatBubbleWidget(mensaje: _mensajeMio())),
      ));
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('muestra nombre del remitente para mensaje ajeno', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatBubbleWidget(mensaje: _mensajeOtro())),
      ));
      expect(find.text('Carlos'), findsOneWidget);
    });

    testWidgets('no muestra nombre para mensaje propio', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatBubbleWidget(mensaje: _mensajeMio())),
      ));
      expect(find.text('Yo'), findsNothing);
    });

    testWidgets('muestra avatar para mensaje ajeno', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatBubbleWidget(mensaje: _mensajeOtro())),
      ));
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });

  group('ChatInputWidget', () {
    testWidgets('campo de texto es visible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInputWidget(onSendMessage: (_) {}, enabled: true),
        ),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('botón enviar es visible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInputWidget(onSendMessage: (_) {}, enabled: true),
        ),
      ));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('envía mensaje al presionar botón', (tester) async {
      String? enviado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInputWidget(
            onSendMessage: (t) => enviado = t,
            enabled: true,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(enviado, 'Test message');
    });

    testWidgets('no envía si está deshabilitado', (tester) async {
      String? enviado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInputWidget(
            onSendMessage: (t) => enviado = t,
            enabled: false,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(enviado, isNull);
    });

    testWidgets('limpia el campo después de enviar', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInputWidget(onSendMessage: (_) {}, enabled: true),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Hola');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text ?? '', isEmpty);
    });
  });

  group('ChatListWidget', () {
    testWidgets('muestra estado vacío cuando no hay mensajes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatListWidget(mensajes: const [], usuarioActualId: 'u1'),
        ),
      ));
      expect(find.text('Sin mensajes aún'), findsOneWidget);
    });

    testWidgets('renderiza burbujas para cada mensaje', (tester) async {
      final mensajes = [
        ChatMessageDomain(
          id: '1',
          turnoId: 't1',
          remitenteId: 'u1',
          nombreRemitente: 'Ana',
          texto: 'Mensaje uno',
          timestamp: DateTime(2026, 4, 9, 10, 0),
        ),
        ChatMessageDomain(
          id: '2',
          turnoId: 't1',
          remitenteId: 'u2',
          nombreRemitente: 'Bob',
          texto: 'Mensaje dos',
          timestamp: DateTime(2026, 4, 9, 10, 5),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatListWidget(mensajes: mensajes, usuarioActualId: 'u1'),
        ),
      ));

      expect(find.byType(ChatBubbleWidget), findsNWidgets(2));
    });
  });
}
