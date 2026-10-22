import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'al pintar el 95% del dibujo sale la celebración (aunque sea con un '
      'solo color)', (tester) async {
    sinAvisosDeSonido();
    final dibujo = cuadrado('fiesta');
    final lienzo = await abrirPantalla(tester, <Dibujo>[dibujo]);
    final paleta = PaletaDibujo.enMemoria('fiesta')!;
    final fiesta = celebracion;

    // Con un solo color: al cubrir la mitad se suelta y lo vuelve a elegir.
    final vecesElegido = await pintarHastaCelebrar(tester, lienzo, dibujo);
    expect(vecesElegido, 2);
    expect(fiesta, findsOneWidget);
    expect(paleta.celebrado, isTrue);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text(AjustesPintar.celebracionLinea1), findsOneWidget);
    expect(find.text(AjustesPintar.celebracionLinea2), findsOneWidget);
    expect(
      find.descendant(of: fiesta, matching: find.byIcon(Icons.star_rounded)),
      findsAtLeastNWidgets(12),
    );
    await esperar(tester, vueltas: 2);
    expect(frases, contains(AjustesPintar.vozCelebracion));

    // Se va sola después de unos segundos.
    await tester.pump(const Duration(seconds: AjustesApp.segundosCelebracion));
    await tester.pump(const Duration(seconds: 1));
    expect(fiesta, findsNothing);

    // Seguir pintando no la repite.
    frases.clear();
    if (colorElegido(tester) == null) await elegirColor(tester, 0);
    for (var k = 0; k < 6; k++) {
      await tester.tapAt(enPantalla(lienzo, dibujo, cuadricula[k]));
      await esperar(tester, vueltas: 3);
    }
    expect(fiesta, findsNothing);
    expect(frases, isNot(contains(AjustesPintar.vozCelebracion)));

    // Borrar lo pintado deja que vuelva a salir la próxima vez.
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await esperar(tester);
    expect(PaletaDibujo.enMemoria('fiesta')!.celebrado, isFalse);
    await cerrarPantalla(tester);
  });
}
