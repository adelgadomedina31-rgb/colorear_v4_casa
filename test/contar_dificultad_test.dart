import 'package:colorear_ninos/juegos/contar/contar_ajustes.dart';
import 'package:colorear_ninos/juegos/contar/contar_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      '¿Cuántos hay?: si acierta seguido puede haber más cosas (hasta 5)',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: ContarJuego(semilla: 9)));
    await esperar(tester);

    var mayor = 0;
    for (var k = 0; k < 14; k++) {
      final n = cosasParaContar(tester);
      if (n > mayor) mayor = n;
      expect(n, lessThanOrEqualTo(AjustesContar.hastaMaximo));
      expect(botonesContar(tester), contains(n));
      await acertarContar(tester);
      // Se salta la celebración.
      if (celebracion.evaluate().isNotEmpty) {
        await tester.pump(const Duration(seconds: 10));
        await esperar(tester, vueltas: 4);
      }
    }
    expect(mayor, greaterThan(AjustesContar.hastaAlEmpezar),
        reason: 'después de acertar seguido hay más cosas');
    await cerrarPantalla(tester);
  });
}
