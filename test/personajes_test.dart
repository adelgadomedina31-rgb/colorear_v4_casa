import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/personaje_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:flutter_test/flutter_test.dart';

List<Dibujo> _dibujosDeLaApp() {
  final indice = jsonDecode(
    File('assets/drawings/indice.json').readAsStringSync(),
  ) as List<dynamic>;
  return <Dibujo>[
    for (final archivo in indice.cast<String>())
      Dibujo.desdeTexto(File('assets/drawings/$archivo').readAsStringSync()),
  ];
}

/// Una mancha gigante que llena toda la zona [region].
Trazo _llenar(Dibujo d, int region, Color color) => Trazo(
      region: region,
      color: color,
      radio: 1500,
      semilla: 0,
      inicio: d.limites(region).center,
    );

String _cuadro(String id, double x1, double y1, double x2, double y2) =>
    '{"id":"$id","path":"M $x1 $y1 L $x2 $y1 L $x2 $y2 L $x1 $y2 Z"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada dibujo de la app tiene su personaje y sus partes existen', () {
    final dibujos = _dibujosDeLaApp();
    for (final d in dibujos) {
      // En pintar_ajustes.dart o en el mismo dibujo (como las casas).
      final definido = AjustesPintar.personajes[d.id] ?? d.personaje;
      expect(definido, isNotNull, reason: 'falta el personaje de "${d.id}"');
      final ids = <String>{for (final r in d.regiones) r.id};
      for (final parte in definido!.partes) {
        expect(ids, contains(parte), reason: '${d.id}: no hay zona "$parte"');
      }
      final personaje = PersonajeDibujo.de(d);
      expect(personaje.nombre, definido.nombre);
      expect(personaje.zonas.length, definido.partes.length, reason: d.id);
      // Queda algo para el fondo y los detalles.
      expect(personaje.zonas.length, lessThan(d.regiones.length), reason: d.id);
    }
    // No sobra el personaje de un dibujo que no existe.
    expect(<String>{for (final d in dibujos) d.id},
        containsAll(AjustesPintar.personajes.keys));
  });

  test(
      'un dibujo agregado sin personaje: es lo que no toca los bordes, '
      'sin los detalles de adentro', () {
    final d = Dibujo.desdeTexto('{"id":"foto_pez","regiones":['
        '${_cuadro('agua', 0, 0, 1000, 1000)},'
        '${_cuadro('cuerpo', 200, 300, 700, 700)},'
        '${_cuadro('cola', 700, 350, 900, 650)},'
        '${_cuadro('ojo', 280, 380, 340, 440)},'
        '${_cuadro('mancha', 450, 500, 550, 600)}]}');
    final personaje = PersonajeDibujo.de(d);
    expect(personaje.existe, isTrue);
    expect(personaje.nombre, AjustesPintar.personajeSinNombre);
    expect(personaje.zonas, <int>{1, 2}); // el cuerpo y la cola
  });

  test('si todo toca los bordes, el fondo es la zona más grande', () {
    final d = Dibujo.desdeTexto('{"id":"foto_mitades","regiones":['
        '${_cuadro('arriba', 0, 0, 1000, 300)},'
        '${_cuadro('abajo', 0, 300, 1000, 1000)}]}');
    expect(PersonajeDibujo.de(d).zonas, <int>{0});
  });

  test('con una sola zona no hay personaje (se pinta libre)', () {
    final d = Dibujo.desdeTexto(
        '{"id":"foto_una","regiones":[${_cuadro('todo', 0, 0, 1000, 1000)}]}');
    expect(PersonajeDibujo.de(d).existe, isFalse);
  });

  test('un dibujo agregado puede traer su personaje en el JSON', () {
    final zonas = '${_cuadro('cielo', 0, 0, 1000, 1000)},'
        '${_cuadro('cara', 300, 300, 700, 700)},'
        '${_cuadro('rayo', 450, 100, 550, 250)}';
    final conNombre = Dibujo.desdeTexto('{"id":"foto_sol","regiones":[$zonas],'
        '"personaje":{"nombre":"el sol","partes":["cara","rayo"]}}');
    final sol = PersonajeDibujo.de(conNombre);
    expect(sol.nombre, 'el sol');
    expect(sol.zonas, <int>{1, 2});

    final soloPartes = Dibujo.desdeTexto(
        '{"id":"foto_sol2","regiones":[$zonas],"personaje":["cara"]}');
    final cara = PersonajeDibujo.de(soloPartes);
    expect(cara.nombre, AjustesPintar.personajeSinNombre);
    expect(cara.zonas, <int>{1});
  });

  testWidgets(
      'en cada dibujo de la app, pintar el personaje entero lo deja '
      '"terminado", y pintar todo llega a la celebración', (tester) async {
    const rojo = Color(0xFFE53935);
    const azul = Color(0xFF1E88E5);
    for (final d in _dibujosDeLaApp()) {
      final personaje = PersonajeDibujo.de(d);
      await tester.runAsync(() async {
        await Pintura.abrir(d);
        // Solo el personaje, rojo.
        Pintura.hornear(
          d,
          <Trazo>[for (final i in personaje.zonas) _llenar(d, i, rojo)],
          Pintura.version(d.id),
        );
        final soloPersonaje = await Pintura.medirColores(
            d, const <Trazo>[], const <Color>[rojo, azul],
            personaje: personaje.zonas);
        expect(soloPersonaje!.personaje,
            greaterThanOrEqualTo(AjustesPintar.personajeTerminado),
            reason: d.id);
        // (Los bordes, mezclados con el blanco, no cuentan como "rojo"; en
        // personajes chiquitos, como el perrito de la casita, pesan más.)
        expect(soloPersonaje.enPersonaje[0], greaterThan(0.8), reason: d.id);
        // Queda bastante para el fondo: todavía no se celebra.
        expect(soloPersonaje.pintado, lessThan(0.9), reason: d.id);

        // El resto, azul: el dibujo queda terminado.
        Pintura.hornear(
          d,
          <Trazo>[
            for (var i = 0; i < d.regiones.length; i++)
              if (!personaje.contiene(i)) _llenar(d, i, azul),
          ],
          Pintura.version(d.id),
        );
        final todo = await Pintura.medirColores(
            d, const <Trazo>[], const <Color>[rojo, azul],
            personaje: personaje.zonas);
        if (AjustesPintar.porcentajeCelebracion >= 0.999) {
          expect(todo!.completo, isTrue, reason: d.id);
        } else {
          expect(todo!.pintado,
              greaterThanOrEqualTo(AjustesPintar.porcentajeCelebracion),
              reason: d.id);
        }
        expect(todo.personaje, greaterThanOrEqualTo(0.97), reason: d.id);
        expect(todo.fueraDelPersonaje[0], lessThan(0.01), reason: d.id);
        await Pintura.cerrar(d);
      });
    }
  });
}
