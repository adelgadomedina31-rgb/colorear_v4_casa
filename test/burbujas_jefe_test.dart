import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Nivel 1: llega el Rey Burbuja, gigante, y hace temblar la pantalla; '
      'con cada toque se achica, se ríe, sale corriendo y suelta '
      'burbujitas, y al final explota en muchas más con fuegos artificiales',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 1, semilla: 3)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    final plan = juego.plan!;
    expect(plan.jefe, TipoJefe.rey);
    expect(frases.last, AjustesBurbujas.vozJefes['rey']);
    expect(Sonidos.pedidos, contains(AjustesBurbujas.sonidoJefe),
        reason: 'llega con música');
    expect(plan.cuantas(TipoBurbuja.normal), AjustesBurbujas.burbujasAlEmpezar);
    expect(juego.total,
        AjustesBurbujas.burbujasAlEmpezar + 1 + plan.burbujitasDelJefe,
        reason: 'las burbujitas que suelta también cuentan');

    // Es el primero en salir, desde arriba, y es gigante.
    await avanzar(tester, const Duration(milliseconds: 700));
    final rey = juego.burbujas.first;
    expect(rey.tipo, TipoBurbuja.jefe);
    expect(rey.jefe, TipoJefe.rey);
    expect(rey.centro.dy, lessThan(0), reason: 'baja desde arriba');
    final lado = zonaBurbujas(tester).size.shortestSide;
    expect(rey.radio * 2 / lado, closeTo(AjustesBurbujas.tamanoJefe, 0.01));
    expect(rey.toques, plan.toquesJefe);

    // Espera a que entre, reventando las normales mientras tanto. Al
    // llegar, la pantalla tiembla.
    var temblo = false;
    for (var k = 0; k < 500 && !rey.llego; k++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(rey.llego, isTrue);
    for (var k = 0; k < 5; k++) {
      if (juego.temblor != Offset.zero) temblo = true;
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(temblo, isTrue, reason: 'la pantalla tiembla cuando llega');
    await esperarBurbuja(tester, TipoBurbuja.jefe);
    final radioInicial = rey.radio;
    final hechas = juego.reventadas;
    int chicas() =>
        juego.burbujas.where((b) => b.tipo == TipoBurbuja.chica).length;

    for (var k = 1; k < plan.toquesJefe; k++) {
      final radio = rey.radio;
      final antes = chicas();
      Sonidos.pedidos.clear();
      await tocarBurbuja(tester, rey);
      expect(Sonidos.pedidos, contains(AjustesBurbujas.sonidoToqueJefe));
      expect(rey.apurado(juego.ahora), isTrue, reason: 'sale corriendo');
      expect(juego.burbujas, contains(rey), reason: 'todavía no revienta');
      expect(rey.toques, plan.toquesJefe - k);
      expect(rey.radio, lessThan(radio), reason: 'se achica');
      expect(rey.gesto(rey.risa), Gesto.risa, reason: 'se ríe');
      expect(chicas(), antes + AjustesBurbujas.burbujitasPorToqueJefe,
          reason: 'suelta burbujitas');
      expect(juego.reventadas, hechas);
    }
    expect(
        rey.radio, closeTo(radioInicial * AjustesBurbujas.jefeAchicaHasta, 1),
        reason: 'al final queda chiquito');

    // El último toque: ¡explota en muchas burbujitas y la mascota aplaude!
    final antes = chicas();
    Sonidos.pedidos.clear();
    await tocarBurbuja(tester, rey);
    expect(juego.burbujas, isNot(contains(rey)));
    expect(juego.reventadas, hechas + 1);
    expect(chicas(), antes + AjustesBurbujas.burbujitasAlReventarJefe);
    expect(juego.mascota!.aplaudeHasta, greaterThan(0));
    expect(Sonidos.pedidos, contains(AjustesBurbujas.sonidoJefePop));
    expect(juego.temblor, isNot(Offset.zero), reason: 'tiembla todo');

    await reventarTodas(tester);
    expect(juego.reventadas, juego.total);
    await avanzar(tester, const Duration(seconds: 3));
    expect(juego.nivel, 2);
    final otro = juego.plan!.jefe;
    expect(otro, isNotNull, reason: 'en el nivel siguiente llega otro jefe');
    expect(otro, isNot(TipoJefe.rey));
    await cerrarPantalla(tester);
  });
}
