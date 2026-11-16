import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'La Burbuja Saltarina da saltitos sola, y con cada toque salta lejos',
      (tester) async {
    final b = await abrirJefe(tester, TipoJefe.saltarina);
    final juego = juegoBurbujas(tester);
    var saltito = false;
    for (var k = 0; k < 100 && !saltito; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      saltito = b.saltando(juego.ahora);
    }
    expect(saltito, isTrue, reason: 'da saltitos sola');
    await avanzar(tester, const Duration(milliseconds: 600));
    expect(estaAdentro(tester, b), isTrue);
    final donde = b.centro;
    await tocarBurbuja(tester, b);
    await avanzar(tester, const Duration(milliseconds: 200));
    expect(b.gesto(b.risa + 0.01), Gesto.risa);
    await avanzar(tester, const Duration(milliseconds: 400));
    expect((b.centro - donde).distance, greaterThan(b.radio),
        reason: 'saltó lejos');
    expect(estaAdentro(tester, b), isTrue, reason: 'y sigue en la pantalla');
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
