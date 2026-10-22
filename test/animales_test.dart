import 'package:colorear_ninos/juegos/animales/animales_ajustes.dart';
import 'package:colorear_ninos/juegos/animales/animales_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Animales: la voz pregunta quién hace un sonido, cada animal que toca '
      'hace el suyo y al acertar gana una estrella', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: AnimalesJuego()));
    await esperar(tester);

    // Empieza con 2 animales (se ven sus dibujos) y la voz pregunta por uno.
    final ids = nombresCon(tester, 'animal_');
    expect(ids.length, AjustesAnimales.animalesAlEmpezar);
    for (final id in ids) {
      final animal = AjustesAnimales.animales.firstWhere((a) => a.id == id);
      expect(find.text(animal.dibujo), findsOneWidget);
    }
    final pedido = animalPedido();
    expect(ids, contains(pedido.id));
    expect(frases.last, preguntaPor(pedido));

    // Toca el otro: la voz dice cuál es y hace su sonido.
    final otro = AjustesAnimales.animales
        .firstWhere((a) => a.id != pedido.id && ids.contains(a.id));
    await tocarAnimal(tester, otro.id);
    expect(frases.last,
        '${AjustesAnimales.vozError.replaceAll('{animal}', otro.nombre)} ¡${otro.sonido}!');
    expect(estrellas(tester), 0);

    // La orejita repite la pregunta.
    await tester.tap(find.byKey(const ValueKey<String>('repetir')));
    await esperar(tester, vueltas: 2);
    expect(frases.last, preguntaPor(pedido));

    // Toca el correcto: gana una estrella, la voz la felicita y el animal
    // hace su sonido.
    await tocarAnimal(tester, pedido.id);
    expect(estrellas(tester), 1);
    expect(
      AjustesAnimales.vozAcierto.map((f) =>
          '${f.replaceAll('{animal}', pedido.nombre)} ¡${pedido.sonido}!'),
      contains(frases.last),
    );
    // Tocar otra vez mientras festeja no hace nada.
    await tocarAnimal(tester, otro.id);
    expect(estrellas(tester), 1);

    // Después viene otra pregunta, por otro animal.
    await tester.pump(const Duration(milliseconds: 4600));
    await esperar(tester, vueltas: 3);
    expect(animalPedido().id, isNot(pedido.id));

    // Tres aciertos seguidos sin equivocarse: aparece un animal más.
    for (var k = 0; k < AjustesAnimales.aciertosParaSubir; k++) {
      expect(nombresCon(tester, 'animal_').length, 2);
      await acertarAnimal(tester);
    }
    expect(nombresCon(tester, 'animal_').length, 3);

    // Al llegar a 5 aciertos sale la celebración.
    await acertarAnimal(tester);
    expect(estrellas(tester), AjustesAnimales.aciertosParaCelebrar);
    await tester.pump(const Duration(seconds: 1));
    expect(celebracion, findsOneWidget);
    expect(find.text(AjustesAnimales.celebracionLinea2), findsOneWidget);
    expect(frases, contains(AjustesAnimales.vozCelebracion));
    await quitarCelebracion(tester);
    await esperar(tester, vueltas: 2);
    expect(frases.last, preguntaPor(animalPedido()));
    await cerrarPantalla(tester);
  });
}
