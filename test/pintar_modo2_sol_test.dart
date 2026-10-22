import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets('Modo 2: los rayos y la cara del sol van todos del mismo color',
      (tester) async {
    sinAvisosDeSonido();
    await ModoPintado.cambiar(ModoPintado.porObjeto);
    final sol = leerDibujo('sol.json');
    final lienzo = await abrirPantalla(tester, <Dibujo>[sol]);
    final paleta = PaletaDibujo.enMemoria('sol')!;
    // Amarillo, Naranja, Celeste, Rojo, Rosado.
    Future<void> tocarZona(String zona) =>
        tocar(tester, lienzo, sol, puntoDe(sol, zona));
    Future<bool> pintada(String zona) async =>
        await pintadoEn(tester, sol, puntoDe(sol, zona)) > 0;

    // Un rayo amarillo: el sol es amarillo.
    await elegirColor(tester, 0);
    await tocarZona('rayo1');
    expect(await pintada('rayo1'), isTrue);
    expect(paleta.colorPersonaje, 'Amarillo');

    // Otro rayo de naranja: no (rayito por rayito no).
    await elegirColor(tester, 1);
    frases.clear();
    await tocarZona('rayo2');
    expect(await pintada('rayo2'), isFalse);
    expect(frases, <String>['¡Pinta el sol con el amarillo!']);
    // La cara tampoco.
    await tocarZona('cara');
    expect(await pintada('cara'), isFalse);
    // El cielo de naranja, sí.
    await tocarZona('cielo');
    expect(await pintada('cielo'), isTrue);
    expect(paleta.usadoEnResto('Naranja'), isTrue);

    // Con amarillo, los otros rayos y la cara sí; el cielo no.
    await elegirColor(tester, 0);
    await tocarZona('rayo5');
    await tocarZona('cara');
    expect(await pintada('rayo5'), isTrue);
    expect(await pintada('cara'), isTrue);
    frases.clear();
    await tocar(tester, lienzo, sol, puntosDe(sol, 'cielo').last);
    expect(await pintadoEn(tester, sol, puntosDe(sol, 'cielo').last), 0);
    expect(frases, <String>['¡Este color es para el sol!']);
    await cerrarPantalla(tester);
  });
}
