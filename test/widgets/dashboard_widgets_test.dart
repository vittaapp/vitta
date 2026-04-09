import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/widgets/common/section_title_widget.dart';
import 'package:vitta_app/widgets/dashboard/access_card_widget.dart';
import 'package:vitta_app/widgets/dashboard/chip_disponibilidad_widget.dart';

void main() {
  group('Dashboard widgets básicos', () {
    testWidgets('SectionTitleWidget renderiza texto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SectionTitleWidget(text: 'Mi sección')),
        ),
      );

      expect(find.text('Mi sección'), findsOneWidget);
    });

    testWidgets('AccessCardWidget renderiza y ejecuta onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessCardWidget(
              icono: Icons.medical_services,
              titulo: 'Acceso',
              subtitulo: 'Detalle',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Acceso'), findsOneWidget);
      expect(find.text('Detalle'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('ChipDisponibilidadWidget renderiza icono y label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChipDisponibilidadWidget(
              icon: Icons.wb_sunny_rounded,
              label: 'Mañana',
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('Mañana'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
    });
  });
}
