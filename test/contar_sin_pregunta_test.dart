import 'package:colorear_ninos/juegos/contar/contar_ajustes.dart';
import 'package:colorear_ninos/juegos/contar/contar_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';
import 'contar_test.dart' show cosaPedida, pregunta;

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      '¿Cuántos hay? (como viene): cuando cuenta todas, la voz dice el '
      'número y termina la ronda, sin preguntar ni botones', (tester) async {
    expect(AjustesContar.preguntarCuantosHay, isFalse,
        reason: 'así viene: sin la pregunta');
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: ContarJuego(semilla: 5)));
    await esperar(tester);

    for (var ronda = 1; ronda <= 3; ronda++) {
      final cosa = cosaPedida();
      final n = cosasParaContar(tester);
      expect(botonesContar(tester), isEmpty, reason: 'no hay botones');

      // Toca cada una: la voz cuenta.
      for (var i = 0; i < n; i++) {
        await tester.tap(find.byKey(ValueKey<String>('cosa_$i')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(frases.last, AjustesContar.numeros[i]);
      }

      // Al terminar, dice cuántas hay (sin preguntar) y gana la estrella.
      await tester.pump(const Duration(milliseconds: 1000));
      await esperar(tester, vueltas: 2);
      expect(frases, isNot(contains(pregunta(cosa))));
      expect(botonesContar(tester), isEmpty);
      expect(estrellas(tester), ronda);
      final unaSola = n == 1;
      final numero = unaSola
          ? (cosa.femenino ? 'una' : 'un')
          : AjustesContar.numeros[n - 1];
      expect(
        AjustesContar.vozAcierto.map((f) => f
            .replaceAll('{numero}', numero)
            .replaceAll('{cosas}', unaSola ? cosa.una : cosa.varias)),
        contains(frases.last),
        reason: 'la voz dice el número',
      );

      // Y viene otra ronda, con otra cosa.
      await tester.pump(const Duration(milliseconds: 4000));
      await esperar(tester, vueltas: 4);
      expect(cosaPedida(), isNot(cosa));
      expect(find.byKey(const ValueKey<String>('numero_0')), findsNothing);
    }
    await cerrarPantalla(tester);
  });
}
