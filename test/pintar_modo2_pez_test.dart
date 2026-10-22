import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
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
      'Modo 2: todo el pez de un solo color, ese color no pinta el agua, y '
      'al terminar el pez pide otro color', (tester) async {
    sinAvisosDeSonido();
    await ModoPintado.cambiar(ModoPintado.porObjeto);
    final pez = leerDibujo('pez.json');
    final lienzo = await abrirPantalla(tester, <Dibujo>[pez]);
    final paleta = PaletaDibujo.enMemoria('pez')!;
    // Naranja, Amarillo, Celeste, Azul, Verde.
    expect(
      <String>[for (final c in PaletaDibujo.coloresDe(pez)) c.nombre],
      <String>['Naranja', 'Amarillo', 'Celeste', 'Azul', 'Verde'],
    );
    Future<void> tocarZona(String zona) =>
        tocar(tester, lienzo, pez, puntoDe(pez, zona));
    Future<bool> pintada(String zona) async =>
        await pintadoEn(tester, pez, puntoDe(pez, zona)) > 0;

    // El agua, celeste.
    await elegirColor(tester, 2);
    await tocarZona('agua');
    expect(await pintada('agua'), isTrue);
    expect(paleta.usadoEnResto('Celeste'), isTrue);

    // El celeste ya es del agua: no pinta el pez.
    await esperarAvisos(tester);
    frases.clear();
    await tocarZona('cuerpo');
    expect(await pintada('cuerpo'), isFalse);
    expect(paleta.colorPersonaje, isNull);
    expect(frases, <String>['¡Elige otro color para el pez!']);

    // El pez, naranja.
    await elegirColor(tester, 0);
    await tocarZona('cuerpo');
    expect(await pintada('cuerpo'), isTrue);
    expect(paleta.colorPersonaje, 'Naranja');

    // El naranja es del pez: no pinta el agua ni las burbujas.
    await esperarAvisos(tester);
    frases.clear();
    await tocarZona('burbuja1');
    expect(await pintada('burbuja1'), isFalse);
    expect(paleta.usadoEnResto('Naranja'), isFalse);
    expect(frases, <String>['¡Este color es para el pez!']);

    // Con otro color no se pinta ninguna parte del pez...
    await elegirColor(tester, 1); // Amarillo
    frases.clear();
    await tocarZona('cola');
    expect(await pintada('cola'), isFalse);
    expect(frases, <String>['¡Pinta el pez con el naranja!']);
    // ...pero sí lo demás, como las burbujas (pueden ser de varios colores).
    await tocarZona('burbuja1');
    expect(await pintada('burbuja1'), isTrue);
    expect(paleta.usadoEnResto('Amarillo'), isTrue);

    // Se pinta todo el pez de naranja: al terminar, la voz pide otro color
    // y el naranja se suelta (no se elige otro solo).
    await elegirColor(tester, 0);
    frases.clear();
    var toques = 0;
    for (final zona in <String>[
      'cuerpo',
      'cola',
      'aleta_arriba',
      'aleta_abajo'
    ]) {
      for (final p in puntosDe(pez, zona, paso: 60)) {
        if (paleta.personajeTerminado) break;
        await tester.tapAt(enPantalla(lienzo, pez, p));
        toques++;
        await esperar(tester, vueltas: 2);
      }
    }
    await esperar(tester);
    expect(paleta.personajeTerminado, isTrue, reason: '$toques toques');
    expect(frases, contains(AjustesPintar.vozEligeOtroParaSeguir));
    expect(colorElegido(tester), isNull);
    expect(hayTarritoElegido(), isFalse);
    expect(celebracion, findsNothing);
    final medida = await medir(tester, pez, personaje: <int>{
      for (final parte in AjustesPintar.personajes['pez']!.partes)
        zona(pez, parte),
    });
    expect(medida.personaje,
        greaterThanOrEqualTo(AjustesPintar.personajeTerminado));
    expect(medida.enPersonaje[0], greaterThan(0.9));

    // Si vuelve al naranja, no pinta el agua...
    await elegirColor(tester, 0);
    frases.clear();
    await tocar(tester, lienzo, pez, puntosDe(pez, 'agua').last);
    expect(await pintadoEn(tester, pez, puntosDe(pez, 'agua').last), 0);
    expect(frases, <String>[AjustesPintar.vozEligeOtroParaSeguir]);
    // ...pero sí puede retocar el pez.
    await esperarHorneado(tester);
    final antes = Pintura.completa('pez');
    await tocarZona('cuerpo');
    await esperarHorneado(tester);
    expect(identical(Pintura.completa('pez'), antes), isFalse);

    // Borrar lo pintado deja todo como nuevo.
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await esperar(tester);
    final nueva = PaletaDibujo.enMemoria('pez')!;
    expect(nueva.colorPersonaje, isNull);
    expect(nueva.usadoEnResto('Celeste'), isFalse);
    expect(nueva.personajeTerminado, isFalse);
    await cerrarPantalla(tester);
  });
}
