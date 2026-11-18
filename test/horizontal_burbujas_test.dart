import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Burbujas: al girar la tablet en pleno nivel las burbujas siguen '
      'adentro de la pantalla y se pueden reventar', (tester) async {
    sinAvisosDeSonido();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(520, 832);
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 6, semilla: 4)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    await avanzar(tester, const Duration(seconds: 6));
    await reventarBurbujas(tester, 2);

    // Acostada.
    tester.view.physicalSize = const Size(832, 520);
    await avanzar(tester, const Duration(seconds: 4));
    final zona = juego.zona!;
    expect(zona.width, greaterThan(zona.height));
    for (final b in juego.burbujas.where((b) => b.adentro)) {
      expect(b.centro.dx, inInclusiveRange(0, zona.width), reason: '${b.id}');
      expect(b.centro.dy, inInclusiveRange(0, zona.height), reason: '${b.id}');
    }
    await reventarBurbujas(tester, 5);

    // De pie otra vez.
    tester.view.physicalSize = const Size(520, 832);
    await avanzar(tester, const Duration(seconds: 3));
    await reventarBurbujas(tester, 7);
    await cerrarPantalla(tester);
  });
}
