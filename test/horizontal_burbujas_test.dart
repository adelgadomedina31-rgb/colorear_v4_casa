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
      'Burbujas acostada: los botones, las estrellas y la barrita van al '
      'costado y las burbujas tienen todo el alto; de pie van arriba en una '
      'sola fila. Al girar en pleno nivel todo sigue andando', (tester) async {
    sinAvisosDeSonido();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const acostada = Size(832, 520);
    const dePie = Size(520, 832);
    tester.view.physicalSize = acostada;
    await tester.pumpWidget(const MaterialApp(
        home: BurbujasJuego(nivelInicial: 6, semilla: 4, jefe: TipoJefe.rey)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    final jefe = await esperarBurbuja(tester, TipoBurbuja.jefe);

    Rect donde(String clave) =>
        tester.getRect(find.byKey(ValueKey<String>(clave)));

    // Acostada: la barra a la izquierda, las burbujas con todo el alto.
    var zona = juego.zona!;
    expect(zona.height, acostada.height);
    expect(zona.width, greaterThan(acostada.width - 110));
    expect(donde('progreso').right, lessThan(110));
    expect(donde('casita').top, lessThan(donde('repetir').top));
    // El jefe, una parte del alto (le queda lugar para subir y bajar).
    expect(jefe.radioInicial,
        closeTo(AjustesBurbujas.tamanoJefeAcostada * zona.height / 2, 0.5));
    await reventarBurbujas(tester, 2, salvo: (b) => b.tipo == TipoBurbuja.jefe);

    // De pie: todo arriba en una fila (la barrita al costado de las
    // estrellas), y el resto para las burbujas.
    tester.view.physicalSize = dePie;
    await avanzar(tester, const Duration(seconds: 3));
    zona = juego.zona!;
    expect(zona.width, dePie.width);
    expect(zona.height, greaterThan(dePie.height - 90));
    expect(donde('progreso').top, lessThan(donde('estrellas').bottom));
    expect(donde('progreso').left, greaterThan(donde('estrellas').right));
    for (final b in juego.burbujas.where((b) => b.adentro)) {
      expect(b.centro.dx, inInclusiveRange(0, zona.width), reason: '${b.id}');
      expect(b.centro.dy, inInclusiveRange(0, zona.height), reason: '${b.id}');
    }
    await reventarBurbujas(tester, 4, salvo: (b) => b.tipo == TipoBurbuja.jefe);

    // Acostada otra vez.
    tester.view.physicalSize = acostada;
    await avanzar(tester, const Duration(seconds: 3));
    await reventarBurbujas(tester, 6, salvo: (b) => b.tipo == TipoBurbuja.jefe);
    await cerrarPantalla(tester);
  });
}
