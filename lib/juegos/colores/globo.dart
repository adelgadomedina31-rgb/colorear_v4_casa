import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Cómo se dibuja un globo: el cuerpo de color, el brillo blanco, el nudito
/// y el hilo. [ayuda] (de 0 a 1) le pone un resplandor amarillo alrededor,
/// para cuando hay que ayudarla a encontrarlo.
///
/// El globo ocupa todo el espacio que le den; queda bien si ese espacio es
/// un poco más alto que ancho (ancho = 0.72 del alto).
class PintorGlobo extends CustomPainter {
  PintorGlobo(this.color, {this.ayuda = 0});

  final Color color;
  final double ayuda;

  @override
  void paint(Canvas canvas, Size tam) {
    final w = tam.width;
    final h = tam.height;
    final cuerpo = Rect.fromCenter(
      center: Offset(w / 2, h * 0.39),
      width: w * 0.86,
      height: h * 0.74,
    );

    // Resplandor de ayuda.
    if (ayuda > 0) {
      canvas.drawOval(
        cuerpo.inflate(w * 0.06 + w * 0.05 * ayuda),
        Paint()
          ..color =
              const Color(0xFFFFEB3B).withValues(alpha: 0.35 + 0.5 * ayuda)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
      );
    }

    // El hilo, ondulado.
    final abajo = Offset(w / 2, cuerpo.bottom + h * 0.04);
    final hilo = Path()
      ..moveTo(abajo.dx, abajo.dy)
      ..cubicTo(w * 0.40, h * 0.86, w * 0.60, h * 0.92, w * 0.48, h * 0.995);
    canvas.drawPath(
      hilo,
      Paint()
        ..color = const Color(0xFF757575)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );

    // El nudito.
    final oscuro = Color.lerp(color, Colors.black, 0.22)!;
    final nudo = Path()
      ..moveTo(w / 2, cuerpo.bottom - h * 0.01)
      ..lineTo(w / 2 - w * 0.06, abajo.dy + h * 0.01)
      ..lineTo(w / 2 + w * 0.06, abajo.dy + h * 0.01)
      ..close();
    canvas.drawPath(nudo, Paint()..color = oscuro);

    // El cuerpo, con un poco de sombra abajo a la derecha.
    canvas.drawOval(
      cuerpo,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cuerpo.left + cuerpo.width * 0.35,
              cuerpo.top + cuerpo.height * 0.3),
          cuerpo.width * 0.85,
          <Color>[Color.lerp(color, Colors.white, 0.18)!, color, oscuro],
          <double>[0.0, 0.55, 1.0],
        ),
    );
    canvas.drawOval(
      cuerpo,
      Paint()
        ..color = oscuro
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    // El brillo blanco.
    canvas.save();
    canvas.translate(
        cuerpo.left + cuerpo.width * 0.3, cuerpo.top + cuerpo.height * 0.26);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: h * 0.15),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorGlobo viejo) =>
      viejo.color != color || viejo.ayuda != ayuda;
}
