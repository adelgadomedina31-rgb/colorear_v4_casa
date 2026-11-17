import 'dart:io';
import 'dart:ui' as ui;

import 'package:colorear_ninos/juegos/burbujas/animaciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// Para que vaya fluido, cada cuadro de una animación (mascotas y fondo del
/// mar) se arma una sola vez y después se repite.
void main() {
  test('Cada cuadro de la animación se arma una sola vez', () async {
    const ruta = 'assets/mascotas/perrito.json';
    final composicion =
        await LottieComposition.fromBytes(File(ruta).readAsBytesSync());
    Animaciones.poner(ruta, composicion);
    addTearDown(Animaciones.olvidar);
    final cuadros = composicion.durationFrames.round();

    // Diez vueltas de la animación.
    for (var i = 0; i < cuadros * 10; i++) {
      final grabadora = ui.PictureRecorder();
      final dibujo = Animaciones.dibujar(
        Canvas(grabadora),
        ruta,
        (i / cuadros) % 1,
        const Rect.fromLTWH(10, 20, 150, 130),
        fit: BoxFit.fill,
      );
      grabadora.endRecording().dispose();
      expect(dibujo, isTrue);
    }
    expect(Animaciones.cuadrosPreparados, cuadros,
        reason: 'uno por cuadro, no uno cada vez que se dibuja');

    // Si todavía no está cargada, no dibuja nada.
    expect(
        Animaciones.dibujar(
            Canvas(ui.PictureRecorder()), 'otra.json', 0, Rect.zero),
        isFalse);

    // Al salir del juego se sueltan.
    Animaciones.olvidarCuadros();
    expect(Animaciones.cuadrosPreparados, 0);
  });
}
