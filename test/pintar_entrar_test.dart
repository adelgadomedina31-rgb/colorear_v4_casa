import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'al entrar a un dibujo no hay color elegido: la voz pide uno y los '
      'tarritos saltan', (tester) async {
    sinAvisosDeSonido();
    final sol = leerDibujo('sol.json');
    final luna = leerDibujo('luna.json');
    final lienzo = await abrirPantalla(tester, <Dibujo>[sol, luna]);
    final cara = puntoDe(sol, 'cara');

    // Los 5 colores del sol, ninguno elegido.
    expect(tarritosVisibles(tester).length, 5);
    expect(colorElegido(tester), isNull);
    expect(hayTarritoElegido(), isFalse);
    expect(frases, <String>[AjustesPintar.vozEligeUnColor]);
    expect(await tarritosSaltan(tester), isTrue);

    // Tocar el dibujo sin color no pinta nada...
    await tocar(tester, lienzo, sol, cara);
    await esperarHorneado(tester);
    expect(Pintura.completa('sol'), isNull);
    // ...y si insiste, la voz se lo vuelve a pedir.
    await esperarAvisos(tester);
    await tocar(tester, lienzo, sol, cara);
    await esperarHorneado(tester);
    expect(Pintura.completa('sol'), isNull);
    expect(frases,
        <String>[AjustesPintar.vozEligeUnColor, AjustesPintar.vozEligeUnColor]);

    // Elige el amarillo: la voz lo nombra, los tarritos dejan de saltar y
    // ya pinta.
    await elegirColor(tester, 0);
    expect(frases.last, 'Amarillo');
    expect(colorElegido(tester), PaletaDibujo.coloresDe(sol)[0].color);
    expect(hayTarritoElegido(), isTrue);
    expect(await tarritosSaltan(tester), isFalse);
    await tocar(tester, lienzo, sol, cara);
    expect(await pintadoEn(tester, sol, cara), greaterThan(0));

    // Borrar lo pintado deja el color elegido (y no dice nada).
    frases.clear();
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await esperar(tester);
    expect(Pintura.completa('sol'), isNull);
    expect(colorElegido(tester), isNotNull);
    expect(frases, isEmpty);

    // En el siguiente dibujo hay que elegir otra vez (nunca se elige solo).
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await esperar(tester);
    expect(colorElegido(tester), isNull);
    expect(hayTarritoElegido(), isFalse);
    expect(frases, <String>[AjustesPintar.vozEligeUnColor]);

    // Y al volver al sol, también.
    await esperarAvisos(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await esperar(tester);
    expect(colorElegido(tester), isNull);
    expect(frases,
        <String>[AjustesPintar.vozEligeUnColor, AjustesPintar.vozEligeUnColor]);
    await cerrarPantalla(tester);
  });
}
