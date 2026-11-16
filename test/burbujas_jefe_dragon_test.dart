import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'El Dragón Burbuja vuela haciendo olas; al tocarlo estornuda '
      'chispitas de colores y le salen burbujitas de la boca', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.dragon);
    final juego = juegoBurbujas(tester);

    // Vuela haciendo olas: cambia de dirección todo el tiempo.
    var menos = b.rumbo;
    var mas = b.rumbo;
    for (var k = 0; k < 50; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      if (b.rumbo < menos) menos = b.rumbo;
      if (b.rumbo > mas) mas = b.rumbo;
    }
    expect(mas - menos, greaterThan(0.5));

    final viejas = juego.burbujas.toSet();
    Sonidos.pedidos.clear();
    await tocarBurbuja(tester, b);
    expect(juego.llamaradas, 1, reason: 'estornuda chispitas');
    expect(Sonidos.pedidos, contains(AjustesBurbujas.sonidosJefes['dragon']));
    final nuevas = juego.burbujas.where((o) => !viejas.contains(o)).toList();
    expect(nuevas, hasLength(AjustesBurbujas.burbujitasPorToqueJefe));
    for (final c in nuevas) {
      expect(c.centro.dy, greaterThan(b.centro.dy - b.radio * 0.2),
          reason: 'salen de la boca (abajo de los ojos)');
    }
    await avanzar(tester, const Duration(seconds: 1));
    expect(juego.llamaradas, 0, reason: 'las chispitas se apagan');
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
