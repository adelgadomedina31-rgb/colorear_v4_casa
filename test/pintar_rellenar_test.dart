import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'al terminar, los puntitos sin pintar se rellenan con el color de su '
      'zona, sin tocar lo pintado ni las zonas que siguen en blanco',
      (tester) async {
    final dibujo = Dibujo.desdeTexto(
      '{"id":"rellenar","regiones":['
      '{"id":"fondo","path":"M 0 0 L 1000 0 L 1000 1000 L 0 1000 Z"},'
      '{"id":"esquina","path":"M 800 800 L 950 800 L 950 950 L 800 950 Z"}]}',
    );
    const rojo = Color(0xFFE53935);
    const azul = Color(0xFF1E88E5);
    await tester.runAsync(() async {
      await Pintura.abrir(dibujo);
      // Una mancha roja grande en el fondo (las esquinas quedan en blanco)
      // y una azul chiquita.
      Pintura.hornear(
        dibujo,
        <Trazo>[
          Trazo(
              region: 0,
              color: rojo,
              radio: 480,
              semilla: 0,
              inicio: const Offset(500, 500)),
          Trazo(
              region: 0,
              color: azul,
              radio: 60,
              semilla: 0,
              inicio: const Offset(300, 300)),
        ],
        Pintura.version(dibujo.id),
      );
    });
    final colores = <Color>[rojo, azul];
    Future<Medida> medirAhora() async => (await tester.runAsync(
        () => Pintura.medirColores(dibujo, const <Trazo>[], colores)))!;

    final antes = await medirAhora();
    expect(antes.pintado, lessThan(0.8));
    expect(antes.completo, isFalse);

    await tester.runAsync(() => Pintura.rellenarPuntitos(dibujo));
    final despues = await medirAhora();
    // El fondo quedó entero: rojo, menos la mancha azul (que sigue ahí).
    // La esquina, que nunca se pintó, sigue en blanco.
    const esquina = 150 * 150 / 1000000;
    expect(despues.pintado, closeTo(1 - esquina, 0.01));
    expect(despues.colores[1], closeTo(3.1416 * 60 * 60 / 1000000, 0.004));
    expect(despues.colores[0], greaterThan(0.95 - esquina));
    expect(despues.completo, isFalse);
    await tester.runAsync(() => Pintura.cerrar(dibujo));
  });
}
