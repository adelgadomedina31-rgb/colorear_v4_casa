import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/juegos/burbujas/dibujos.dart';
import 'package:colorear_ninos/juegos/burbujas/mundos.dart';

/// La mascota de cada nivel: está abajo, en el medio, sopla burbujas, se ríe
/// si la tocan y aplaude al pasar de nivel.
class Mascota {
  Mascota(this.emoji, this.mundo);

  /// El animalito ('🐥', '🐳'...).
  final String emoji;

  /// El mundo donde está (en el espacio lleva casco de astronauta).
  final Mundo mundo;

  /// Cuándo sopló la última burbuja, cuándo saltó (al tocarla) y entre
  /// cuándo y cuándo aplaude (segundos del juego).
  double soplo = -10;
  double salto = -10;
  double aplaudeDesde = -10;
  double aplaudeHasta = -10;

  /// Cuándo apareció (llega dando un saltito).
  double llega = -10;

  static const double duracionSoplo = 0.45;
  static const double duracionSalto = 0.7;

  bool aplaudiendo(double ahora) =>
      ahora >= aplaudeDesde && ahora < aplaudeHasta;

  bool saltando(double ahora) => ahora - salto < duracionSalto;

  /// Qué tan grande se ve en una zona de juego de tamaño [zona].
  static double tamanoPara(Size zona) => zona.shortestSide * 0.2;

  /// Dónde está (sin contar los saltos), para saber si la tocaron.
  Rect lugar(Size zona) {
    final t = tamanoPara(zona);
    return Rect.fromCenter(
      center: Offset(zona.width / 2, zona.height - t * 0.5 - 2),
      width: t,
      height: t,
    );
  }

  /// Por dónde salen las burbujas que sopla.
  Offset boca(Size zona) {
    final l = lugar(zona);
    return Offset(l.center.dx, l.top + l.height * 0.3);
  }
}

/// Dibuja la mascota [m] en la zona de juego de tamaño [zona].
void pintarMascota(
  Canvas canvas,
  Size zona,
  Mascota m,
  double ahora, {
  TextStyle? letra,
}) {
  final imagen = Dibujos.emoji(m.emoji, letra);
  if (imagen == null) return;
  final lugar = m.lugar(zona);
  final t = lugar.width;
  var centro = lugar.center;

  // Respira (sube y baja suavecito).
  var subir = math.sin(ahora * 2.2) * t * 0.025;
  var ancho = 1.0;
  var alto = 1.0 + 0.03 * math.sin(ahora * 2.2);
  var giro = 0.0;

  // Llega dando un saltito.
  final llegada = (ahora - m.llega) / 0.6;
  var aparece = 1.0;
  if (llegada >= 0 && llegada < 1) {
    aparece = Curves.easeOutBack.transform(llegada);
    subir += math.sin(llegada * math.pi) * t * 0.4;
  }

  // Al soplar se infla un poquito.
  final soplo = (ahora - m.soplo) / Mascota.duracionSoplo;
  if (soplo >= 0 && soplo < 1) {
    final f = math.sin(soplo * math.pi);
    ancho += 0.12 * f;
    alto -= 0.06 * f;
  }

  // Al tocarla salta y se mueve contenta.
  final salto = (ahora - m.salto) / Mascota.duracionSalto;
  if (salto >= 0 && salto < 1) {
    subir += math.sin(salto * math.pi) * t * 0.6;
    giro = math.sin(salto * math.pi * 4) * 0.2;
  }

  // Aplaudiendo: da saltitos.
  final aplaude = m.aplaudiendo(ahora);
  if (aplaude) {
    subir += (math.sin(ahora * 9)).abs() * t * 0.22;
  }
  centro = centro - Offset(0, subir);

  // La sombra en el suelo (más chica cuando está en el aire).
  final piso = lugar.bottom - t * 0.04;
  final enElAire = (subir / t).clamp(0.0, 1.0);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(lugar.center.dx, piso),
      width: t * 0.75 * (1 - 0.4 * enElAire) * aparece,
      height: t * 0.14 * (1 - 0.4 * enElAire) * aparece,
    ),
    Paint()..color = Colors.black.withValues(alpha: 0.18),
  );

  canvas.save();
  canvas.translate(centro.dx, centro.dy);
  canvas.rotate(giro);
  canvas.scale(ancho * aparece, alto * aparece);
  dibujarImagen(canvas, imagen, Offset.zero, t, 1);
  if (m.mundo == Mundo.espacio) _casco(canvas, t);
  canvas.restore();

  // El aire del soplido: unas bolitas que suben.
  if (soplo >= 0 && soplo < 1) {
    final boca = m.boca(zona) - Offset(0, subir);
    for (var k = 0; k < 3; k++) {
      final f = (soplo * 1.3 - k * 0.15).clamp(0.0, 1.0);
      if (f <= 0) continue;
      final p = boca + Offset((k - 1) * t * 0.12 * f, -t * (0.15 + 0.5 * f));
      canvas.drawCircle(
        p,
        t * (0.04 + 0.03 * f),
        Paint()..color = Colors.white.withValues(alpha: 0.7 * (1 - f)),
      );
    }
  }

  // Estrellitas cuando salta.
  if (salto >= 0 && salto < 1) {
    for (var k = 0; k < 5; k++) {
      final a = -math.pi / 2 + (k - 2) * 0.55;
      final p =
          centro + Offset(math.cos(a), math.sin(a)) * t * (0.55 + 0.4 * salto);
      canvas.drawPath(
        estrella(p, t * 0.08 * (1 - salto), t * 0.035 * (1 - salto)),
        Paint()
          ..color = const <Color>[
            Color(0xFFFFEB3B),
            Color(0xFFFF4081),
            Color(0xFF40C4FF),
            Color(0xFF69F0AE),
            Color(0xFFFFAB40),
          ][k],
      );
    }
  }

  // Las manitos que aplauden, a los dos lados.
  if (aplaude) {
    final manos = Dibujos.emoji('👏', letra);
    if (manos != null) {
      for (final lado in <double>[-1, 1]) {
        final golpe = (math.sin(ahora * 16 + (lado > 0 ? math.pi : 0))).abs();
        final p = centro + Offset(lado * t * 0.75, -t * 0.2);
        dibujarImagen(canvas, manos, p, t * (0.42 + 0.12 * golpe), 1);
      }
    }
  }
}

/// El casco de astronauta (en el espacio).
void _casco(Canvas canvas, double t) {
  final c = Offset(0, -t * 0.04);
  final r = t * 0.6;
  canvas.drawCircle(
    c,
    r,
    Paint()..color = const Color(0xFF80D8FF).withValues(alpha: 0.2),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = t * 0.045
      ..color = Colors.white.withValues(alpha: 0.9),
  );
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: r * 0.78),
    math.pi * 1.1,
    0.8,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = t * 0.05
      ..color = Colors.white.withValues(alpha: 0.75),
  );
  // La antenita.
  final base = c - Offset(0, r);
  canvas.drawLine(
    base,
    base - Offset(0, t * 0.14),
    Paint()
      ..strokeWidth = t * 0.025
      ..color = Colors.white,
  );
  canvas.drawCircle(
    base - Offset(0, t * 0.16),
    t * 0.04,
    Paint()..color = const Color(0xFFFF5252),
  );
}
