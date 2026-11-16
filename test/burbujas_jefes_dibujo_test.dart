import 'dart:ui' as ui;

import 'package:colorear_ninos/juegos/burbujas/burbuja.dart';
import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuántos puntitos dibujados hay en [imagen] dentro de [zona].
Future<int> _dibujados(ui.Image imagen, Rect zona) async {
  final datos = (await imagen.toByteData())!;
  var n = 0;
  for (var y = zona.top.toInt(); y < zona.bottom.toInt(); y++) {
    for (var x = zona.left.toInt(); x < zona.right.toInt(); x++) {
      if (datos.getUint8((y * imagen.width + x) * 4 + 3) > 40) n++;
    }
  }
  return n;
}

void main() {
  testWidgets(
      'Todos los jefes se dibujan con lo que llevan puesto (corona, orejas, '
      'sábana, tentáculos, alas...), en cualquier momento', (tester) async {
    await tester.runAsync(() async {
      for (final jefe in TipoJefe.values) {
        for (final ahora in <double>[0.0, 1.3, 2.7]) {
          final b = Burbuja(
            id: 0,
            tipo: TipoBurbuja.jefe,
            centro: const Offset(150, 150),
            radio: 50,
            color: colorDeJefe(jefe),
            velocidad: 0,
            rumbo: 0,
            fase: 1,
            toques: 5,
            jefe: jefe,
          )..vuelta = ahora * 3;
          final grabadora = ui.PictureRecorder();
          pintarBurbuja(Canvas(grabadora), b, ahora);
          final imagen = await grabadora.endRecording().toImage(300, 300);
          final cuerpo = await _dibujados(
              imagen, Rect.fromCircle(center: b.centro, radius: 35));
          expect(cuerpo, greaterThan(2000), reason: '$jefe en $ahora');
          // Lo que lleva puesto sale de la burbuja (arriba, abajo o a los
          // lados), y se ve bien (no solo los rayos de luz).
          final arriba = await _dibujados(
              imagen, Rect.fromLTRB(90, 150 - b.margenArriba, 210, 100));
          final abajo = await _dibujados(
              imagen, Rect.fromLTRB(90, 200, 210, 150 + b.margenAbajo));
          if (b.margenArriba > 55) {
            expect(arriba, greaterThan(300), reason: '$jefe: arriba');
          }
          if (b.margenAbajo > 55) {
            expect(abajo, greaterThan(300), reason: '$jefe: abajo');
          }
          imagen.dispose();
        }
      }
    });
  });
}
