import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/app/pantalla_ajustes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets('en Ajustes se puede ocultar un juego del menú (y se recuerda)',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: MenuJuegos()));
    await esperar(tester);
    const animales = ValueKey<String>('juego_animales');
    expect(find.byKey(animales), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('engranaje')));
    await esperar(tester, vueltas: 10);
    expect(find.byType(PantallaAjustes), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('mostrar_animales')));
    await esperar(tester, vueltas: 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('juegos_ocultos'), <String>['animales']);

    await tester.pageBack();
    await esperar(tester, vueltas: 10);
    expect(find.byKey(animales), findsNothing);
    expect(find.byKey(const ValueKey<String>('juego_pintar')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('juego_colores')), findsOneWidget);

    // Al abrir la app otra vez sigue oculto.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: MenuJuegos()));
    await esperar(tester);
    expect(find.byKey(animales), findsNothing);
    await cerrarPantalla(tester);
  });
}
