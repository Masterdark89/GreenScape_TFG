import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:tfg/pantalla/cliente1.dart';
import 'package:tfg/pantalla/inicio.dart';
import 'package:tfg/pantalla/perfilC.dart';
import 'package:tfg/pantalla/perfilT.dart';
import 'package:tfg/pantalla/trabajador1.dart';

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
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientProfileScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar Sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar Sesión'));
      await tester.pumpAndSettle();

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
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(WorkerMainScreen), findsOneWidget);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkerProfileScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar Sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar Sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
