import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'El Pulpo Burbuja nada a empujoncitos; al tocarlo sale disparado y '
      'suelta burbujitas para atrás', (tester) async {
    final b = await abrirJefe(tester, TipoJefe.pulpo);
    final juego = juegoBurbujas(tester);

    // Nada a empujoncitos: a ratos va rápido y a ratos casi quieto.
    final pasos = <double>[];
    var antes = b.centro;
    for (var k = 0; k < 75; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      pasos.add((b.centro - antes).distance);
      antes = b.centro;
    }
    pasos.sort();
    expect(pasos[pasos.length * 9 ~/ 10],
        greaterThan(pasos[pasos.length ~/ 10] * 3),
        reason: 'empujoncitos');

    // Al tocarlo sale disparado, y las burbujitas salen para atrás.
    final viejas = juego.burbujas.toSet();
    await tocarBurbuja(tester, b);
    expect(b.apurado(juego.ahora), isTrue);
    final nuevas = juego.burbujas.where((o) => !viejas.contains(o)).toList();
    expect(nuevas, hasLength(AjustesBurbujas.burbujitasPorToqueJefe));
    for (final c in nuevas) {
      final va = math.cos(c.rumbo) * math.cos(b.rumbo) +
          math.sin(c.rumbo) * math.sin(b.rumbo);
      expect(va, lessThan(0), reason: 'para el otro lado que el pulpo');
    }
    await pasarDeNivel(tester);
    await cerrarPantalla(tester);
  });
}
