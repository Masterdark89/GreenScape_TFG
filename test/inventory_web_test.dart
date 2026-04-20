import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/pantalla/inventario.dart';

void main() {
  testWidgets('Inventario carga datos desde la base de datos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InventoryScreen()),
    );

    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Inventario').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('No se pudo cargar el inventario'), findsNothing);
    expect(find.text('Inventario'), findsWidgets);
  });
}
