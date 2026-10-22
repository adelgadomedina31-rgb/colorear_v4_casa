/// Ayudas para las pruebas de la pantalla de pintar.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_pantalla.dart';
import 'package:colorear_ninos/juegos/pintar/partes/lienzo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que dijo la voz durante la prueba.
final List<String> frases = <String>[];

/// La voz y los sonidos "de mentira": la voz anota lo que diría.
void simularCelular() {
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  mensajero.setMockMethodCallHandler(const MethodChannel('flutter_tts'),
      (llamada) async {
    if (llamada.method == 'speak') frases.add('${llamada.arguments}');
    return 1;
  });
  for (final canal in <String>[
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
  ]) {
    mensajero.setMockMethodCallHandler(MethodChannel(canal), (_) async => null);
  }
}

Dibujo leerDibujo(String archivo) =>
    Dibujo.desdeTexto(File('assets/drawings/$archivo').readAsStringSync());

/// Los tarritos que se ven en la paleta.
Finder get tarritos =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Tarrito');

Iterable<Widget> tarritosVisibles(WidgetTester tester) =>
    tester.widgetList(tarritos);

/// El color con el que pinta el lienzo ahora (null = ninguno elegido).
Color? colorElegido(WidgetTester tester) {
  final color = tester.widget<Lienzo>(find.byType(Lienzo)).color;
  return color.a == 0 ? null : color;
}

/// true si algún tarrito de la paleta se ve elegido (con su estrellita).
bool hayTarritoElegido() => find
    .descendant(
        of: find.byType(Paleta), matching: find.byIcon(Icons.star_rounded))
    .evaluate()
    .isNotEmpty;

/// Deja correr el tiempo de verdad (para las mediciones) y el de la prueba.
Future<void> esperar(WidgetTester tester, {int vueltas = 8}) async {
  for (var k = 0; k < vueltas; k++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Toca el tarrito número [i] y espera a que la voz diga el color (en la
/// prueba la voz nunca avisa que terminó: se espera lo más que espera la
/// app, unos 4 segundos).
Future<void> elegirColor(WidgetTester tester, int i) async {
  await tester.tap(tarritos.at(i));
  await esperar(tester, vueltas: 27);
}

/// Deja pasar el tiempo para que la voz pueda volver a avisar (los avisos
/// no se repiten más de una vez cada 3 segundos).
Future<void> esperarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await esperar(tester, vueltas: 2);
}

/// Los sonidos no existen en la prueba: se ignoran sus avisos.
void sinAvisosDeSonido() {
  final avisoOriginal = FlutterError.onError;
  FlutterError.onError = (detalles) {
    if (detalles.exception is MissingPluginException) return;
    avisoOriginal?.call(detalles);
  };
  addTearDown(() => FlutterError.onError = avisoOriginal);
}

/// Un dibujo de prueba: un solo cuadrado grande (sin paleta en pintar_ajustes.dart,
/// así que usa la de por defecto: Rojo, Amarillo, Verde, Azul y Rosado).
Dibujo cuadrado(String id) => Dibujo.desdeTexto(
      '{"id":"$id","regiones":[{"id":"todo",'
      '"path":"M 0 0 L 1000 0 L 1000 1000 L 0 1000 Z"}]}',
    );

/// Abre la pantalla de pintar y devuelve dónde quedó el dibujo.
Future<Rect> abrirPantalla(WidgetTester tester, List<Dibujo> dibujos) async {
  await tester.binding.setSurfaceSize(const Size(420, 860));
  await tester.pumpWidget(MaterialApp(
    home: PintarPantalla(dibujos: dibujos, indice: 0),
  ));
  await esperar(tester);
  return tester.getRect(find
      .descendant(of: find.byType(Lienzo), matching: find.byType(Listener))
      .first);
}

/// Dónde se ve en la pantalla el punto [p] del dibujo (medido de 0 a 1000).
Offset enPantalla(Rect lienzo, Dibujo d, Offset p) =>
    lienzo.topLeft +
    Offset(lienzo.width * p.dx / d.lado, lienzo.height * p.dy / d.lado);

/// El número de la zona [id] del dibujo.
int zona(Dibujo d, String id) {
  final i = d.regiones.indexWhere((r) => r.id == id);
  expect(i, isNonNegative, reason: 'el dibujo no tiene la zona "$id"');
  return i;
}

/// La zona que se ve en el punto [p] (la de más arriba), o null.
int? zonaEn(Dibujo d, Offset p) {
  for (var i = d.regiones.length - 1; i >= 0; i--) {
    if (d.regiones[i].path.contains(p)) return i;
  }
  return null;
}

/// Puntos donde se ve la zona [id] (sin otra zona encima), cada [paso]
/// unidades, del centro hacia afuera.
List<Offset> puntosDe(Dibujo d, String id, {double paso = 40}) {
  final i = zona(d, id);
  final caja = d.limites(i);
  for (var p = paso; p >= 4; p /= 2) {
    final puntos = <Offset>[];
    for (var y = caja.top + p / 2; y < caja.bottom; y += p) {
      for (var x = caja.left + p / 2; x < caja.right; x += p) {
        final punto = Offset(x, y);
        if (zonaEn(d, punto) == i) puntos.add(punto);
      }
    }
    if (puntos.isEmpty) continue;
    var suma = Offset.zero;
    for (final punto in puntos) {
      suma += punto;
    }
    final centro = suma / puntos.length.toDouble();
    puntos.sort((a, b) =>
        (a - centro).distanceSquared.compareTo((b - centro).distanceSquared));
    return puntos;
  }
  fail('no se ve la zona "$id"');
}

/// Un punto bien adentro de la zona [id].
Offset puntoDe(Dibujo d, String id) => puntosDe(d, id).first;

/// Toca el dibujo en el punto [p] (de 0 a 1000) y espera a que la mancha
/// termine de derramarse.
Future<void> tocar(WidgetTester tester, Rect lienzo, Dibujo d, Offset p) async {
  await tester.tapAt(enPantalla(lienzo, d, p));
  await esperar(tester, vueltas: 6);
}

/// Espera a que las manchas terminen de derramarse y queden horneadas en la
/// imagen del dibujo (el lienzo mide ese tiempo con un reloj de verdad).
Future<void> esperarHorneado(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(
      const Duration(milliseconds: AjustesPintar.duracionDerrame + 150)));
  await esperar(tester, vueltas: 4);
}

/// Mide lo que quedó pintado en el dibujo, con los colores de su paleta, en
/// el mismo orden.
Future<Medida> medir(
  WidgetTester tester,
  Dibujo d, {
  Set<int> personaje = const <int>{},
}) async {
  await esperarHorneado(tester);
  final colores = <Color>[for (final c in PaletaDibujo.coloresDe(d)) c.color];
  final medida = await tester.runAsync(() =>
      Pintura.medirColores(d, const <Trazo>[], colores, personaje: personaje));
  expect(medida, isNotNull);
  return medida!;
}

/// La transparencia (0 a 255) de lo pintado en el punto [p] del dibujo
/// (0 = sin pintar).
Future<int> pintadoEn(WidgetTester tester, Dibujo d, Offset p) async {
  await esperarHorneado(tester);
  final imagen = Pintura.completa(d.id);
  if (imagen == null) return 0;
  final datos = await tester.runAsync(
      () => imagen.toByteData(format: ui.ImageByteFormat.rawStraightRgba));
  final x = (p.dx / d.lado * imagen.width).floor();
  final y = (p.dy / d.lado * imagen.height).floor();
  return datos!.getUint8((y * imagen.width + x) * 4 + 3);
}

/// La celebración de "¡Felicidades!" (si está a la vista).
final Finder celebracion = find.byKey(const ValueKey<String>('celebracion'));

/// Toca la celebración para quitarla y espera a que se vaya.
Future<void> quitarCelebracion(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(celebracion);
  for (var k = 0; k < 8; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Cierra la pantalla y deja terminar las esperas de la voz y los sonidos.
Future<void> cerrarPantalla(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

/// Lo que se prepara antes de cada prueba (empieza en el Modo 1).
Future<void> prepararPrueba() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  frases.clear();
  simularCelular();
  await ModoPintado.cambiar(ModoPintado.total);
}

/// true si los tarritos están saltando (se miran un ratito).
Future<bool> tarritosSaltan(WidgetTester tester) async {
  final alturas = <double>{};
  for (var k = 0; k < 17; k++) {
    alturas.add(tester.getTopLeft(tarritos.first).dy);
    await tester.pump(const Duration(milliseconds: 100));
  }
  return alturas.length > 1;
}

/// Los puntos de una cuadrícula de 5 x 5 sobre todo el dibujo.
final List<Offset> cuadricula = <Offset>[
  for (final y in const <double>[100, 300, 500, 700, 900])
    for (final x in const <double>[100, 300, 500, 700, 900]) Offset(x, y),
];

/// Pinta con el color [color] tocando por todo el dibujo hasta que sale la
/// celebración. Si el color se suelta (en el Modo 1, al cubrir la mitad),
/// lo vuelve a elegir. Devuelve cuántas veces lo tuvo que volver a elegir.
Future<int> pintarHastaCelebrar(
  WidgetTester tester,
  Rect lienzo,
  Dibujo d, {
  int color = 0,
}) async {
  var toques = 0;
  var vecesElegido = 0;
  while (celebracion.evaluate().isEmpty && toques < 300) {
    if (colorElegido(tester) == null) {
      await elegirColor(tester, color);
      vecesElegido++;
    }
    await tester.tapAt(enPantalla(lienzo, d, cuadricula[toques % 25]));
    toques++;
    await esperar(tester, vueltas: 3);
  }
  return vecesElegido;
}
