import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'El Remolino Burbuja da vueltas y vueltas; al tocarlo gira rapidísimo '
      'y tira burbujitas en espiral', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.remolino);
    final juego = juegoBurbujas(tester);

    var antes = b.vuelta;
    await avanzar(tester, const Duration(seconds: 1));
    final normal = b.vuelta - antes;
    expect(normal, greaterThan(2), reason: 'gira');

    final viejas = juego.burbujas.toSet();
    await tocarBurbuja(tester, b);
    final nuevas = juego.burbujas.where((o) => !viejas.contains(o)).toList();
    expect(nuevas, isNotEmpty);
    for (final c in nuevas) {
      // Salen de costado (en espiral), no derecho para afuera.
      final afuera = c.centro - b.centro;
      final va =
          (math.cos(c.rumbo) * afuera.dx + math.sin(c.rumbo) * afuera.dy) /
              afuera.distance;
      expect(va.abs(), lessThan(0.7));
    }
    antes = b.vuelta;
    await avanzar(tester, const Duration(seconds: 1));
    expect(b.vuelta - antes, greaterThan(normal * 2.5), reason: 'rapidísimo');
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
