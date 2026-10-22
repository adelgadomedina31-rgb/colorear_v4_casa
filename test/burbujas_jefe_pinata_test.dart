import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets('A la Burbuja Piñata le caen burbujitas de dulce',
      (tester) async {
    final b = await abrirJefe(tester, TipoJefe.pinata);
    final juego = juegoBurbujas(tester);
    final antes = juego.burbujas.toSet();
    await tocarBurbuja(tester, b);
    final nuevas =
        juego.burbujas.where((o) => !antes.contains(o) && o != b).toList();
    expect(nuevas, hasLength(AjustesBurbujas.burbujitasPorToqueJefe));
    for (final c in nuevas) {
      expect(c.tipo, TipoBurbuja.chica);
      expect(coloresDulces, contains(c.color));
      expect(c.centro.dy, greaterThan(b.centro.dy - b.radio * 0.2),
          reason: 'caen hacia abajo');
    }
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
