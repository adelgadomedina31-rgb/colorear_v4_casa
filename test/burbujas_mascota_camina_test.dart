import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'La mascota camina y corre de un lado a otro sin salirse de su zona, '
      'mira hacia donde va, se queda quieta un ratito entre paseos, sopla '
      'burbujas desde donde está y si la tocas salta', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 1, semilla: 7)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    final m = juego.mascota!;
    final zona = zonaBurbujas(tester);
    final ancho = zona.width;
    const parte = AjustesBurbujas.zonaDeLaMascota;

    // Al llegar se queda quieta un ratito.
    expect(m.velocidad, 0);
    await avanzar(tester, const Duration(milliseconds: 600));
    expect(m.velocidad, 0);

    final miradas = <double>{};
    var camino = false;
    var paroDespues = false;
    var desde = 1.0;
    var hasta = 0.0;
    var antes = m.x;
    for (var k = 0; k < 600; k++) {
      // Revienta algunas para que sigan saliendo (sin terminar el nivel).
      final adentro = burbujasAdentro(tester);
      if (k % 20 == 0 &&
          adentro.length > 1 &&
          juego.total - juego.reventadas > 2) {
        await tocarBurbuja(tester, adentro.first);
      } else {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final lugar = m.lugar(zona.size);
      expect(lugar.left, greaterThanOrEqualTo(ancho * (0.5 - parte / 2) - 1),
          reason: 'no se sale de su zona');
      expect(lugar.right, lessThanOrEqualTo(ancho * (0.5 + parte / 2) + 1),
          reason: 'no se sale de su zona');
      expect(lugar.bottom, lessThanOrEqualTo(zona.height));
      if (m.velocidad > 0) {
        camino = true;
        miradas.add(m.mira);
        if ((m.x - antes).abs() > 1e-9) {
          expect((m.x - antes).sign, m.mira, reason: 'mira hacia donde va');
        }
        // Corriendo va más rápido.
        final normal = m.velocidad /
            (m.corriendo ? AjustesBurbujas.rapidezCorriendo : 1.0);
        expect(normal,
            closeTo(m.como.rapidez * m.tamanoPara(zona.size).width, 0.01));
      } else if (camino) {
        paroDespues = true;
      }
      if (m.x < desde) desde = m.x;
      if (m.x > hasta) hasta = m.x;
      antes = m.x;
    }
    expect(camino, isTrue, reason: 'camina');
    expect(paroDespues, isTrue, reason: 'se queda quieta entre paseos');
    expect(miradas, containsAll(<double>[-1, 1]), reason: 'va y vuelve');
    expect(hasta - desde, greaterThan(parte * 0.4), reason: 'recorre su zona');

    // Si la tocas mientras camina: salta, se ríe y deja de caminar mientras
    // salta.
    for (var k = 0; k < 400 && m.velocidad == 0; k++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(m.velocidad, greaterThan(0));
    final lugar = m.lugar(zona.size);
    final libre = juego.burbujas.every((b) =>
        (b.centro - lugar.center).distance > b.radio * 1.15 + lugar.width);
    if (libre) {
      await tester.tapAt(zona.topLeft + lugar.center);
      await tester.pump(const Duration(milliseconds: 40));
      expect(m.salto, greaterThan(0));
      expect(m.velocidad, 0);
    }

    // También sopla burbujas mientras camina: salen de su boca, donde esté
    // (se sigue jugando, pasando de nivel, hasta que pase).
    var sopladaCaminando = false;
    for (var k = 0; k < 3000 && !sopladaCaminando; k++) {
      final adentro = burbujasAdentro(tester);
      if (k % 15 == 0 && adentro.isNotEmpty) {
        await tocarBurbuja(tester, adentro.first);
      } else {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final mascota = juego.mascota;
      if (mascota == null || mascota.velocidad == 0) continue;
      for (final b in juego.burbujas) {
        if (b.soplada && b.nace == juego.ahora) {
          expect((b.centro - mascota.boca(zona.size)).distance, lessThan(1));
          sopladaCaminando = true;
        }
      }
    }
    expect(sopladaCaminando, isTrue);
    await cerrarPantalla(tester);
  });
}
