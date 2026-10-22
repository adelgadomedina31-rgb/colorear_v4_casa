import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Modo 1: arrastrando el dedo, cuando el color se suelta deja de '
      'pintar', (tester) async {
    sinAvisosDeSonido();
    final dibujo = cuadrado('arrastre');
    final lienzo = await abrirPantalla(tester, <Dibujo>[dibujo]);
    final paleta = PaletaDibujo.enMemoria('arrastre')!;
    Offset punto(double x, double y) =>
        enPantalla(lienzo, dibujo, Offset(x, y));

    await elegirColor(tester, 0); // Rojo
    // Zigzag desde arriba, sin levantar el dedo, hasta cubrir la mitad.
    final dedo = await tester.startGesture(punto(60, 60));
    var fila = 0;
    while (!paleta.recomendado('Rojo') && fila < 8) {
      final y = 60.0 + fila * 125;
      for (var k = 0; k <= 10; k++) {
        final x = fila.isEven ? 60.0 + k * 88 : 940.0 - k * 88;
        await dedo.moveTo(punto(x, y));
        await tester.pump(const Duration(milliseconds: 16));
        if (k % 3 == 0) await esperar(tester, vueltas: 1);
      }
      fila++;
    }
    expect(paleta.recomendado('Rojo'), isTrue);
    expect(fila, lessThan(6));
    await esperar(tester, vueltas: 2);
    expect(colorElegido(tester), isNull);

    // El dedo sigue apoyado y pasa por abajo: ya no pinta.
    for (var k = 0; k <= 10; k++) {
      await dedo.moveTo(punto(60.0 + k * 88, 950));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await dedo.up();
    await esperar(tester);
    for (final x in const <double>[100, 500, 900]) {
      expect(await pintadoEn(tester, dibujo, Offset(x, 950)), 0);
    }
    // Lo de arriba sí quedó pintado.
    expect(
        await pintadoEn(tester, dibujo, const Offset(500, 60)), greaterThan(0));
    await cerrarPantalla(tester);
  });
}
