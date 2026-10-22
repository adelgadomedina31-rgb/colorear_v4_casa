import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// =============================================================================
//  Dibujos ya hechos (letras y emojis): se dibujan una sola vez y después se
//  reutilizan, para que el juego vaya fluido.
// =============================================================================

class Dibujos {
  Dibujos._();

  static final Map<String, ui.Image?> _imagenes = <String, ui.Image?>{};

  /// La palabra [texto] con borde blanco, de color [color] (64 px de alto).
  static ui.Image? palabra(String texto, Color color, TextStyle? letra) {
    final clave = 'p|$texto|${color.toARGB32()}|${letra?.fontFamily}';
    return _imagenes.putIfAbsent(clave, () {
      final pintores = <TextPainter>[
        for (final borde in <bool>[true, false])
          TextPainter(
            text: TextSpan(
              text: texto,
              style: TextStyle(
                fontFamily: letra?.fontFamily,
                fontFamilyFallback: letra?.fontFamilyFallback,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                foreground: borde
                    ? (Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 10
                      ..strokeJoin = StrokeJoin.round
                      ..color = Colors.white)
                    : (Paint()..color = color),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];
      return _foto(pintores, 8);
    });
  }

  /// Un emoji (96 px).
  static ui.Image? emoji(String emoji, TextStyle? letra) {
    final clave = 'e|$emoji|${letra?.fontFamily}';
    return _imagenes.putIfAbsent(clave, () {
      final pintor = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(
            fontFamily: letra?.fontFamily,
            fontFamilyFallback: letra?.fontFamilyFallback,
            fontSize: 96,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return _foto(<TextPainter>[pintor], 4);
    });
  }

  static ui.Image? _foto(List<TextPainter> pintores, double margen) {
    try {
      final w = pintores.first.width + margen * 2;
      final h = pintores.first.height + margen * 2;
      final grabadora = ui.PictureRecorder();
      final canvas = Canvas(grabadora);
      for (final p in pintores) {
        p.paint(canvas, Offset(margen, margen));
      }
      final foto = grabadora.endRecording();
      final imagen = foto.toImageSync(w.ceil(), h.ceil());
      foto.dispose();
      return imagen;
    } catch (_) {
      return null;
    }
  }
}

/// Dibuja [imagen] centrada en [c], con [alto] de alto y [opacidad].
void dibujarImagen(
  Canvas canvas,
  ui.Image imagen,
  Offset c,
  double alto,
  double opacidad,
) {
  final ancho = alto * imagen.width / imagen.height;
  canvas.drawImageRect(
    imagen,
    Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
    Rect.fromCenter(center: c, width: ancho, height: alto),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacidad.clamp(0.0, 1.0)),
  );
}

/// Una estrella de 5 puntas centrada en [c].
Path estrella(Offset c, double grande, double chica) {
  final camino = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? grande : chica;
    final p = c + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      camino.moveTo(p.dx, p.dy);
    } else {
      camino.lineTo(p.dx, p.dy);
    }
  }
  return camino..close();
}
