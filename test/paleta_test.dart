import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dibujo _dibujo(String id, {List<String> colores = const <String>[]}) => Dibujo(
      id: id,
      nombre: id,
      lado: 1000,
      regiones: <Region>[],
      detalles: <Detalle>[],
      colores: colores,
    );

List<String> _nombres(List<ColorConNombre> lista) =>
    <String>[for (final c in lista) c.nombre];

/// Una mancha gigante que llena toda la zona [region].
Trazo _llenar(int region, Color color) => Trazo(
      region: region,
      color: color,
      radio: 1500,
      semilla: 0,
      inicio: const Offset(500, 500),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('colores de cada dibujo', () {
    test('los dibujos de la app tienen su paleta de hasta 5 colores', () {
      final indice = jsonDecode(
        File('assets/drawings/indice.json').readAsStringSync(),
      ) as List<dynamic>;
      for (final archivo in indice.cast<String>()) {
        final datos = jsonDecode(
          File('assets/drawings/$archivo').readAsStringSync(),
        ) as Map<String, dynamic>;
        final id = datos['id'] as String;
        // En pintar_ajustes.dart o en el mismo dibujo (como las casas).
        final nombres = AjustesPintar.paletasDibujos[id] ??
            (datos['colores'] as List<dynamic>?)?.cast<String>();
        expect(nombres, isNotNull, reason: 'falta la paleta de "$id"');
        final colores = PaletaDibujo.coloresDe(_dibujo(id,
            colores: AjustesPintar.paletasDibujos[id] == null
                ? nombres!
                : const <String>[]));
        // Todos los nombres existen en la lista de colores.
        expect(colores.length, nombres!.length, reason: id);
        expect(colores.length, inInclusiveRange(2, 5), reason: id);
      }
    });

    test('un dibujo con "colores" en su JSON usa esos (con o sin tilde)', () {
      final d = Dibujo.desdeTexto(
        '{"id":"foto_gato","regiones":[{"path":"M 0 0 L 10 0 L 10 10 Z"}],'
        '"colores":["naranja","MARRON","Rosado","Celeste","Verde","Rojo"]}',
      );
      expect(_nombres(PaletaDibujo.coloresDe(d)),
          <String>['Naranja', 'Marrón', 'Rosado', 'Celeste', 'Verde']);
    });

    test('con un solo color se agrega otro (para poder cambiar)', () {
      final d = Dibujo.desdeTexto(
        '{"id":"foto_rojo","regiones":[{"path":"M 0 0 L 10 0 L 10 10 Z"}],'
        '"colores":["Rojo"]}',
      );
      expect(_nombres(PaletaDibujo.coloresDe(d)), <String>['Rojo', 'Amarillo']);
    });

    test('sin paleta propia usa la de por defecto', () {
      expect(_nombres(PaletaDibujo.coloresDe(_dibujo('foto_nuevo'))),
          AjustesPintar.paletaPorDefecto);
    });
  });

  group('modo de pintar', () {
    tearDown(() => ModoPintado.cambiar(ModoPintado.total));

    test('empieza en el Modo 1 y el elegido queda guardado', () async {
      expect(AjustesPintar.modoPorDefecto, ModoPintado.total);
      expect(ModoPintado.actual, ModoPintado.total);
      await ModoPintado.cambiar(ModoPintado.porObjeto);
      expect(ModoPintado.actual, ModoPintado.porObjeto);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('modo_pintado'), 2);
      // Un número que no es un modo deja el Modo 1.
      await ModoPintado.cambiar(7);
      expect(ModoPintado.actual, ModoPintado.total);
    });

    test('al abrir la app se lee el modo guardado', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'modo_pintado': 2,
      });
      await ModoPintado.cargar();
      expect(ModoPintado.actual, ModoPintado.porObjeto);
    });
  });

  group('cada dibujo recuerda lo suyo', () {
    test('lo de un dibujo no se mezcla con otro y se guarda en el celular',
        () async {
      final pez = await PaletaDibujo.cargar('recordar_pez');
      final otro = await PaletaDibujo.cargar('recordar_otro');
      pez.marcarRecomendado('Rojo');
      pez.fijarColorPersonaje('Naranja');
      pez.usarEnResto('Celeste');
      pez.marcarPersonajeTerminado();
      pez.marcarCelebrado();
      expect(pez.recomendado('Rojo'), isTrue);
      expect(pez.recomendado('Azul'), isFalse);
      expect(pez.colorPersonaje, 'Naranja');
      expect(pez.usadoEnResto('Celeste'), isTrue);
      expect(pez.usadoEnResto('Naranja'), isFalse);
      expect(otro.recomendado('Rojo'), isFalse);
      expect(otro.colorPersonaje, isNull);
      expect(otro.personajeTerminado, isFalse);
      expect(otro.celebrado, isFalse);

      await PaletaDibujo.guardarPendientes();
      final prefs = await SharedPreferences.getInstance();
      final guardado =
          jsonDecode(prefs.getString('paleta_recordar_pez')!) as Map;
      expect(guardado['recomendados'], <String>['Rojo']);
      expect(guardado['colorPersonaje'], 'Naranja');
      expect(guardado['coloresResto'], <String>['Celeste']);
      expect(guardado['personajeTerminado'], isTrue);
      expect(guardado['celebrado'], isTrue);
    });

    test('lo guardado se lee al abrir la app', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'paleta_leido': '{"recomendados":["Verde"],"colorPersonaje":"Azul",'
            '"coloresResto":["Rojo","Amarillo"],"personajeTerminado":true,'
            '"celebrado":true}',
      });
      final paleta = await PaletaDibujo.cargar('leido');
      expect(paleta.recomendado('Verde'), isTrue);
      expect(paleta.colorPersonaje, 'Azul');
      expect(paleta.usadoEnResto('Rojo'), isTrue);
      expect(paleta.usadoEnResto('Amarillo'), isTrue);
      expect(paleta.personajeTerminado, isTrue);
      expect(paleta.celebrado, isTrue);
    });

    test(
        'lo que guardó la v8 se lee sin problema (los colores ya no se '
        'acaban)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'paleta_v8': '{"gasto":{"Rojo":0.71},"acabados":["Rojo"],'
            '"celebrado":true}',
        'paleta_danado': 'esto no es un JSON',
      });
      final vieja = await PaletaDibujo.cargar('v8');
      expect(vieja.celebrado, isTrue);
      expect(vieja.recomendado('Rojo'), isFalse);
      expect(vieja.colorPersonaje, isNull);
      final danada = await PaletaDibujo.cargar('danado');
      expect(danada.celebrado, isFalse);
      expect(danada.colorPersonaje, isNull);
    });

    test('borrar lo pintado la deja como nueva y borra lo guardado', () async {
      final vieja = await PaletaDibujo.cargar('borrar');
      vieja.marcarRecomendado('Amarillo');
      vieja.fijarColorPersonaje('Amarillo');
      vieja.usarEnResto('Celeste');
      vieja.marcarCelebrado();
      await PaletaDibujo.guardarPendientes();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('paleta_borrar'), isNotNull);

      Pintura.borrarId('borrar');
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString('paleta_borrar'), isNull);
      final nueva = PaletaDibujo.enMemoria('borrar')!;
      expect(identical(nueva, vieja), isFalse);
      expect(nueva.recomendado('Amarillo'), isFalse);
      expect(nueva.colorPersonaje, isNull);
      expect(nueva.usadoEnResto('Celeste'), isFalse);
      expect(nueva.celebrado, isFalse);

      // Algo que llegue tarde para la paleta vieja ya no se guarda.
      vieja.usarEnResto('Rojo');
      await PaletaDibujo.guardarPendientes();
      expect(prefs.getString('paleta_borrar'), isNull);
    });
  });

  testWidgets('se mide cuánto del dibujo cubre cada color', (tester) async {
    await tester.runAsync(() async {
      // Un fondo que cubre todo y un cuadro encima en la mitad izquierda.
      final d = Dibujo.desdeTexto(
        '{"id":"medida","regiones":['
        '{"id":"fondo","path":"M 0 0 L 1000 0 L 1000 1000 L 0 1000 Z"},'
        '{"id":"cuadro","path":"M 0 0 L 500 0 L 500 1000 L 0 1000 Z"}]}',
      );
      const rojo = Color(0xFFE53935);
      const azul = Color(0xFF1E88E5);
      const amarillo = Color(0xFFFDD835);
      // Manchas gigantes: el rojo llena el cuadro y el azul el fondo (que
      // queda tapado por el cuadro en la mitad izquierda).
      final medida = await Pintura.medirColores(
        d,
        <Trazo>[_llenar(1, rojo), _llenar(0, azul)],
        const <Color>[rojo, azul, amarillo],
      );
      expect(medida, isNotNull);
      expect(medida!.colores[0], closeTo(0.5, 0.03));
      expect(medida.colores[1], closeTo(0.5, 0.03));
      expect(medida.colores[2], 0);
      // Todo el dibujo está pintado.
      expect(medida.pintado, closeTo(1.0, 0.02));
      expect(Pintura.fraccionPintable('medida'), closeTo(1.0, 0.01));

      // Solo el azul, en el fondo: cubre la mitad derecha.
      final soloAzul = await Pintura.medirColores(
        d,
        <Trazo>[_llenar(0, azul)],
        const <Color>[rojo, azul],
      );
      expect(soloAzul!.colores[0], 0);
      expect(soloAzul.colores[1], closeTo(0.5, 0.03));
      // Lo pintado cuenta igual aunque el color no esté en la paleta.
      expect(soloAzul.pintado, closeTo(0.5, 0.03));
      final sinPaleta = await Pintura.medirColores(
        d,
        <Trazo>[_llenar(0, azul)],
        const <Color>[rojo],
      );
      expect(sinPaleta!.colores[0], 0);
      expect(sinPaleta.pintado, closeTo(0.5, 0.03));
    });
  });

  testWidgets('se mide cuánto del personaje está pintado y de qué color',
      (tester) async {
    await tester.runAsync(() async {
      // El agua (todo), el pez (un cuadro en el medio) y un ojo encima del
      // pez. El personaje es solo el pez: el ojo es un detalle.
      final d = Dibujo.desdeTexto(
        '{"id":"medida_pez","regiones":['
        '{"id":"agua","path":"M 0 0 L 1000 0 L 1000 1000 L 0 1000 Z"},'
        '{"id":"pez","path":"M 250 250 L 750 250 L 750 750 L 250 750 Z"},'
        '{"id":"ojo","path":"M 300 300 L 400 300 L 400 400 L 300 400 Z"}]}',
      );
      const naranja = Color(0xFFFB8C00);
      const celeste = Color(0xFF00ACC1);
      const colores = <Color>[naranja, celeste];
      const personaje = <int>{1};

      final vacio = await Pintura.medirColores(d, const <Trazo>[], colores,
          personaje: personaje);
      expect(vacio!.personaje, 0);

      // Solo el agua, celeste: el pez sigue sin pintar.
      final soloAgua = await Pintura.medirColores(
          d, <Trazo>[_llenar(0, celeste)], colores,
          personaje: personaje);
      expect(soloAgua!.personaje, lessThan(0.02));
      expect(soloAgua.fueraDelPersonaje[1], closeTo(0.75, 0.02));
      expect(soloAgua.enPersonaje[1], lessThan(0.02));

      // El pez naranja (el ojo no cuenta: es un detalle).
      final conPez = await Pintura.medirColores(
          d, <Trazo>[_llenar(0, celeste), _llenar(1, naranja)], colores,
          personaje: personaje);
      expect(conPez!.personaje, greaterThan(AjustesPintar.personajeTerminado));
      expect(conPez.enPersonaje[0], greaterThan(0.95));
      expect(conPez.enPersonaje[1], lessThan(0.02));
      expect(conPez.fueraDelPersonaje[0], lessThan(0.01));
      expect(conPez.fueraDelPersonaje[1], closeTo(0.75, 0.02));
      // Falta el ojo: casi todo, pero no todo, está pintado.
      expect(conPez.pintado, closeTo(0.99, 0.01));
    });
  });
}
