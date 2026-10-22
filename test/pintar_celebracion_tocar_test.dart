import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets('la celebración se quita tocándola', (tester) async {
    sinAvisosDeSonido();
    final dibujo = cuadrado('tocar');
    final lienzo = await abrirPantalla(tester, <Dibujo>[dibujo]);
    final fiesta = celebracion;
    await pintarHastaCelebrar(tester, lienzo, dibujo);
    expect(fiesta, findsOneWidget);
    // Un toque apurado justo al aparecer no la quita.
    await tester.tap(fiesta);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(fiesta, findsOneWidget);
    await quitarCelebracion(tester);
    expect(fiesta, findsNothing);
    await cerrarPantalla(tester);
  });
}
