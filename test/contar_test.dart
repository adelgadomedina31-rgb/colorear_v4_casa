import 'package:colorear_ninos/juegos/contar/contar_ajustes.dart';
import 'package:colorear_ninos/juegos/contar/contar_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

/// La cosa de la ronda, según lo que dijo la voz al empezar.
Cosa cosaPedida() {
  for (final f in frases.reversed) {
    for (final c in AjustesContar.cosas) {
      final las = c.femenino ? 'las' : 'los';
      final una = c.femenino ? 'una' : 'uno';
      if (f ==
          AjustesContar.vozCuenta
              .replaceAll('{las}', las)
              .replaceAll('{cosas}', c.varias)
              .replaceAll('{una}', una)) {
        return c;
      }
    }
  }
  throw StateError('La voz no pidió contar nada: $frases');
}

String pregunta(Cosa c) => AjustesContar.vozPregunta
    .replaceAll('{Cuantas}', c.femenino ? 'Cuántas' : 'Cuántos')
    .replaceAll('{cosas}', c.varias);

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      '¿Cuántos hay?: toca cada cosa y la voz cuenta, después elige el '
      'número; si se equivoca cuentan otra vez; si acierta gana una estrella',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: ContarJuego(semilla: 5)));
    await esperar(tester);

    // Hay entre 1 y 3 cosas, y la voz dice qué contar.
    final cosa = cosaPedida();
    final n = cosasParaContar(tester);
    expect(n, inInclusiveRange(1, AjustesContar.hastaAlEmpezar));
    expect(find.text(cosa.dibujo), findsNWidgets(n));
    expect(estrellas(tester), 0);
    // Los botones todavía no se pueden tocar.
    await tester.tap(find.byKey(ValueKey<String>('respuesta_$n')),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(estrellas(tester), 0);

    // Toca cada cosa: la voz cuenta y le queda su número.
    for (var i = 0; i < n; i++) {
      await tester.tap(find.byKey(ValueKey<String>('cosa_$i')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(frases.last, AjustesContar.numeros[i]);
      expect(find.byKey(ValueKey<String>('numero_$i')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey<String>('contador')))
              .data,
          '${i + 1}');
    }
    // Tocar otra vez una ya contada no cuenta de nuevo.
    final dichas = frases.length;
    await tester.tap(find.byKey(const ValueKey<String>('cosa_0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(frases.length, dichas);

    // Después pregunta cuántas hay, y salen los botones.
    await tester.pump(const Duration(milliseconds: 1000));
    await esperar(tester, vueltas: 2);
    expect(frases.last, pregunta(cosa));
    final botones = botonesContar(tester);
    expect(botones.length, AjustesContar.botones);
    expect(botones, contains(n));

    // La orejita repite la pregunta.
    await tester.tap(find.byKey(const ValueKey<String>('repetir')));
    await esperar(tester, vueltas: 2);
    expect(frases.last, pregunta(cosa));

    // Toca otro número: la voz le dice cuál tocó y cuentan otra vez.
    final otro = botones.firstWhere((b) => b != n);
    await responder(tester, otro);
    expect(
        frases.last,
        AjustesContar.vozError
            .replaceAll('{otro}', AjustesContar.numeros[otro - 1]));
    expect(estrellas(tester), 0);
    await tester.pump(const Duration(seconds: 4));
    for (var k = 0; k < 40 && frases.last != pregunta(cosa); k++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(frases.last, pregunta(cosa));
    final contadas = frases.sublist(frases.lastIndexOf(AjustesContar.vozError
            .replaceAll('{otro}', AjustesContar.numeros[otro - 1])) +
        1);
    expect(contadas, <String>[
      ...AjustesContar.numeros.take(n),
      pregunta(cosa),
    ]);

    // Ahora acierta: gana una estrella y la voz la felicita.
    await responder(tester, n);
    expect(estrellas(tester), 1);
    final unaSola = n == 1;
    final numero = unaSola
        ? (cosa.femenino ? 'una' : 'un')
        : AjustesContar.numeros[n - 1];
    expect(
      AjustesContar.vozAcierto.map((f) => f
          .replaceAll('{numero}', numero)
          .replaceAll('{cosas}', unaSola ? cosa.una : cosa.varias)),
      contains(frases.last),
    );

    // Después viene otra ronda, con otra cosa.
    await tester.pump(const Duration(milliseconds: 4000));
    await esperar(tester, vueltas: 4);
    expect(cosaPedida(), isNot(cosa));
    expect(find.byKey(const ValueKey<String>('numero_0')), findsNothing);

    // Cada 5 aciertos, la celebración.
    for (var k = 1; k < AjustesContar.aciertosParaCelebrar; k++) {
      expect(celebracion, findsNothing);
      await acertarContar(tester);
    }
    expect(estrellas(tester), AjustesContar.aciertosParaCelebrar);
    expect(celebracion, findsOneWidget);
    expect(find.text(AjustesContar.celebracionLinea2), findsOneWidget);
    await cerrarPantalla(tester);
  });
}
