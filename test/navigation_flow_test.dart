import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:tfg/pantalla/cliente1.dart';
import 'package:tfg/pantalla/inicio.dart';
import 'package:tfg/pantalla/perfilC.dart';
import 'package:tfg/pantalla/perfilT.dart';
import 'package:tfg/pantalla/trabajador1.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxIterations = 100,
  Duration step = const Duration(milliseconds: 250),
}) async {
  for (var i = 0; i < maxIterations; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flujo cliente: Login -> Main -> PerfilC -> Cerrar sesion -> Login', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      await tester.enterText(find.byType(TextField).first, 'cliente@gmail.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await _pumpUntilFound(tester, find.byType(MainScreen));

      expect(find.byType(MainScreen), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await _pumpUntilFound(tester, find.byType(ClientProfileScreen));

      expect(find.byType(ClientProfileScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar Sesión'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cerrar Sesión'));
      await _pumpUntilFound(tester, find.byType(LoginScreen));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  testWidgets('Flujo trabajador: Login -> Main -> PerfilT -> Cerrar sesion -> Login', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      await tester.enterText(
        find.byType(TextField).first,
        'trabajador@gmail.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await _pumpUntilFound(tester, find.byType(WorkerMainScreen));

      expect(find.byType(WorkerMainScreen), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await _pumpUntilFound(tester, find.byType(WorkerProfileScreen));

      expect(find.byType(WorkerProfileScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar Sesión'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cerrar Sesión'));
      await _pumpUntilFound(tester, find.byType(LoginScreen));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
