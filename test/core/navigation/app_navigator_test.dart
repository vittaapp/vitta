import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/core/navigation/app_navigator.dart';

void main() {
  group('AppNavigator', () {
    test('expone métodos estáticos de navegación', () {
      expect(AppNavigator.replaceWithRoleHome, isA<Function>());
      expect(AppNavigator.replaceWithRoleHomePostFrame, isA<Function>());
    });

    testWidgets(
      'replaceWithRoleHomePostFrame no falla con context desmontado',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: _Host()),
          ),
        );

        final hostFinder = find.byType(_Host);
        final oldContext = tester.element(hostFinder);

        // Desmontamos _Host para simular context inválido al ejecutarse el callback.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

        expect(
          () => AppNavigator.replaceWithRoleHomePostFrame(
            oldContext,
            'familiar',
          ),
          returnsNormally,
        );

        await tester.pump();
      },
    );
  });
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
