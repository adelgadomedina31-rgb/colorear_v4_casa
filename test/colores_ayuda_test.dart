import 'package:colorear_ninos/juegos/colores/colores_ajustes.dart';
import 'package:colorear_ninos/juegos/colores/colores_juego.dart';
import 'package:colorear_ninos/juegos/colores/globo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Colores: si se equivoca varias veces, el globo correcto brilla y '
      'después hay un globo menos', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: ColoresJuego()));
    await esperar(tester);

    // Primero sube a 3 globos.
    for (var k = 0; k < AjustesColores.aciertosParaSubir; k++) {
      await acertarGlobo(tester);
    }
    expect(nombresCon(tester, 'globo_').length, 3);

    double brillo(String nombre) {
      final pintor = tester
          .widgetList<CustomPaint>(find.descendant(
            of: find.byKey(ValueKey<String>('globo_$nombre')),
            matching: find.byType(CustomPaint),
          ))
          .map((c) => c.painter)
          .whereType<PintorGlobo>()
          .first;
      return pintor.ayuda;
    }

    // Se equivoca: todavía no hay ayuda.
    final pedido = globoPedido();
    final otro = nombresCon(tester, 'globo_').firstWhere((n) => n != pedido);
    await tocarGlobo(tester, otro);
    await tester.pump(const Duration(milliseconds: 250));
    expect(brillo(pedido), 0);

    // Se vuelve a equivocar: el correcto brilla para ayudarla.
    await tocarGlobo(tester, otro);
    var maximo = 0.0;
    for (var k = 0; k < 14; k++) {
      await tester.pump(const Duration(milliseconds: 80));
      if (brillo(pedido) > maximo) maximo = brillo(pedido);
    }
    expect(maximo, greaterThan(0.3));
    expect(brillo(otro), 0);

    // Acierta: en la ronda siguiente hay un globo menos (vuelve a 2).
    await acertarGlobo(tester);
    expect(nombresCon(tester, 'globo_').length, 2);
    await cerrarPantalla(tester);
  });
}
