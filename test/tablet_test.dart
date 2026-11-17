import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/app/lista_juegos.dart';
import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/comun/pantalla_grande.dart';
import 'package:colorear_ninos/juegos/colores/colores_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  test('En un celular no se agranda nada; en la tablet de 10 pulgadas, sí', () {
    expect(PantallaGrande.cuantoAgrandar(const Size(411, 891)), 1);
    expect(PantallaGrande.cuantoAgrandar(const Size(360, 780)), 1);
    // Blackview Tab 20 Kids: 800 x 1280.
    expect(PantallaGrande.cuantoAgrandar(const Size(800, 1280)),
        closeTo(800 / AjustesApp.anchoComoCelular, 0.001));
    expect(
        PantallaGrande.cuantoAgrandar(const Size(800, 1280)), greaterThan(1.3));
  });

  testWidgets(
      'En la tablet todo se ve más grande: el menú se arma con el ancho de '
      'un celular, se ven todas las tarjetas sin mover la pantalla y al '
      'tocar una se abre el juego', (tester) async {
    sinAvisosDeSonido();
    // Blackview Tab 20 Kids: 800 x 1280.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    await tester.pumpWidget(MaterialApp(
      builder: (context, hijo) => PantallaGrande(child: hijo!),
      home: const MenuJuegos(),
    ));
    await esperar(tester);

    // Adentro, la pantalla "mide" como un celular grande.
    final ancho =
        MediaQuery.sizeOf(tester.element(find.byType(MenuJuegos))).width;
    expect(ancho, closeTo(AjustesApp.anchoComoCelular, 0.5));

    // Todas las tarjetas se ven enteras dentro de la pantalla, y grandes.
    for (final juego in listaJuegos) {
      final tarjeta =
          tester.getRect(find.byKey(ValueKey<String>('juego_${juego.id}')));
      expect(tarjeta.top, greaterThanOrEqualTo(0));
      expect(tarjeta.bottom, lessThanOrEqualTo(1280), reason: juego.id);
      expect(tarjeta.width, greaterThan(300),
          reason: 'en la tablet las tarjetas son grandes');
    }

    // Tocar una tarjeta abre el juego (los toques llegan bien).
    await tester.tap(find.byKey(const ValueKey<String>('juego_colores')));
    await esperar(tester, vueltas: 14);
    expect(find.byType(ColoresJuego), findsOneWidget);
    // La casita, más grande que en el celular, también se puede tocar.
    final casita = tester.getRect(find.byKey(const ValueKey<String>('casita')));
    expect(casita.width, greaterThan(70));
    await tester.tap(find.byKey(const ValueKey<String>('casita')));
    await esperar(tester, vueltas: 10);
    expect(find.byType(MenuJuegos), findsOneWidget);
    await cerrarPantalla(tester);
  });
}
