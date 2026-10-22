import 'dart:ui' as ui;

import 'package:colorear_ninos/juegos/burbujas/animaciones.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/mascota.dart';
import 'package:colorear_ninos/juegos/burbujas/mundos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

/// Cuántos puntitos dibujados (no transparentes) hay en [imagen].
Future<int> _dibujados(ui.Image imagen) async {
  final datos = (await imagen.toByteData())!;
  var n = 0;
  for (var i = 3; i < datos.lengthInBytes; i += 4) {
    if (datos.getUint8(i) > 20) n++;
  }
  return n;
}

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Las animaciones de las mascotas y el fondo del mar se abren bien, se '
      've el dibujo, y en el juego la mascota y el mar las usan',
      (tester) async {
    sinAvisosDeSonido();
    // Todas las mascotas tienen nombre, y las que tienen animación tienen
    // sus datos para caminar.
    for (final lista in AjustesBurbujas.mascotas.values) {
      for (final emoji in lista) {
        expect(AjustesBurbujas.nombresMascotas, contains(emoji));
      }
    }
    for (final ruta in AjustesBurbujas.animacionesMascotas.values) {
      expect(ComoEsLaMascota.deCadaAnimacion, contains(ruta.split('/').last));
    }

    final rutas = <String>[
      ...AjustesBurbujas.animacionesMascotas.values,
      ...AjustesBurbujas.fondosAnimados.values,
    ];
    await tester.runAsync(() async {
      for (final ruta in rutas) {
        final c = await AssetLottie(ruta).load();
        expect(c.seconds, greaterThan(0), reason: ruta);
        expect(c.bounds.width, greaterThan(0), reason: ruta);
        // Las fotos que trae (el gatito) se abrieron todas.
        for (final foto in c.images.values) {
          expect(foto.loadedImage, isNotNull, reason: '$ruta ${foto.id}');
        }
        expect(c.warnings.where((w) => w.contains('Failed')), isEmpty,
            reason: ruta);
        // Se ve el dibujo en varios momentos de la animación.
        final d = LottieDrawable(c);
        for (final momento in <double>[0, 0.37, 0.81]) {
          d.setProgress(momento);
          final grabadora = ui.PictureRecorder();
          d.draw(Canvas(grabadora), const Rect.fromLTWH(0, 0, 100, 100),
              fit: BoxFit.contain);
          final imagen = await grabadora.endRecording().toImage(100, 100);
          expect(await _dibujados(imagen), greaterThan(1500),
              reason: '$ruta en $momento');
          imagen.dispose();
        }
        Animaciones.poner(ruta, c);
      }
    });

    // En el juego: la mascota usa su animación (con su forma, no
    // cuadrada) y el mar usa el fondo animado.
    var vioElMar = false;
    for (var semilla = 0; semilla < 30 && !vioElMar; semilla++) {
      await tester.binding.setSurfaceSize(const Size(420, 860));
      await tester.pumpWidget(
          MaterialApp(home: BurbujasJuego(nivelInicial: 2, semilla: semilla)));
      await tester.pump(const Duration(milliseconds: 100));
      final juego = juegoBurbujas(tester);
      final m = juego.mascota!;
      final ruta = AjustesBurbujas.animacionesMascotas[m.emoji];
      if (ruta != null) {
        expect(m.dibujo, isNotNull);
        final t = m.tamanoPara(zonaBurbujas(tester).size);
        expect(t.width / t.height,
            closeTo(m.dibujo!.size.width / m.dibujo!.size.height, 0.01));
      }
      if (juego.mundo == Mundo.mar) {
        vioElMar = true;
        expect(m.emoji, '🐟');
        expect(
            Animaciones.de(AjustesBurbujas.fondosAnimados['mar']), isNotNull);
      }
      // Se juega un poquito (se dibuja todo en cada cuadro) sin errores.
      await avanzar(tester, const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await cerrarPantalla(tester);
    }
    expect(vioElMar, isTrue);
  });
}
