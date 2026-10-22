import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets('La Burbuja Saltarina salta a otro lado con cada toque',
      (tester) async {
    final b = await abrirJefe(tester, TipoJefe.saltarina);
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
