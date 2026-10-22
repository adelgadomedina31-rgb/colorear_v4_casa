import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/mundos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Cada nivel pasa en otro mundo, con su mascota: sopla burbujas, salta '
      'y se ríe si la tocas, y aplaude al pasar de nivel', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 1, semilla: 12)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);

    void revisarMascota() {
      final m = juego.mascota!;
      expect(m.mundo, juego.mundo);
      expect(AjustesBurbujas.mascotas[juego.mundo.name], contains(m.emoji));
    }

    expect(Mundo.deLosAjustes, contains(juego.mundo));
    revisarMascota();

    // La mascota sopla burbujas (salen de su boca y suben).
    var sopladas = 0;
    for (var k = 0; k < 300 && sopladas == 0; k++) {
      await tester.pump(const Duration(milliseconds: 40));
      sopladas = juego.burbujas.where((b) => b.soplada).length;
    }
    expect(sopladas, greaterThan(0));
    final soplada = juego.burbujas.firstWhere((b) => b.soplada);
    final y = soplada.centro.dy;
    await avanzar(tester, const Duration(milliseconds: 400));
    expect(soplada.centro.dy, lessThan(y), reason: 'sube');

    // Tocar la mascota: salta y se ríe (no revienta nada).
    final m = juego.mascota!;
    final zona = zonaBurbujas(tester);
    final lugar = m.lugar(zona.size);
    final libre = juego.burbujas.every((b) =>
        (b.centro - lugar.center).distance > b.radio * 1.15 + lugar.width);
    if (libre) {
      final hechas = juego.reventadas;
      await tester.tapAt(zona.topLeft + lugar.center);
      await tester.pump(const Duration(milliseconds: 40));
      expect(m.salto, greaterThan(0));
      expect(juego.reventadas, hechas);
    }

    // Pasa de nivel: la mascota aplaude, y el nivel 2 es en otro mundo (la
    // voz dice cuál, con el nombre de la mascota).
    final mundos = <Mundo>[juego.mundo];
    await reventarTodas(tester);
    await avanzar(tester, const Duration(milliseconds: 600));
    expect(juego.mascota!.aplaudiendo(juego.mascota!.aplaudeDesde), isTrue);
    for (var nivel = 2; nivel <= 4; nivel++) {
      for (var k = 0; k < 200 && juego.nivel < nivel; k++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(juego.nivel, nivel);
      expect(juego.mundo, isNot(mundos.last), reason: 'cambió de mundo');
      mundos.add(juego.mundo);
      revisarMascota();
      if (juego.plan!.jefe == null && juego.plan!.nuevos.isEmpty) {
        final nombre = AjustesBurbujas.nombresMascotas[juego.mascota!.emoji]!;
        expect(frases.last, contains(nombre));
      }
      if (nivel < 4) await reventarTodas(tester);
    }
    await cerrarPantalla(tester);
  });
}
