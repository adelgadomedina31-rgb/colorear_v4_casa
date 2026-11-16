import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'La Burbuja Pelota rebota y rebota en el piso, rodando; al tocarla '
      'pega un salto altísimo', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.pelota);
    final alto = zonaBurbujas(tester).height;

    // Rebota: toca el piso varias veces y sube alto, y rueda.
    var rebotes = 0;
    var arriba = b.centro.dy;
    var abajo = b.centro.dy;
    var vy = b.vy;
    final vuelta = b.vuelta;
    for (var k = 0; k < 100; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (vy > 0 && b.vy < 0) rebotes++;
      vy = b.vy;
      if (b.centro.dy < arriba) arriba = b.centro.dy;
      if (b.centro.dy > abajo) abajo = b.centro.dy;
      expect(estaAdentro(tester, b), isTrue, reason: 'no se sale');
    }
    expect(rebotes, greaterThanOrEqualTo(2));
    expect(abajo - arriba, greaterThan(alto * 0.25), reason: 'sube alto');
    expect(b.vuelta, isNot(vuelta), reason: 'rueda');

    // Al tocarla: ¡un salto hasta arriba de todo!
    for (var k = 0; k < 100 && b.vy <= 0; k++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tocarBurbuja(tester, b);
    expect(b.vy, lessThan(0), reason: 'salta para arriba');
    var cumbre = b.centro.dy;
    for (var k = 0; k < 40; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (b.centro.dy < cumbre) cumbre = b.centro.dy;
    }
    expect(cumbre, lessThan(b.margenArriba + b.radio * 0.6),
        reason: 'llega hasta arriba');
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
