import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Si tocas a la mascota salta y habla: el gatito dice "miau", el '
      'perrito "guau" y el pollito "pío"', (tester) async {
    sinAvisosDeSonido();
    expect(AjustesBurbujas.sonidosMascotas, <String, String>{
      '🐱': 'burbujas/miau.wav',
      '🐶': 'burbujas/guau.wav',
      '🐥': 'burbujas/pio.wav',
    });
    final oidos = <String>{};
    for (var semilla = 0; semilla < 60 && oidos.length < 3; semilla++) {
      await tester.binding.setSurfaceSize(const Size(420, 860));
      await tester.pumpWidget(
          MaterialApp(home: BurbujasJuego(nivelInicial: 1, semilla: semilla)));
      await tester.pump(const Duration(milliseconds: 100));
      final juego = juegoBurbujas(tester);
      final m = juego.mascota!;
      final sonido = AjustesBurbujas.sonidosMascotas[m.emoji];
      if (sonido != null && !oidos.contains(m.emoji)) {
        await avanzar(tester, const Duration(milliseconds: 600));
        final zona = zonaBurbujas(tester);
        final lugar = m.lugar(zona.size);
        final libre = juego.burbujas.every(
            (b) => (b.centro - lugar.center).distance > b.radio * 1.15 + 20);
        if (libre) {
          Sonidos.pedidos.clear();
          await tester.tapAt(zona.topLeft + lugar.center);
          await tester.pump(const Duration(milliseconds: 40));
          expect(m.salto, greaterThan(0), reason: 'salta');
          expect(Sonidos.pedidos, contains(sonido), reason: m.emoji);
          expect(Sonidos.pedidos, isNot(contains(AjustesBurbujas.sonidoRisa)));
          oidos.add(m.emoji);
        }
      }
      await cerrarPantalla(tester);
    }
    expect(oidos, containsAll(<String>['🐱', '🐶', '🐥']));
  });
}
