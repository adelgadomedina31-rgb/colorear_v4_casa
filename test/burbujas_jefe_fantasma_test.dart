import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'La Burbuja Fantasma se ve medio transparente; al tocarla dice '
      '"¡buu!", desaparece y aparece en otro lado', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.fantasma);
    final juego = juegoBurbujas(tester);
    expect(b.opacidad(juego.ahora), inInclusiveRange(0.6, 0.98),
        reason: 'medio transparente');
    final donde = b.centro;
    final toques = b.toques;
    Sonidos.pedidos.clear();
    await tocarBurbuja(tester, b);
    expect(b.toques, toques - 1);
    expect(Sonidos.pedidos, contains(AjustesBurbujas.sonidosJefes['fantasma']));
    expect(b.escondiendo(juego.ahora), isTrue);

    // Desaparece (y mientras no se ve, no se puede tocar)...
    var menos = 1.0;
    var probo = false;
    for (var k = 0; k < 20 && b.escondiendo(juego.ahora); k++) {
      final o = b.opacidad(juego.ahora);
      if (o < menos) menos = o;
      if (o < 0.3 && !probo) {
        probo = true;
        await tester.tapAt(dondeEsta(tester, b));
        expect(b.toques, toques - 1, reason: 'escondida no se toca');
      }
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(menos, lessThan(0.15), reason: 'casi no se ve');
    expect(probo, isTrue);
    // ... y aparece en otro lado.
    await tester.pump(const Duration(milliseconds: 40));
    expect(b.opacidad(juego.ahora), greaterThan(0.6));
    expect((b.centro - donde).distance, greaterThan(b.radio),
        reason: 'apareció lejos');
    expect(estaAdentro(tester, b), isTrue);
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
