import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'la celebración sale solo cuando TODO el dibujo está pintado (el 100%), '
      'aunque falte una parte chiquita', (tester) async {
    sinAvisosDeSonido();
    // Un fondo grande y un botón redondo chiquito en el medio (un 1,5%).
    final dibujo = Dibujo.desdeTexto(
      '{"id":"boton","regiones":['
      '{"id":"fondo","path":"M 0 0 L 1000 0 L 1000 1000 L 0 1000 Z"},'
      '{"id":"boton","path":"M 430 500 A 70 70 0 1 0 570 500 '
      'A 70 70 0 1 0 430 500 Z"}]}',
    );
    final lienzo = await abrirPantalla(tester, <Dibujo>[dibujo]);
    final boton = puntoDe(dibujo, 'boton');

    // Pinta solo el fondo (sin tocar el botón).
    final puntos = <Offset>[
      for (final p in cuadricula)
        if ((p - boton).distance > 150) p,
      for (final y in const <double>[350, 650])
        for (final x in const <double>[350, 650]) Offset(x, y),
      const Offset(500, 380),
      const Offset(500, 620),
      const Offset(380, 500),
      const Offset(620, 500),
    ];
    for (var vuelta = 0; vuelta < 3; vuelta++) {
      for (final p in puntos) {
        if (colorElegido(tester) == null) await elegirColor(tester, 0);
        await tester.tapAt(enPantalla(lienzo, dibujo, p));
        await esperar(tester, vueltas: 3);
      }
    }
    final antes = await medir(tester, dibujo);
    expect(antes.pintado, greaterThan(0.95)); // con el 95% ya habría salido
    expect(antes.completo, isFalse);
    expect(celebracion, findsNothing);

    // Pinta el botón: ahora sí está todo pintado.
    if (colorElegido(tester) == null) await elegirColor(tester, 1);
    await tocar(tester, lienzo, dibujo, boton);
    await esperarHorneado(tester);
    expect(celebracion, findsOneWidget);
    final despues = await medir(tester, dibujo);
    expect(despues.completo, isTrue);
    await cerrarPantalla(tester);
  });
}
