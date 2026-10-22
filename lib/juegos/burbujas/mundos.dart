import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:colorear_ninos/juegos/burbujas/animaciones.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/dibujos.dart';

/// Los mundos donde pasa cada nivel de Burbujas (el fondo de la pantalla).
enum Mundo {
  /// De día: sol con carita, nubes que pasan, lomas con flores.
  cielo,

  /// El fondo del mar: peces que nadan, algas, arena y burbujitas.
  mar,

  /// El atardecer: sol grande que se esconde, pajaritos y lomas moradas.
  atardecer,

  /// La noche: luna, estrellas que brillan, luciérnagas y casitas.
  noche,

  /// El espacio: planetas, estrellas fugaces, un cohete y suelo de luna.
  espacio;

  /// Los mundos que están en la lista de burbujas_ajustes.dart (en ese
  /// orden). Los nombres que no existen no cuentan.
  static List<Mundo> get deLosAjustes => <Mundo>[
        for (final nombre in AjustesBurbujas.mundos)
          for (final m in Mundo.values)
            if (m.name == nombre) m,
      ];
}

/// Lo que el dibujo del mundo necesita saber en cada cuadro: qué mundo es,
/// cuál era el anterior (mientras cambia) y la hora del juego.
class VistaMundo {
  Mundo mundo = Mundo.cielo;
  Mundo? anterior;
  double inicioCambio = -10;
  double ahora = 0;

  /// Cuánto tarda en cambiar de un mundo al otro (segundos).
  static const double duracionCambio = 0.9;

  /// Cambia al mundo [nuevo]: se abre un círculo desde abajo que lo va
  /// mostrando.
  void cambiarA(Mundo nuevo, double ahora) {
    if (nuevo == mundo && anterior == null) return;
    anterior = mundo;
    mundo = nuevo;
    inicioCambio = ahora;
  }
}

/// Dibuja el mundo (cielo, mar...) detrás de todo. Se repinta en cada
/// cuadro (los peces nadan, las estrellas brillan...).
class PintorMundo extends CustomPainter {
  PintorMundo(
    this.vista, {
    required Listenable repaint,
    this.abajo = 0,
    this.letra,
  }) : super(repaint: repaint);

  final VistaMundo vista;

  /// Cuánto espacio queda abajo de la zona de juego (la barra del
  /// teléfono): el suelo se dibuja arriba de eso.
  final double abajo;

  /// La letra de la app (para los emojis de los peces y el cohete).
  final TextStyle? letra;

  @override
  void paint(Canvas canvas, Size tam) {
    if (tam.isEmpty) return;
    final s = tam.shortestSide;
    final suelo = tam.height - abajo - s * 0.075;
    final ahora = vista.ahora;
    final anterior = vista.anterior;
    final t = (ahora - vista.inicioCambio) / VistaMundo.duracionCambio;
    if (anterior == null || t >= 1) {
      pintarMundo(canvas, tam, vista.mundo, suelo, ahora, letra);
      return;
    }
    // Cambiando: el mundo nuevo aparece en un círculo que crece desde
    // donde está la mascota.
    pintarMundo(canvas, tam, anterior, suelo, ahora, letra);
    final e = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    final centro = Offset(tam.width / 2, suelo);
    final lejos =
        math.sqrt(math.pow(tam.width / 2, 2) + math.pow(suelo, 2)) + s * 0.1;
    final radio = math.max(1.0, e * lejos);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centro, radius: radio)),
    );
    pintarMundo(canvas, tam, vista.mundo, suelo, ahora, letra);
    canvas.restore();
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..color = Colors.white.withValues(alpha: 0.7 * (1 - e)),
    );
  }

  @override
  bool shouldRepaint(covariant PintorMundo viejo) =>
      viejo.vista != vista || viejo.abajo != abajo || viejo.letra != letra;
}

/// Dibuja el mundo [mundo] entero. [suelo] = dónde empieza el suelo (la
/// mascota se para ahí). [ahora] = segundos del juego.
void pintarMundo(
  Canvas canvas,
  Size tam,
  Mundo mundo,
  double suelo,
  double ahora,
  TextStyle? letra,
) {
  // Si el mundo tiene un fondo animado (y ya se cargó), se ve ese.
  final fondo = Animaciones.de(AjustesBurbujas.fondosAnimados[mundo.name]);
  if (fondo != null) {
    _fondoAnimado(canvas, tam, fondo, ahora);
    return;
  }
  switch (mundo) {
    case Mundo.cielo:
      _cielo(canvas, tam, suelo, ahora);
    case Mundo.mar:
      _mar(canvas, tam, suelo, ahora, letra);
    case Mundo.atardecer:
      _atardecer(canvas, tam, suelo, ahora);
    case Mundo.noche:
      _noche(canvas, tam, suelo, ahora);
    case Mundo.espacio:
      _espacio(canvas, tam, suelo, ahora, letra);
  }
}

/// Un fondo animado (Lottie) que llena toda la pantalla: se agranda lo
/// necesario y, si sobra, se corta arriba o a los lados (la parte de abajo
/// se ve siempre).
void _fondoAnimado(
    Canvas canvas, Size tam, LottieDrawable fondo, double ahora) {
  final duracion = math.max(0.1, fondo.composition.seconds);
  fondo.setProgress((ahora / duracion) % 1);
  canvas.save();
  canvas.clipRect(Offset.zero & tam);
  fondo.draw(
    canvas,
    Offset.zero & tam,
    fit: BoxFit.cover,
    alignment: Alignment.bottomCenter,
  );
  canvas.restore();
}

// =============================================================================
//  Ayudas
// =============================================================================

/// Puntos al azar (siempre los mismos): x e y entre 0 y 1, y dos números
/// más entre 0 y 1 (para el tamaño y el ritmo de cada uno).
List<(double, double, double, double)> _puntos(int n, int semilla) {
  final azar = math.Random(semilla);
  return <(double, double, double, double)>[
    for (var i = 0; i < n; i++)
      (
        azar.nextDouble(),
        azar.nextDouble(),
        azar.nextDouble(),
        azar.nextDouble(),
      ),
  ];
}

final List<(double, double, double, double)> _estrellasNoche = _puntos(55, 3);
final List<(double, double, double, double)> _estrellasEspacio = _puntos(90, 5);
final List<(double, double, double, double)> _luciernagas = _puntos(10, 9);
final List<(double, double, double, double)> _burbujitasMar = _puntos(18, 4);

/// Un degradado de arriba a abajo que llena toda la pantalla.
void _degradado(
  Canvas canvas,
  Size tam,
  List<int> colores,
  List<double> donde,
) {
  canvas.drawRect(
    Offset.zero & tam,
    Paint()
      ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, tam.height),
          <Color>[
            for (final c in colores) Color(c),
          ],
          donde),
  );
}

/// Una loma (o el suelo): una línea ondulada a la altura [y] y todo lo de
/// abajo pintado de [color].
void _loma(
  Canvas canvas,
  Size tam,
  double y,
  double alto,
  double ondas,
  double fase,
  Color color,
) {
  final camino = Path()..moveTo(0, tam.height);
  const pasos = 32;
  for (var i = 0; i <= pasos; i++) {
    final x = tam.width * i / pasos;
    camino.lineTo(
      x,
      y - alto * math.sin(i / pasos * ondas * 2 * math.pi + fase),
    );
  }
  camino
    ..lineTo(tam.width, tam.height)
    ..close();
  canvas.drawPath(camino, Paint()..color = color);
}

/// La altura de una [_loma] en el punto [x].
double _alturaLoma(
  Size tam,
  double x,
  double y,
  double alto,
  double ondas,
  double fase,
) =>
    y - alto * math.sin(x / tam.width * ondas * 2 * math.pi + fase);

/// Una nube esponjosa.
void _nube(Canvas canvas, Offset c, double r, Paint pintura) {
  canvas.drawCircle(c, r, pintura);
  canvas.drawCircle(c + Offset(-r * 0.9, r * 0.3), r * 0.7, pintura);
  canvas.drawCircle(c + Offset(r * 0.95, r * 0.25), r * 0.75, pintura);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(c.dx - r * 1.5, c.dy, c.dx + r * 1.6, c.dy + r * 0.85),
      Radius.circular(r * 0.45),
    ),
    pintura,
  );
}

/// Algo que pasa de un lado al otro de la pantalla y vuelve a empezar.
/// [x0] = dónde empieza (0 a 1), [rapidez] = píxeles por segundo,
/// [margen] = cuánto se sale por los lados.
double _pasando(
  double ancho,
  double x0,
  double rapidez,
  double margen,
  double ahora, {
  bool haciaLaIzquierda = false,
}) {
  final largo = ancho + margen * 2;
  final x = (x0 * largo + ahora * rapidez) % largo - margen;
  return haciaLaIzquierda ? ancho - x : x;
}

/// Un brillo redondo suave (sin desenfoque, que es lento).
void _brillo(Canvas canvas, Offset c, double r, Color color, double fuerza) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = ui.Gradient.radial(c, r, <Color>[
        color.withValues(alpha: fuerza),
        color.withValues(alpha: 0),
      ]),
  );
}

/// Un emoji en [c], de [alto] de alto. [espejo] = mirando al otro lado.
void _emoji(
  Canvas canvas,
  String emoji,
  Offset c,
  double alto,
  TextStyle? letra, {
  bool espejo = false,
  double opacidad = 1,
  double giro = 0,
}) {
  final imagen = Dibujos.emoji(emoji, letra);
  if (imagen == null) return;
  canvas.save();
  canvas.translate(c.dx, c.dy);
  if (giro != 0) canvas.rotate(giro);
  if (espejo) canvas.scale(-1, 1);
  dibujarImagen(canvas, imagen, Offset.zero, alto, opacidad);
  canvas.restore();
}

// =============================================================================
//  CIELO (de día)
// =============================================================================

void _cielo(Canvas canvas, Size tam, double suelo, double ahora) {
  final s = tam.shortestSide;
  final w = tam.width;
  final h = tam.height;
  _degradado(
    canvas,
    tam,
    const <int>[0xFF4FC3F7, 0xFF81D4FA, 0xFFE1F5FE],
    const <double>[0, 0.45, 1],
  );

  // El sol, con carita y rayos que giran.
  final sol = Offset(w * 0.8, h * 0.21);
  final rs = s * 0.085;
  _brillo(canvas, sol, rs * 2.4, const Color(0xFFFFF59D), 0.7);
  final rayos = Paint()..color = const Color(0xFFFFD54F);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6 + ahora * 0.25;
    final largo = rs * (1.55 + 0.12 * math.sin(ahora * 3 + i));
    final punta = sol + Offset(math.cos(a), math.sin(a)) * largo;
    final lado = Offset(-math.sin(a), math.cos(a)) * rs * 0.16;
    final base = sol + Offset(math.cos(a), math.sin(a)) * rs * 1.08;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + lado.dx, base.dy + lado.dy)
        ..lineTo(punta.dx, punta.dy)
        ..lineTo(base.dx - lado.dx, base.dy - lado.dy)
        ..close(),
      rayos,
    );
  }
  canvas.drawCircle(
    sol,
    rs,
    Paint()
      ..shader = ui.Gradient.radial(
        sol + Offset(-rs * 0.3, -rs * 0.3),
        rs * 1.3,
        const <Color>[Color(0xFFFFF59D), Color(0xFFFFCA28)],
      ),
  );
  _caritaDeSol(canvas, sol, rs, ahora);

  // Las nubes que pasan despacito.
  final blanco = Paint()..color = Colors.white.withValues(alpha: 0.85);
  const nubes = <(double, double, double, double)>[
    // (y, tamaño, rapidez, dónde empieza)
    (0.2, 0.07, 0.018, 0.1),
    (0.36, 0.09, 0.012, 0.6),
    (0.55, 0.06, 0.022, 0.35),
    (0.7, 0.075, 0.015, 0.85),
  ];
  for (final (y, r, v, x0) in nubes) {
    final x = _pasando(w, x0, v * s, r * s * 2.5, ahora);
    _nube(canvas, Offset(x, y * h), r * s, blanco);
  }

  // Lomas verdes con flores.
  _loma(
    canvas,
    tam,
    suelo - s * 0.08,
    s * 0.03,
    1.5,
    0.6,
    const Color(0xFFAED581),
  );
  _loma(canvas, tam, suelo, s * 0.012, 2.5, 1.2, const Color(0xFF7CB342));
  final pasto = Paint()
    ..color = const Color(0xFF558B2F)
    ..strokeWidth = s * 0.006
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 26; i++) {
    final x = w * (i + 0.5) / 26;
    final y = _alturaLoma(tam, x, suelo, s * 0.012, 2.5, 1.2) + s * 0.012;
    final mueve = math.sin(ahora * 2 + i) * s * 0.004;
    canvas.drawLine(
      Offset(x, y),
      Offset(x - s * 0.01 + mueve, y - s * 0.022),
      pasto,
    );
    canvas.drawLine(
      Offset(x + s * 0.008, y),
      Offset(x + s * 0.014 + mueve, y - s * 0.018),
      pasto,
    );
  }
  const flores = <(double, int)>[
    (0.08, 0xFFFF4081),
    (0.2, 0xFFFFEB3B),
    (0.31, 0xFFE040FB),
    (0.69, 0xFFFF7043),
    (0.8, 0xFFFF4081),
    (0.93, 0xFFFFEB3B),
  ];
  for (final (fx, color) in flores) {
    final x = fx * w;
    final y = _alturaLoma(tam, x, suelo, s * 0.012, 2.5, 1.2) + s * 0.03;
    final c = Offset(x + math.sin(ahora * 1.5 + fx * 9) * s * 0.004, y);
    final r = s * 0.011;
    for (var p = 0; p < 5; p++) {
      final a = p * 2 * math.pi / 5;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r,
        r * 0.8,
        Paint()..color = Color(color),
      );
    }
    canvas.drawCircle(c, r * 0.6, Paint()..color = const Color(0xFFFFF59D));
  }
}

/// La carita del sol (y de la luna): ojitos y sonrisa.
void _caritaDeSol(Canvas canvas, Offset c, double r, double ahora) {
  final oscuro = Paint()..color = const Color(0xFF6D4C41);
  final parpadea = (ahora % 4.2) < 0.15;
  for (final lado in <double>[-1, 1]) {
    final ojo = c + Offset(lado * r * 0.32, -r * 0.12);
    if (parpadea) {
      canvas.drawLine(
        ojo - Offset(r * 0.09, 0),
        ojo + Offset(r * 0.09, 0),
        oscuro
          ..strokeWidth = r * 0.06
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: ojo, width: r * 0.14, height: r * 0.2),
        oscuro,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(lado * r * 0.55, r * 0.18),
        width: r * 0.24,
        height: r * 0.14,
      ),
      Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7),
    );
  }
  canvas.drawArc(
    Rect.fromCenter(
      center: c + Offset(0, r * 0.08),
      width: r * 0.6,
      height: r * 0.5,
    ),
    0.35,
    math.pi - 0.7,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6D4C41),
  );
}

// =============================================================================
//  EL FONDO DEL MAR
// =============================================================================

void _mar(
  Canvas canvas,
  Size tam,
  double suelo,
  double ahora,
  TextStyle? letra,
) {
  final s = tam.shortestSide;
  final w = tam.width;
  final h = tam.height;
  _degradado(
    canvas,
    tam,
    const <int>[0xFF4DD0E1, 0xFF0288D1, 0xFF01579B],
    const <double>[0, 0.5, 1],
  );

  // Rayos de luz que entran desde arriba y se mueven despacito.
  for (var i = 0; i < 4; i++) {
    final x0 =
        w * (0.1 + i * 0.27) + math.sin(ahora * 0.5 + i * 1.7) * s * 0.04;
    final abajo = h * 0.8;
    canvas.drawPath(
      Path()
        ..moveTo(x0 - s * 0.04, 0)
        ..lineTo(x0 + s * 0.05, 0)
        ..lineTo(x0 + s * 0.24, abajo)
        ..lineTo(x0 + s * 0.04, abajo)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, abajo), <Color>[
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0),
        ]),
    );
  }

  // Los peces que nadan (unos para un lado y otros para el otro).
  const peces = <(String, double, double, double, double)>[
    // (pez, altura, tamaño, rapidez, dónde empieza)
    ('🐠', 0.2, 0.14, 0.07, 0.2),
    ('🐟', 0.34, 0.12, 0.1, 0.7),
    ('🐡', 0.48, 0.13, 0.05, 0.45),
    ('🐠', 0.62, 0.11, 0.09, 0.05),
    ('🐟', 0.75, 0.12, 0.06, 0.9),
  ];
  for (var i = 0; i < peces.length; i++) {
    final (pez, y, t, v, x0) = peces[i];
    final izquierda = i.isOdd;
    final x = _pasando(w, x0, v * s, t * s, ahora, haciaLaIzquierda: izquierda);
    final sube = math.sin(ahora * 1.6 + i * 2) * s * 0.015;
    // Los emojis de peces miran a la izquierda: los que van a la derecha
    // se dan vuelta.
    _emoji(
      canvas,
      pez,
      Offset(x, y * h + sube),
      t * s,
      letra,
      espejo: !izquierda,
      opacidad: 0.92,
    );
  }

  // Burbujitas que suben desde el fondo.
  final borde = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.0035
    ..color = Colors.white.withValues(alpha: 0.6);
  final relleno = Paint()..color = Colors.white.withValues(alpha: 0.15);
  for (final (x0, y0, t, ritmo) in _burbujitasMar) {
    final alto = suelo;
    final y = alto - (y0 * alto + ahora * s * (0.05 + 0.06 * ritmo)) % alto;
    final x = x0 * w + math.sin(ahora * 2 + ritmo * 9) * s * 0.012;
    final r = s * (0.006 + 0.01 * t);
    canvas.drawCircle(Offset(x, y), r, relleno);
    canvas.drawCircle(Offset(x, y), r, borde);
  }

  // La arena.
  _loma(canvas, tam, suelo, s * 0.01, 2, 0.4, const Color(0xFFFFE0B2));
  final puntitos = Paint()..color = const Color(0xFFFFCC80);
  for (var i = 0; i < 30; i++) {
    final x = w * ((i * 0.37) % 1);
    canvas.drawCircle(
      Offset(x, suelo + s * (0.02 + 0.04 * ((i * 0.61) % 1))),
      s * 0.004,
      puntitos,
    );
  }

  // Algas que se mueven con el agua (a los lados, para no tapar a la
  // mascota).
  const algas = <(double, double, int)>[
    (0.05, 0.28, 0xFF2E7D32),
    (0.12, 0.2, 0xFF43A047),
    (0.27, 0.16, 0xFF388E3C),
    (0.74, 0.18, 0xFF43A047),
    (0.9, 0.3, 0xFF2E7D32),
    (0.96, 0.17, 0xFF66BB6A),
  ];
  for (var i = 0; i < algas.length; i++) {
    final (ax, alto, color) = algas[i];
    final base = Offset(ax * w, suelo + s * 0.02);
    final camino = Path()..moveTo(base.dx, base.dy);
    const pasos = 8;
    for (var k = 1; k <= pasos; k++) {
      final f = k / pasos;
      final mueve = math.sin(ahora * 1.6 + i + f * 3) * s * 0.03 * f;
      camino.lineTo(base.dx + mueve, base.dy - alto * s * f);
    }
    canvas.drawPath(
      camino,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.024
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color(color),
    );
  }

  // Una estrella de mar, un caracol y un cangrejo que camina.
  final estrellaMar = Offset(w * 0.18, suelo + s * 0.045);
  canvas.drawPath(
    estrella(estrellaMar, s * 0.03, s * 0.014),
    Paint()..color = const Color(0xFFFF8A65),
  );
  canvas.drawPath(
    estrella(estrellaMar, s * 0.03, s * 0.014),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.003
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE64A19),
  );
  final caracol = Offset(w * 0.33, suelo + s * 0.05);
  canvas.drawArc(
    Rect.fromCircle(center: caracol, radius: s * 0.018),
    math.pi,
    math.pi,
    true,
    Paint()..color = const Color(0xFFF8BBD0),
  );
  final cangrejo = Offset(
    w * 0.8 + math.sin(ahora * 0.6) * w * 0.08,
    suelo + s * 0.035,
  );
  _emoji(
    canvas,
    '🦀',
    cangrejo,
    s * 0.07,
    letra,
    giro: math.sin(ahora * 8) * 0.06,
  );
}

// =============================================================================
//  EL ATARDECER
// =============================================================================

void _atardecer(Canvas canvas, Size tam, double suelo, double ahora) {
  final s = tam.shortestSide;
  final w = tam.width;
  final h = tam.height;
  _degradado(
    canvas,
    tam,
    const <int>[0xFF6A3FB5, 0xFFF06292, 0xFFFF8A65, 0xFFFFD54F],
    const <double>[0, 0.42, 0.72, 1],
  );

  // El sol grande que se está escondiendo.
  final sol = Offset(w * 0.3, suelo - s * 0.06);
  final rs = s * 0.18;
  _brillo(canvas, sol, rs * 2.6, const Color(0xFFFFF59D), 0.55);
  canvas.drawCircle(
    sol,
    rs,
    Paint()
      ..shader = ui.Gradient.linear(
        sol - Offset(0, rs),
        sol + Offset(0, rs),
        const <Color>[Color(0xFFFFF176), Color(0xFFFF7043)],
      ),
  );
  // Rayitas del reflejo.
  for (var i = 0; i < 3; i++) {
    final y = sol.dy + rs * (0.25 + i * 0.22);
    canvas.drawLine(
      Offset(sol.dx - rs * 1.05, y),
      Offset(sol.dx + rs * 1.05, y),
      Paint()
        ..strokeWidth = rs * 0.06
        ..color = const Color(0xFFFF8A65).withValues(alpha: 0.8),
    );
  }

  // Nubes alargadas de color rosado.
  const nubes = <(double, double, double, double)>[
    (0.16, 0.12, 0.01, 0.15),
    (0.3, 0.09, 0.014, 0.65),
    (0.48, 0.1, 0.008, 0.4),
  ];
  for (var i = 0; i < nubes.length; i++) {
    final (y, largo, v, x0) = nubes[i];
    final x = _pasando(w, x0, v * s, largo * s * 2, ahora);
    final c = Offset(x, y * h);
    final pintura = Paint()
      ..color = const Color(0xFFFFCCBC).withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: largo * s * 2, height: s * 0.035),
        Radius.circular(s * 0.02),
      ),
      pintura,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(largo * s * 0.3, -s * 0.025),
          width: largo * s * 1.1,
          height: s * 0.035,
        ),
        Radius.circular(s * 0.02),
      ),
      pintura,
    );
  }

  // Pajaritos que vuelan aleteando.
  final ala = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.008
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF4A148C);
  for (var i = 0; i < 4; i++) {
    final x = _pasando(w, i * 0.27, s * (0.05 + 0.01 * i), s * 0.05, ahora);
    final y = h * (0.12 + 0.09 * i) + math.sin(ahora * 1.3 + i) * s * 0.02;
    final a = s * (0.022 + 0.004 * (i % 2));
    final aleteo = math.sin(ahora * 9 + i * 1.3) * a * 0.55;
    canvas.drawPath(
      Path()
        ..moveTo(x - a, y - aleteo)
        ..quadraticBezierTo(x - a * 0.45, y - a * 0.35 - aleteo * 0.3, x, y)
        ..quadraticBezierTo(
          x + a * 0.45,
          y - a * 0.35 - aleteo * 0.3,
          x + a,
          y - aleteo,
        ),
      ala,
    );
  }

  // Las lomas moradas.
  _loma(
    canvas,
    tam,
    suelo - s * 0.07,
    s * 0.035,
    1.2,
    2.2,
    const Color(0xFF9C4D97),
  );
  _loma(canvas, tam, suelo, s * 0.012, 2.2, 0.3, const Color(0xFF5B2A6E));
}

// =============================================================================
//  LA NOCHE CON ESTRELLAS
// =============================================================================

void _noche(Canvas canvas, Size tam, double suelo, double ahora) {
  final s = tam.shortestSide;
  final w = tam.width;
  final h = tam.height;
  _degradado(
    canvas,
    tam,
    const <int>[0xFF0B1035, 0xFF1A237E, 0xFF3949AB],
    const <double>[0, 0.6, 1],
  );

  // Estrellas que brillan.
  for (final (x, y, t, ritmo) in _estrellasNoche) {
    final c = Offset(x * w, y * suelo * 0.92);
    final brillo = 0.35 +
        0.65 * (0.5 + 0.5 * math.sin(ahora * (1 + 2 * ritmo) + ritmo * 20));
    final color = (t > 0.7 ? const Color(0xFFFFF9C4) : Colors.white).withValues(
      alpha: brillo,
    );
    final r = s * (0.003 + 0.006 * t);
    canvas.drawCircle(c, r, Paint()..color = color);
    if (t > 0.75) {
      // Las más grandes, con destello.
      final rayo = Paint()
        ..color = color
        ..strokeWidth = r * 0.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        c - Offset(r * 3 * brillo, 0),
        c + Offset(r * 3 * brillo, 0),
        rayo,
      );
      canvas.drawLine(
        c - Offset(0, r * 3 * brillo),
        c + Offset(0, r * 3 * brillo),
        rayo,
      );
    }
  }

  // La luna (en cuarto creciente), con su brillo.
  final luna = Offset(w * 0.8, h * 0.21);
  final rl = s * 0.085;
  _brillo(canvas, luna, rl * 2.8, const Color(0xFFFFF9C4), 0.35);
  final forma = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: luna, radius: rl)),
    Path()
      ..addOval(
        Rect.fromCircle(
          center: luna + Offset(rl * 0.5, -rl * 0.25),
          radius: rl * 0.85,
        ),
      ),
  );
  canvas.drawPath(forma, Paint()..color = const Color(0xFFFFF59D));
  // Un ojito dormido y una sonrisa en la luna.
  final ojo = luna + Offset(-rl * 0.45, -rl * 0.05);
  canvas.drawArc(
    Rect.fromCenter(center: ojo, width: rl * 0.26, height: rl * 0.2),
    0.2,
    math.pi - 0.4,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rl * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8D6E63),
  );
  canvas.drawArc(
    Rect.fromCenter(
      center: luna + Offset(-rl * 0.42, rl * 0.38),
      width: rl * 0.3,
      height: rl * 0.2,
    ),
    0.3,
    math.pi - 0.6,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rl * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8D6E63),
  );

  // Las lomas, con casitas de ventanas prendidas.
  const lomaLejos = 1.3;
  _loma(
    canvas,
    tam,
    suelo - s * 0.07,
    s * 0.03,
    lomaLejos,
    1.0,
    const Color(0xFF283593),
  );
  for (final (cx, t) in const <(double, double)>[(0.16, 1.0), (0.72, 0.85)]) {
    final x = cx * w;
    final base =
        _alturaLoma(tam, x, suelo - s * 0.07, s * 0.03, lomaLejos, 1.0) +
            s * 0.01;
    final a = s * 0.05 * t;
    final casa = Paint()..color = const Color(0xFF1A237E);
    canvas.drawRect(Rect.fromLTWH(x - a / 2, base - a * 0.8, a, a * 0.8), casa);
    canvas.drawPath(
      Path()
        ..moveTo(x - a * 0.65, base - a * 0.75)
        ..lineTo(x, base - a * 1.3)
        ..lineTo(x + a * 0.65, base - a * 0.75)
        ..close(),
      casa,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, base - a * 0.45),
        width: a * 0.3,
        height: a * 0.28,
      ),
      Paint()..color = const Color(0xFFFFE082),
    );
  }
  _loma(canvas, tam, suelo, s * 0.012, 2.3, 0.8, const Color(0xFF141B4D));

  // Luciérnagas que vuelan cerca del suelo.
  for (final (x0, y0, t, ritmo) in _luciernagas) {
    final c = Offset(
      x0 * w + math.sin(ahora * (0.5 + ritmo) + t * 10) * s * 0.08,
      suelo -
          s * (0.06 + 0.3 * y0) +
          math.cos(ahora * (0.7 + ritmo) + t * 7) * s * 0.04,
    );
    final prende = 0.5 + 0.5 * math.sin(ahora * (2 + 2 * t) + ritmo * 12);
    _brillo(canvas, c, s * 0.03, const Color(0xFFC6FF00), 0.5 * prende);
    canvas.drawCircle(
      c,
      s * 0.006,
      Paint()
        ..color = const Color(0xFFF4FF81).withValues(alpha: 0.4 + 0.6 * prende),
    );
  }
}

// =============================================================================
//  EL ESPACIO
// =============================================================================

void _espacio(
  Canvas canvas,
  Size tam,
  double suelo,
  double ahora,
  TextStyle? letra,
) {
  final s = tam.shortestSide;
  final w = tam.width;
  final h = tam.height;
  _degradado(
    canvas,
    tam,
    const <int>[0xFF07021A, 0xFF1B0B3F, 0xFF311B6B],
    const <double>[0, 0.6, 1],
  );

  // Nubes de colores (nebulosas).
  _brillo(
    canvas,
    Offset(w * 0.25, h * 0.38),
    s * 0.55,
    const Color(0xFF7C4DFF),
    0.3,
  );
  _brillo(
    canvas,
    Offset(w * 0.82, h * 0.62),
    s * 0.5,
    const Color(0xFFFF4081),
    0.2,
  );
  _brillo(
    canvas,
    Offset(w * 0.62, h * 0.12),
    s * 0.4,
    const Color(0xFF18FFFF),
    0.14,
  );

  // Muchas estrellitas.
  const colores = <Color>[Colors.white, Color(0xFFB3E5FC), Color(0xFFFFF9C4)];
  for (var i = 0; i < _estrellasEspacio.length; i++) {
    final (x, y, t, ritmo) = _estrellasEspacio[i];
    final brillo =
        0.3 + 0.7 * (0.5 + 0.5 * math.sin(ahora * (1.5 + 3 * ritmo) + i));
    canvas.drawCircle(
      Offset(x * w, y * suelo),
      s * (0.002 + 0.005 * t),
      Paint()..color = colores[i % colores.length].withValues(alpha: brillo),
    );
  }

  // Una estrella fugaz cada 4 segundos.
  final cual = (ahora / 4).floor();
  final tf = (ahora - cual * 4) / 0.9;
  if (tf >= 0 && tf < 1) {
    final azar = math.Random(cual);
    final inicio = Offset(
      w * (0.35 + 0.6 * azar.nextDouble()),
      h * (0.04 + 0.3 * azar.nextDouble()),
    );
    const dir = Offset(-0.8944, 0.4472);
    final cabeza = inicio + dir * (tf * s * 0.8);
    final cola = cabeza - dir * (s * 0.28);
    final apaga = 1 - tf;
    canvas.drawLine(
      cola,
      cabeza,
      Paint()
        ..strokeWidth = s * 0.008
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(cola, cabeza, <Color>[
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: apaga),
        ]),
    );
    canvas.drawCircle(
      cabeza,
      s * 0.008,
      Paint()..color = Colors.white.withValues(alpha: apaga),
    );
  }

  // El planeta con anillo.
  final planeta = Offset(w * 0.2, h * 0.2);
  final rp = s * 0.075;
  final anillo = Rect.fromCenter(
    center: Offset.zero,
    width: rp * 3.4,
    height: rp * 0.9,
  );
  final pinturaAnillo = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = rp * 0.16
    ..color = const Color(0xFFFFE0B2).withValues(alpha: 0.9);
  canvas.save();
  canvas.translate(planeta.dx, planeta.dy);
  canvas.rotate(-0.35);
  canvas.drawArc(anillo, math.pi, math.pi, false, pinturaAnillo); // atrás
  canvas.restore();
  canvas.drawCircle(
    planeta,
    rp,
    Paint()
      ..shader = ui.Gradient.radial(
        planeta + Offset(-rp * 0.4, -rp * 0.4),
        rp * 1.6,
        const <Color>[Color(0xFFFFCC80), Color(0xFFE65100)],
      ),
  );
  canvas.save();
  canvas.clipPath(
    Path()..addOval(Rect.fromCircle(center: planeta, radius: rp)),
  );
  for (final y in <double>[-0.35, 0.1, 0.5]) {
    canvas.drawRect(
      Rect.fromLTWH(planeta.dx - rp, planeta.dy + y * rp, rp * 2, rp * 0.16),
      Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.6),
    );
  }
  canvas.restore();
  canvas.save();
  canvas.translate(planeta.dx, planeta.dy);
  canvas.rotate(-0.35);
  canvas.drawArc(anillo, 0, math.pi, false, pinturaAnillo); // adelante
  canvas.restore();

  // Un planeta azul chiquito.
  final azul = Offset(w * 0.86, h * 0.42);
  final ra = s * 0.045;
  canvas.drawCircle(
    azul,
    ra,
    Paint()
      ..shader = ui.Gradient.radial(
        azul + Offset(-ra * 0.4, -ra * 0.4),
        ra * 1.6,
        const <Color>[Color(0xFF80DEEA), Color(0xFF00838F)],
      ),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: azul + Offset(ra * 0.2, ra * 0.1),
      width: ra * 0.8,
      height: ra * 0.5,
    ),
    Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.8),
  );

  // Un cohete que pasa cada tanto.
  final vuelta = ahora % 14;
  if (vuelta < 5) {
    final f = vuelta / 5;
    final c = Offset(-w * 0.1 + f * w * 1.2, h * 0.78 - f * h * 0.72);
    for (var k = 1; k <= 4; k++) {
      final p = c + Offset(-s * 0.03 * k, s * 0.03 * k);
      canvas.drawCircle(
        p,
        s * (0.018 - 0.003 * k),
        Paint()
          ..color =
              (k.isEven ? const Color(0xFFFFEB3B) : const Color(0xFFFF7043))
                  .withValues(alpha: 0.8 - 0.15 * k),
      );
    }
    _emoji(canvas, '🚀', c, s * 0.1, letra);
  }

  // El suelo de la luna, con cráteres.
  _loma(canvas, tam, suelo, s * 0.01, 1.8, 0.5, const Color(0xFFB0BEC5));
  for (final (cx, cy, r) in const <(double, double, double)>[
    (0.12, 0.04, 0.035),
    (0.3, 0.07, 0.022),
    (0.72, 0.05, 0.03),
    (0.9, 0.08, 0.02),
  ]) {
    final c = Offset(cx * w, suelo + cy * s);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * s * 2, height: r * s * 0.8),
      Paint()..color = const Color(0xFF90A4AE),
    );
    canvas.drawArc(
      Rect.fromCenter(center: c, width: r * s * 2, height: r * s * 0.8),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.004
        ..color = const Color(0xFFECEFF1),
    );
  }
}
