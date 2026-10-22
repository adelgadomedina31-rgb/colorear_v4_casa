import 'package:colorear_ninos/juegos/colores/colores_ajustes.dart';
import 'package:colorear_ninos/juegos/colores/colores_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Colores: la voz pide un globo, si se equivoca le dice cuál tocó, si '
      'acierta gana una estrella, y los globos van aumentando', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: ColoresJuego()));
    await esperar(tester);

    // Empieza con 2 globos y la voz pide uno de ellos.
    expect(nombresCon(tester, 'globo_').length, AjustesColores.globosAlEmpezar);
    final pedido = globoPedido();
    expect(nombresCon(tester, 'globo_'), contains(pedido));
    expect(estrellas(tester), 0);

    // Toca el otro: la voz le dice qué color tocó y cuál buscar.
    final otro = nombresCon(tester, 'globo_').firstWhere((n) => n != pedido);
    await tocarGlobo(tester, otro);
    expect(
        frases.last,
        AjustesColores.vozError
            .replaceAll('{otro}', otro.toLowerCase())
            .replaceAll('{color}', pedido.toLowerCase()));
    expect(estrellas(tester), 0);

    // La orejita repite lo que hay que buscar.
    await tester.tap(find.byKey(const ValueKey<String>('repetir')));
    await esperar(tester, vueltas: 2);
    expect(frases.last, pedirGlobo(pedido));

    // Toca el correcto: gana una estrella y la voz la felicita.
    await tocarGlobo(tester, pedido);
    expect(estrellas(tester), 1);
    expect(
      AjustesColores.vozAcierto
          .map((f) => f.replaceAll('{color}', pedido.toLowerCase())),
      contains(frases.last),
    );

    // Después viene otra ronda, con otro color.
    await tester.pump(const Duration(milliseconds: 4600));
    await esperar(tester, vueltas: 3);
    expect(globoPedido(), isNot(pedido));

    // Tres aciertos seguidos sin equivocarse: aparece un globo más.
    for (var k = 0; k < AjustesColores.aciertosParaSubir; k++) {
      expect(nombresCon(tester, 'globo_').length, 2);
      await acertarGlobo(tester);
    }
    expect(estrellas(tester), 1 + AjustesColores.aciertosParaSubir);
    expect(nombresCon(tester, 'globo_').length, 3);

    // Al llegar a 5 globos reventados sale la celebración...
    await tocarGlobo(tester, globoPedido());
    expect(estrellas(tester), AjustesColores.aciertosParaCelebrar);
    await tester.pump(const Duration(milliseconds: 4600));
    await tester.pump(const Duration(seconds: 1));
    expect(celebracion, findsOneWidget);
    expect(find.text(AjustesColores.celebracionLinea2), findsOneWidget);
    expect(frases, contains(AjustesColores.vozCelebracion));

    // ...y al quitarla sigue el juego.
    await quitarCelebracion(tester);
    expect(celebracion, findsNothing);
    await esperar(tester, vueltas: 2);
    expect(frases.last, pedirGlobo(globoPedido()));
    await cerrarPantalla(tester);
  });
}
