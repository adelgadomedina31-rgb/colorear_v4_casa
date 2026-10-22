import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'La Burbuja Dormilona duerme y va lentito; al tocarla se despierta '
      'y corre', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.dormilona);
    expect(b.gesto(0), Gesto.dormida);
    Future<double> recorre() async {
      var camino = 0.0;
      var antes = b.centro;
      for (var k = 0; k < 25; k++) {
        await tester.pump(const Duration(milliseconds: 40));
        camino += (b.centro - antes).distance;
        antes = b.centro;
      }
      return camino;
    }

    final dormida = await recorre();
    await tocarBurbuja(tester, b);
    expect(b.despiertaHasta, greaterThan(0));
    final despierta = await recorre();
    expect(despierta, greaterThan(dormida * 2), reason: 'despierta corre');
    final juego = juegoBurbujas(tester);
    expect(b.gesto(juego.ahora), isNot(Gesto.dormida));
    // Después de un rato se vuelve a dormir.
    await avanzar(tester, const Duration(seconds: 3));
    expect(b.despierta(juego.ahora), isFalse);
    expect(b.gesto(juego.ahora), Gesto.dormida);
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
