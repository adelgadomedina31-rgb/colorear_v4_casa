import 'package:colorear_ninos/comun/pantalla_grande.dart';
import 'package:colorear_ninos/juegos/pintar/partes/lienzo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Pintar con la tablet acostada: el dibujo grande y los colores al '
      'costado; al girarla no se pierde lo que estaba haciendo',
      (tester) async {
    sinAvisosDeSonido();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1280, 800);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(MaterialApp(
      builder: (context, hijo) => PantallaGrande(child: hijo!),
      home: PintarPantalla(dibujos: [cuadrado('a')], indice: 0),
    ));
    await esperar(tester);

    Rect dibujo() => tester.getRect(find.byType(Lienzo));
    Rect colores() => tester.getRect(find.byType(Paleta));

    // Acostada: los colores a la derecha del dibujo, y el dibujo grande.
    expect(colores().left, greaterThan(dibujo().right - 1));
    expect(dibujo().height, greaterThan(800 * 0.6));
    expect(colores().bottom, lessThanOrEqualTo(800));
    final lienzo = tester.state(find.byType(Lienzo));

    // De pie: los colores abajo del dibujo.
    tester.view.physicalSize = const Size(800, 1280);
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    await esperar(tester);
    expect(colores().top, greaterThan(dibujo().bottom - 1));
    expect(colores().bottom, lessThanOrEqualTo(1280));
    expect(tester.state(find.byType(Lienzo)), same(lienzo),
        reason: 'el mismo dibujo, con lo pintado');
    await cerrarPantalla(tester);
  });
}
