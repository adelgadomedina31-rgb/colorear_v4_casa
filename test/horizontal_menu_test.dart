import 'package:colorear_ninos/app/lista_juegos.dart';
import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/comun/pantalla_grande.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Con la tablet acostada el menú se ve en 3 columnas, todas las '
      'tarjetas enteras; al ponerla de pie vuelve a 2 columnas',
      (tester) async {
    sinAvisosDeSonido();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<Set<double>> columnas(Size tam) async {
      tester.view.physicalSize = tam;
      await tester.binding.setSurfaceSize(tam);
      await tester.pump();
      await esperar(tester);
      final lefts = <double>{};
      for (final juego in listaJuegos) {
        final tarjeta =
            tester.getRect(find.byKey(ValueKey<String>('juego_${juego.id}')));
        expect(tarjeta.top, greaterThanOrEqualTo(0), reason: juego.id);
        expect(tarjeta.bottom, lessThanOrEqualTo(tam.height),
            reason: '${juego.id} entera en la pantalla');
        expect(tarjeta.right, lessThanOrEqualTo(tam.width), reason: juego.id);
        lefts.add(tarjeta.left.roundToDouble());
      }
      return lefts;
    }

    tester.view.physicalSize = const Size(1280, 800);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(MaterialApp(
      builder: (context, hijo) => PantallaGrande(child: hijo!),
      home: const MenuJuegos(),
    ));
    await esperar(tester);
    expect((await columnas(const Size(1280, 800))).length, 3);
    expect((await columnas(const Size(800, 1280))).length, 2);
    expect((await columnas(const Size(1280, 800))).length, 3);
    // Un celular acostado también: se ven todas.
    await columnas(const Size(891, 411));
    await cerrarPantalla(tester);
  });
}
