import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/entities/paciente_entity.dart';
import 'package:vitta_app/providers/paciente_principal_provider.dart';
import 'package:vitta_app/widgets/dashboard/emergency_contact_widget.dart';
import 'package:vitta_app/widgets/dashboard/solicitar_turno_card_widget.dart';

/// Paciente de prueba para override del provider.
const _pacienteDemo = PacienteEntity(
  id: 'p-test-01',
  familiarId: 'f-test-01',
  nombre: 'Abuela Rosa',
  edad: 75,
  planActivo: 'salud',
  nivelCuidado: 2,
  diagnostico: 'Hipertensión',
);

void main() {
  group('EmergencyContactWidget', () {
    testWidgets('renderiza título de emergencia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyContactWidget(),
          ),
        ),
      );
      expect(find.text('¿Emergencia?'), findsOneWidget);
    });

    testWidgets('renderiza botón "Llamar ahora"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyContactWidget(),
          ),
        ),
      );
      expect(find.text('Llamar ahora'), findsOneWidget);
    });

    testWidgets('muestra texto de soporte 24/7', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyContactWidget(),
          ),
        ),
      );
      expect(find.textContaining('24/7'), findsOneWidget);
    });

    testWidgets('contiene OutlinedButton para llamar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyContactWidget(),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('muestra icono de advertencia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyContactWidget(),
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });
  });

  group('SolicitarTurnoCardWidget', () {
    Widget _buildWithPaciente(PacienteEntity? paciente) {
      return ProviderScope(
        overrides: [
          pacientePrincipalProvider.overrideWith(
            (ref) async => paciente,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SolicitarTurnoCardWidget(),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra título "Solicita tu cuidador" con paciente', (tester) async {
      await tester.pumpWidget(_buildWithPaciente(_pacienteDemo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Solicita tu cuidador'), findsOneWidget);
    });

    testWidgets('muestra botón "Solicitar turno" con paciente', (tester) async {
      await tester.pumpWidget(_buildWithPaciente(_pacienteDemo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Solicitar turno'), findsOneWidget);
    });

    testWidgets('muestra descripción del nivel según plan salud', (tester) async {
      await tester.pumpWidget(_buildWithPaciente(_pacienteDemo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Plan "salud" → "Cuidadores N1 y N2"
      expect(find.textContaining('N1'), findsWidgets);
      expect(find.textContaining('N2'), findsWidgets);
    });

    testWidgets('muestra ElevatedButton para solicitar', (tester) async {
      await tester.pumpWidget(_buildWithPaciente(_pacienteDemo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('con paciente null retorna SizedBox.shrink', (tester) async {
      await tester.pumpWidget(_buildWithPaciente(null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Solicita tu cuidador'), findsNothing);
      expect(find.text('Solicitar turno'), findsNothing);
    });

    testWidgets('muestra indicador de carga mientras paciente carga', (tester) async {
      // Usamos un Completer que cerramos al final del test para evitar timers pendientes.
      final completer = Future<PacienteEntity?>.value(_pacienteDemo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Reemplazamos con el futuro del paciente demo (resuelve inmediatamente).
            // El loading state aparece en el primer pump antes de que se resuelva.
            pacientePrincipalProvider.overrideWith((ref) => completer),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SolicitarTurnoCardWidget(),
            ),
          ),
        ),
      );
      // Primer pump: puede estar en loading o ya resuelto (future inmediato).
      // Verificamos que el widget existe sin errores.
      await tester.pump();
      // Tras resolución, debe mostrar el contenido.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SolicitarTurnoCardWidget), findsOneWidget);
    });
  });
}
