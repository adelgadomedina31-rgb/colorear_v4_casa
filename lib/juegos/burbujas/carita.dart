import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/juegos/burbujas/dibujos.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';

/// Las caras que pone una burbuja.
enum Gesto {
  /// Contenta: ojitos abiertos (que parpadean) y sonrisa.
  normal,

  /// Riéndose: ojitos cerrados "^ ^" y boca abierta.
  risa,

  /// Dormida: ojitos cerrados y boquita de "o".
  dormida,

  /// "¡Ay!": ojitos apretados "> <" y boca de "o" grande (al reventar).
  ay,
}

const Color _oscuro = Color(0xFF2B2B4A);
const Color _boca = Color(0xFF9C1F45);
const Color _lengua = Color(0xFFFF8A9E);
const Color _cachetes = Color(0xFFFF80AB);

/// true si la burbuja de [fase] está parpadeando en el momento [ahora]
/// (cada una a su ritmo, cada 2 a 4 segundos).
bool parpadeando(double ahora, double fase) {
  final cada = 2.4 + 2.0 * ((fase * 0.37) % 1);
  return (ahora + fase * 1.7) % cada < 0.14;
}

/// Dibuja una carita centrada en (0, 0) (el centro de una burbuja de
/// radio [r]). [mira] = hacia dónde miran los ojitos (de -1 a 1).
void pintarCarita(
  Canvas canvas,
  double r,
  Gesto gesto, {
  bool parpadea = false,
  Offset mira = Offset.zero,
}) {
  final grosor = math.max(1.2, r * 0.05);
  final linea = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _oscuro;
  // Debajo de cada línea, una línea blanca más gruesa: así se ve sobre
  // fondos oscuros (la noche, el espacio).
  final fondo = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor * 2.1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Colors.white.withValues(alpha: 0.75);
  void trazo(Path camino) {
    canvas.drawPath(camino, fondo);
    canvas.drawPath(camino, linea);
  }

  // Los cachetes.
  for (final lado in <double>[-1, 1]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(lado * r * 0.46, r * 0.14),
        width: r * 0.2,
        height: r * 0.12,
      ),
      Paint()..color = _cachetes.withValues(alpha: 0.55),
    );
  }

  // Los ojos.
  for (final lado in <double>[-1, 1]) {
    final c = Offset(lado * r * 0.27, -r * 0.1);
    final a = r * 0.1; // medio ancho de un ojo
    switch (gesto) {
      case Gesto.normal when !parpadea:
        final ojo = Rect.fromCenter(
          center: c,
          width: r * 0.24,
          height: r * 0.3,
        );
        canvas.drawOval(ojo, Paint()..color = Colors.white);
        canvas.drawOval(
          ojo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, r * 0.022)
            ..color = _oscuro.withValues(alpha: 0.6),
        );
        final pupila =
            c + Offset(mira.dx * r * 0.04, mira.dy * r * 0.05 + r * 0.02);
        canvas.drawCircle(pupila, r * 0.085, Paint()..color = _oscuro);
        canvas.drawCircle(
          pupila + Offset(-r * 0.03, -r * 0.035),
          r * 0.032,
          Paint()..color = Colors.white,
        );
      case Gesto.normal || Gesto.dormida:
        // Cerrados: una curvita para abajo.
        trazo(
          Path()
            ..moveTo(c.dx - a, c.dy)
            ..quadraticBezierTo(c.dx, c.dy + a * 0.9, c.dx + a, c.dy),
        );
      case Gesto.risa:
        // "^ ^"
        trazo(
          Path()
            ..moveTo(c.dx - a, c.dy + a * 0.4)
            ..quadraticBezierTo(c.dx, c.dy - a * 1.1, c.dx + a, c.dy + a * 0.4),
        );
      case Gesto.ay:
        // "> <"
        trazo(
          Path()
            ..moveTo(c.dx - lado * a, c.dy - a * 0.7)
            ..lineTo(c.dx + lado * a * 0.6, c.dy)
            ..lineTo(c.dx - lado * a, c.dy + a * 0.7),
        );
    }
  }

  // La boca.
  switch (gesto) {
    case Gesto.normal:
      trazo(
        Path()
          ..moveTo(-r * 0.16, r * 0.17)
          ..quadraticBezierTo(0, r * 0.34, r * 0.16, r * 0.17),
      );
    case Gesto.risa:
      final boca = Path()
        ..moveTo(-r * 0.2, r * 0.13)
        ..lineTo(r * 0.2, r * 0.13)
        ..quadraticBezierTo(r * 0.2, r * 0.46, 0, r * 0.46)
        ..quadraticBezierTo(-r * 0.2, r * 0.46, -r * 0.2, r * 0.13)
        ..close();
      canvas.drawPath(boca, fondo);
      canvas.drawPath(boca, Paint()..color = _boca);
      canvas.save();
      canvas.clipPath(boca);
      canvas.drawCircle(
        Offset(0, r * 0.47),
        r * 0.13,
        Paint()..color = _lengua,
      );
      canvas.restore();
      canvas.drawPath(boca, linea);
    case Gesto.dormida:
      final boca = Rect.fromCenter(
        center: Offset(0, r * 0.24),
        width: r * 0.1,
        height: r * 0.1,
      );
      canvas.drawOval(boca, fondo);
      canvas.drawOval(boca, Paint()..color = _boca);
    case Gesto.ay:
      final boca = Rect.fromCenter(
        center: Offset(0, r * 0.26),
        width: r * 0.2,
        height: r * 0.26,
      );
      canvas.drawOval(boca, fondo);
      canvas.drawOval(boca, Paint()..color = _boca);
      canvas.drawOval(boca, linea);
  }
}

// =============================================================================
//  Lo que lleva puesto cada jefe
// =============================================================================

/// El color de cada jefe.
Color colorDeJefe(TipoJefe jefe) => switch (jefe) {
      TipoJefe.rey => const Color(0xFFFFB300),
      TipoJefe.saltarina => const Color(0xFFEC407A),
      TipoJefe.dormilona => const Color(0xFF7986CB),
      TipoJefe.pinata => const Color(0xFFFF7043),
    };

/// Los colores de los dulces (la piñata y sus burbujitas).
const List<Color> coloresDulces = <Color>[
  Color(0xFFFF4081),
  Color(0xFFFFEB3B),
  Color(0xFF18FFFF),
  Color(0xFF76FF03),
  Color(0xFFFF9100),
  Color(0xFFE040FB),
];

/// Lo que va DETRÁS de la burbuja del jefe (orejas, la cuerda de la
/// piñata). El lienzo ya está en el centro de la burbuja.
void pintarJefeAtras(Canvas canvas, TipoJefe jefe, double r, double ahora) {
  switch (jefe) {
    case TipoJefe.saltarina:
      // Orejas de conejo que se mueven.
      for (final lado in <double>[-1, 1]) {
        final mueve = math.sin(ahora * 4 + lado) * 0.1;
        canvas.save();
        canvas.translate(lado * r * 0.38, -r * 0.78);
        canvas.rotate(lado * 0.25 + mueve);
        final oreja = Rect.fromCenter(
          center: Offset(0, -r * 0.42),
          width: r * 0.36,
          height: r * 0.95,
        );
        canvas.drawOval(oreja, Paint()..color = Colors.white);
        canvas.drawOval(
          oreja,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.03
            ..color = const Color(0xFFAD1457),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * 0.4),
            width: r * 0.17,
            height: r * 0.7,
          ),
          Paint()..color = const Color(0xFFF8BBD0),
        );
        canvas.restore();
      }
    case TipoJefe.pinata:
      // La cuerda de la que cuelga.
      final mueve = math.sin(ahora * 2) * r * 0.08;
      canvas.drawLine(
        Offset(0, -r * 0.95),
        Offset(mueve, -r * 1.7),
        Paint()
          ..strokeWidth = r * 0.03
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8D6E63),
      );
    default:
      break;
  }
}

/// El cuerpo de la piñata: franjas de colores con flecos (va adentro de
/// la burbuja, encima del cuerpo transparente).
void pintarRayasPinata(Canvas canvas, double r, double ahora) {
  canvas.save();
  canvas.clipPath(
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)),
  );
  const franjas = 7;
  final alto = 2 * r / franjas;
  for (var i = 0; i < franjas; i++) {
    final y = -r + i * alto;
    final color = coloresDulces[i % coloresDulces.length];
    // Cada franja con el borde de abajo en zigzag (como flecos de papel).
    final camino = Path()..moveTo(-r, y);
    camino.lineTo(r, y);
    camino.lineTo(r, y + alto);
    const picos = 10;
    for (var k = picos; k >= 0; k--) {
      final x = -r + 2 * r * k / picos;
      camino.lineTo(x, y + alto + (k.isEven ? 0 : alto * 0.35));
    }
    camino.close();
    canvas.drawPath(camino, Paint()..color = color.withValues(alpha: 0.6));
  }
  canvas.restore();
}

/// Lo que va ADELANTE de la burbuja del jefe (corona, gorro, Zzz).
/// [despierta] = la dormilona está despierta.
void pintarJefeAdelante(
  Canvas canvas,
  TipoJefe jefe,
  double r,
  double ahora, {
  bool despierta = false,
  TextStyle? letra,
}) {
  switch (jefe) {
    case TipoJefe.rey:
      _corona(canvas, r, ahora);
    case TipoJefe.dormilona:
      _gorro(canvas, r, ahora);
      if (!despierta) _zetas(canvas, r, ahora, letra);
    default:
      break;
  }
}

void _corona(Canvas canvas, double r, double ahora) {
  final w = r * 0.95;
  final h = r * 0.5;
  final base = -r * 0.78;
  final camino = Path()
    ..moveTo(-w / 2, base)
    ..lineTo(-w / 2, base - h * 0.75)
    ..lineTo(-w / 4, base - h * 0.35)
    ..lineTo(0, base - h)
    ..lineTo(w / 4, base - h * 0.35)
    ..lineTo(w / 2, base - h * 0.75)
    ..lineTo(w / 2, base)
    ..close();
  canvas.drawPath(
    camino,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, base - h),
        Offset(0, base),
        const <Color>[Color(0xFFFFF176), Color(0xFFFFB300)],
      ),
  );
  canvas.drawPath(
    camino,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE65100),
  );
  // Las joyas (brillan).
  final brillo = 0.75 + 0.25 * math.sin(ahora * 5);
  for (final (x, y, color) in <(double, double, Color)>[
    (-w / 2, base - h * 0.75, const Color(0xFFE53935)),
    (0, base - h, const Color(0xFF1E88E5)),
    (w / 2, base - h * 0.75, const Color(0xFF43A047)),
  ]) {
    canvas.drawCircle(
      Offset(x, y),
      r * 0.07,
      Paint()..color = color.withValues(alpha: brillo),
    );
  }
  canvas.drawCircle(
    Offset(0, base - h * 0.3),
    r * 0.065,
    Paint()..color = const Color(0xFFE53935),
  );
}

void _gorro(Canvas canvas, double r, double ahora) {
  // Un gorro de dormir que cae hacia un lado, a rayas, con un pompón.
  final mueve = math.sin(ahora * 1.5) * r * 0.05;
  final punta = Offset(r * 0.95 + mueve, -r * 0.55);
  final camino = Path()
    ..moveTo(-r * 0.62, -r * 0.6)
    ..quadraticBezierTo(-r * 0.2, -r * 1.55, punta.dx, punta.dy)
    ..quadraticBezierTo(r * 0.3, -r * 0.95, r * 0.6, -r * 0.62)
    ..quadraticBezierTo(0, -r * 0.85, -r * 0.62, -r * 0.6)
    ..close();
  canvas.drawPath(camino, Paint()..color = const Color(0xFF5C6BC0));
  canvas.save();
  canvas.clipPath(camino);
  for (var i = 0; i < 5; i++) {
    canvas.drawLine(
      Offset(-r + i * r * 0.45, -r * 0.4),
      Offset(-r * 0.4 + i * r * 0.45, -r * 1.6),
      Paint()
        ..strokeWidth = r * 0.12
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }
  canvas.restore();
  canvas.drawPath(
    camino,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03
      ..color = const Color(0xFF283593),
  );
  // El borde de abajo, blandito.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -r * 0.66),
        width: r * 1.3,
        height: r * 0.18,
      ),
      Radius.circular(r * 0.09),
    ),
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(punta, r * 0.14, Paint()..color = Colors.white);
  canvas.drawCircle(
    punta,
    r * 0.14,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.025
      ..color = const Color(0xFF9FA8DA),
  );
}

/// "Z z z" que suben de la dormilona.
void _zetas(Canvas canvas, double r, double ahora, TextStyle? letra) {
  for (var k = 0; k < 3; k++) {
    final t = (ahora * 0.5 + k / 3) % 1;
    final imagen = Dibujos.palabra('Z', const Color(0xFF5C6BC0), letra);
    if (imagen == null) continue;
    final p = Offset(r * (0.75 + 0.35 * t), -r * (0.9 + 0.8 * t));
    final opacidad = t < 0.2 ? t / 0.2 : (1 - t);
    dibujarImagen(canvas, imagen, p, r * (0.22 + 0.2 * t), opacidad);
  }
}
