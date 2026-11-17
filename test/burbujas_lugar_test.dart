import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'En la tablet las burbujas no tapan más de la cuenta (tienen lugar '
      'para moverse), siguen saliendo muchas y el jefe es igual de grande',
      (tester) async {
    sinAvisosDeSonido();
    // La tablet, como se ve con la app agrandada (520 de ancho).
    tester.view.physicalSize = const Size(520, 832);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 25, semilla: 3)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    final zona = juego.zona!;
    var tapadoMaximo = 0.0;
    var enPantallaMaximo = 0;
    for (var k = 0; k < 500; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      var tapado = 0.0;
      for (final b in juego.burbujas) {
        tapado += math.pi * b.radio * b.radio;
      }
      tapadoMaximo =
          math.max(tapadoMaximo, tapado / (zona.width * zona.height));
      enPantallaMaximo = math.max(enPantallaMaximo, juego.burbujas.length);
    }
    expect(tapadoMaximo,
        lessThanOrEqualTo(AjustesBurbujas.espacioMaximoTapado + 0.001));
    expect(enPantallaMaximo, greaterThanOrEqualTo(8),
        reason: 'siguen saliendo muchas a la vez');

    final jefe = juego.burbujas.firstWhere((b) => b.tipo == TipoBurbuja.jefe);
    expect(jefe.radioInicial,
        closeTo(AjustesBurbujas.tamanoJefe * zona.width / 2, 0.5),
        reason: 'el jefe usa todo el ancho');
    for (final b in juego.burbujas) {
      if (b.tipo != TipoBurbuja.normal) continue;
      expect(b.radio,
          lessThan(AjustesBurbujas.tamanoMaximo * zona.width / 2 * 0.8),
          reason: 'en la tablet las normales son más chicas');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
