import 'package:colorear_ninos/app/lista_juegos.dart';
import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/app/presentacion.dart';
import 'package:colorear_ninos/juegos/colores/colores_juego.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'después de la presentación sale el menú de juegos; tocar un juego lo '
      'abre (la voz dice su nombre) y la casita vuelve al menú',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: Presentacion()));
    await tester.pump(const Duration(milliseconds: 500));
    // Tocar la presentación la salta.
    await tester.tapAt(const Offset(210, 430));
    await esperar(tester, vueltas: 10);
    expect(find.byType(MenuJuegos), findsOneWidget);

    // Una tarjeta por juego, con su nombre.
    for (final juego in listaJuegos) {
      expect(find.byKey(ValueKey<String>('juego_${juego.id}')), findsOneWidget);
      expect(find.text(juego.nombre.toUpperCase()), findsOneWidget);
    }

    // Colores.
    await tester.tap(find.byKey(const ValueKey<String>('juego_colores')));
    await esperar(tester, vueltas: 14);
    expect(frases.first, '¡Los colores!');
    expect(find.byType(ColoresJuego), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('casita')));
    await esperar(tester, vueltas: 10);
    expect(find.byType(ColoresJuego), findsNothing);
    expect(find.byType(MenuJuegos), findsOneWidget);

    // Pintar: se ven los dibujos y la casita también vuelve.
    await tester.tap(find.byKey(const ValueKey<String>('juego_pintar')));
    await esperar(tester, vueltas: 14);
    expect(find.byType(PintarMenu), findsOneWidget);
    await tester.tap(find.byIcon(Icons.home_rounded));
    await esperar(tester, vueltas: 10);
    expect(find.byType(PintarMenu), findsNothing);
    expect(find.byType(MenuJuegos), findsOneWidget);
    await cerrarPantalla(tester);
  });
}
