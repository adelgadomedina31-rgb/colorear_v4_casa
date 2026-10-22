import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:colorear_ninos/juegos/burbujas/animaciones.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/dibujos.dart';
import 'package:colorear_ninos/juegos/burbujas/mundos.dart';

/// Cómo se mueve un animalito cuando va de un lado a otro.
enum Andar {
  /// Camina con sus patitas (la animación avanza mientras camina y se
  /// detiene cuando para).
  camina,

  /// Va dando saltitos (como el pollito en su cascarón).
  salta,

  /// Nada, subiendo y bajando suavecito (el pez).
  nada,
}

/// Lo que hay que saber de cada animación para moverla bien. Todas las
/// medidas son partes del dibujo (0 = izquierda o arriba, 1 = derecha o
/// abajo) mirando hacia la izquierda.
class ComoEsLaMascota {
  const ComoEsLaMascota({
    this.andar = Andar.salta,
    this.miraALaIzquierda = true,
    this.tamano = 1.0,
    this.rapidez = 0.45,
    this.paradas = const <double>[0],
    this.boca = const Offset(0.3, 0.35),
    this.cabeza = const Offset(0.3, 0.35),
    this.radioCasco = 0.35,
  });

  final Andar andar;

  /// true = en la animación mira hacia la izquierda.
  final bool miraALaIzquierda;

  /// Más grande o más chica que las demás (1 = normal).
  final double tamano;

  /// Cuánto avanza por segundo caminando (en "anchos" de la mascota), con
  /// la animación a su velocidad normal.
  final double rapidez;

  /// En qué momentos de la animación (0 a 1) puede quedarse quieta (con las
  /// patitas juntas). Solo para [Andar.camina].
  final List<double> paradas;

  /// Por dónde salen las burbujas que sopla.
  final Offset boca;

  /// El centro de la cabeza y el tamaño del casco de astronauta (parte del
  /// alto).
  final Offset cabeza;
  final double radioCasco;

  /// Los datos de cada animación de assets/mascotas/ (las que no están aquí
  /// usan los de [ComoEsLaMascota.new], que andan bien para casi todas).
  static const Map<String, ComoEsLaMascota> deCadaAnimacion =
      <String, ComoEsLaMascota>{
    'perrito.json': ComoEsLaMascota(
      andar: Andar.camina,
      rapidez: 0.7,
      paradas: <double>[0, 0.5],
      boca: Offset(0.1, 0.4),
      cabeza: Offset(0.22, 0.3),
      radioCasco: 0.27,
    ),
    'gatito.json': ComoEsLaMascota(
      andar: Andar.camina,
      tamano: 0.95,
      rapidez: 0.3,
      paradas: <double>[0, 0.25, 0.5, 0.75],
      boca: Offset(0.18, 0.45),
      cabeza: Offset(0.2, 0.38),
      radioCasco: 0.3,
    ),
    'pollito.json': ComoEsLaMascota(
      andar: Andar.salta,
      rapidez: 0.5,
      boca: Offset(0.4, 0.3),
      cabeza: Offset(0.5, 0.33),
      radioCasco: 0.36,
    ),
    'pececito.json': ComoEsLaMascota(
      andar: Andar.nada,
      tamano: 0.9,
      rapidez: 0.55,
      boca: Offset(0.06, 0.58),
      cabeza: Offset(0.35, 0.5),
      radioCasco: 0.5,
    ),
  };

  /// Para un emoji (sin animación): va dando saltitos.
  static const ComoEsLaMascota deUnEmoji = ComoEsLaMascota(
    boca: Offset(0.5, 0.3),
    cabeza: Offset(0.5, 0.46),
    radioCasco: 0.6,
  );

  static ComoEsLaMascota para(String? ruta) {
    if (ruta == null) return deUnEmoji;
    final nombre = ruta.split('/').last;
    return deCadaAnimacion[nombre] ?? const ComoEsLaMascota();
  }
}

/// La mascota de cada nivel: está abajo, camina y corre de un lado a otro,
/// sopla burbujas, se ríe si la tocan y aplaude al pasar de nivel.
class Mascota {
  Mascota(this.emoji, this.mundo, {math.Random? azar})
      : ruta = AjustesBurbujas.animacionesMascotas[emoji],
        _azar = azar ?? math.Random() {
    como = ComoEsLaMascota.para(ruta);
  }

  /// El animalito ('🐥', '🐶'...).
  final String emoji;

  /// El mundo donde está (en el espacio lleva casco de astronauta).
  final Mundo mundo;

  /// La animación (assets/mascotas/...), o null si se ve el emoji.
  final String? ruta;

  late final ComoEsLaMascota como;

  final math.Random _azar;

  /// Cuándo sopló la última burbuja, cuándo saltó (al tocarla) y entre
  /// cuándo y cuándo aplaude (segundos del juego).
  double soplo = -10;
  double salto = -10;
  double aplaudeDesde = -10;
  double aplaudeHasta = -10;

  /// Cuándo apareció (llega dando un saltito). Si la animación todavía se
  /// estaba cargando, cuenta desde que se ve.
  double llega = -10;

  static const double duracionSoplo = 0.45;
  static const double duracionSalto = 0.7;
  static const double duracionLlegada = 0.6;

  // --------------------------------------------------------- cómo se mueve

  /// Dónde está: 0 = borde izquierdo de la pantalla, 1 = borde derecho (el
  /// centro de la mascota).
  double x = 0.5;
  double _destino = 0.5;
  bool _paseando = false;
  double? _quietaHasta;

  /// true = va corriendo (más rápido).
  bool corriendo = false;

  /// Hacia dónde mira: -1 = izquierda, 1 = derecha.
  double mira = -1;

  /// Hacia dónde se ve que mira: va de -1 a 1 de a poco (para darse vuelta).
  double miraVista = -1;

  /// Cuánto avanza ahora (puntos por segundo; 0 = quieta).
  double velocidad = 0;

  /// En qué parte de la animación va (de 0 a 1).
  double avance = 0;

  /// En qué parte del saltito va (para [Andar.salta]).
  double fase = 0;

  bool _seVeia = false;

  double _entre(double a, double b) => a + (b - a) * _azar.nextDouble();

  bool aplaudiendo(double ahora) =>
      ahora >= aplaudeDesde && ahora < aplaudeHasta;

  bool saltando(double ahora) => ahora - salto < duracionSalto;

  bool llegando(double ahora) => ahora - llega < duracionLlegada;

  /// true = va de un lado a otro.
  bool get paseando => _paseando;

  /// La animación, si ya está cargada.
  LottieDrawable? get dibujo => Animaciones.de(ruta);

  /// El alto de la mascota en una zona de juego de tamaño [zona].
  double altoPara(Size zona) =>
      zona.shortestSide * AjustesBurbujas.tamanoMascota * como.tamano;

  /// El tamaño (ancho y alto) de la mascota.
  Size tamanoPara(Size zona) {
    final alto = altoPara(zona);
    final d = dibujo;
    final proporcion =
        d == null || d.size.height <= 0 ? 1.0 : d.size.width / d.size.height;
    return Size(alto * proporcion, alto);
  }

  /// Dónde está (sin contar los saltos), para dibujarla y saber si la
  /// tocaron.
  Rect lugar(Size zona) {
    final t = tamanoPara(zona);
    final elevada = como.andar == Andar.nada ? t.height * 0.2 : 0.0;
    return Rect.fromLTWH(
      x * zona.width - t.width / 2,
      zona.height - 2 - elevada - t.height,
      t.width,
      t.height,
    );
  }

  /// Un punto del dibujo ([parte] mirando a la izquierda) en la pantalla,
  /// según hacia dónde mira ahora.
  Offset punto(Size zona, Offset parte) {
    final l = lugar(zona);
    return Offset(
      l.center.dx + (parte.dx - 0.5) * l.width * espejo,
      l.top + parte.dy * l.height,
    );
  }

  /// 1 = se ve como en la animación; -1 = dada vuelta (y en el medio,
  /// mientras gira).
  double get espejo {
    final v = como.miraALaIzquierda ? -miraVista : miraVista;
    if (v.abs() >= 0.05) return v;
    final hacia = como.miraALaIzquierda ? -mira : mira;
    return hacia >= 0 ? 0.05 : -0.05;
  }

  /// Por dónde salen las burbujas que sopla.
  Offset boca(Size zona) => punto(zona, como.boca);

  /// Los bordes donde puede caminar (de 0 a 1).
  (double, double) _limites(Size zona) {
    if (zona.width <= 0) return (0.5, 0.5);
    final medio = (tamanoPara(zona).width / 2 + 4) / zona.width;
    final zonaMascota = AjustesBurbujas.zonaDeLaMascota.clamp(0.0, 1.0);
    final desde = math.max(0.5 - zonaMascota / 2 + medio, medio);
    final hasta = math.min(0.5 + zonaMascota / 2 - medio, 1 - medio);
    if (hasta <= desde) return (0.5, 0.5);
    return (desde, hasta);
  }

  /// Mueve la mascota (se llama en cada cuadro del juego).
  void mover(double dt, double ahora, Size zona) {
    // Si la animación recién se terminó de cargar: llega con un saltito.
    // Al aparecer se queda quieta un ratito antes de pasear.
    _quietaHasta ??= ahora + _entre(1.2, 2.2);
    final seVe = dibujo != null || !Animaciones.cargando(ruta);
    if (seVe && !_seVeia && dibujo != null) {
      llega = ahora;
      _quietaHasta = math.max(_quietaHasta!, ahora + 1.0);
    }
    _seVeia = seVe;

    final (desde, hasta) = _limites(zona);
    final ancho = tamanoPara(zona).width;
    final rapidezNormal = como.rapidez * ancho;
    final ocupada = aplaudiendo(ahora) || saltando(ahora) || llegando(ahora);
    var objetivo = 0.0;
    if (!AjustesBurbujas.mascotaCamina || zona.width <= 0) {
      _paseando = false;
    } else if (!ocupada) {
      if (_paseando) {
        final falta = (_destino - x) * zona.width;
        if (falta.abs() < 1) {
          _paseando = false;
          corriendo = false;
          _quietaHasta = ahora +
              _entre(
                AjustesBurbujas.segundosQuietaMinimo,
                AjustesBurbujas.segundosQuietaMaximo,
              );
        } else {
          objetivo = rapidezNormal *
              (corriendo ? AjustesBurbujas.rapidezCorriendo : 1.0);
        }
      } else if (ahora >= _quietaHasta! && hasta > desde) {
        _pasear(desde, hasta);
      }
    }
    velocidad = objetivo;

    // Camina.
    if (velocidad > 0) {
      final falta = (_destino - x) * zona.width;
      final paso = math.min(falta.abs(), velocidad * dt);
      x += falta.sign * paso / zona.width;
    }
    // Si la pantalla cambió de tamaño, que no quede afuera.
    if (hasta > desde) x = x.clamp(desde, hasta);

    // Se da vuelta de a poco (en 0.2 segundos).
    final giro = dt / 0.1;
    if (miraVista < mira) miraVista = math.min(mira, miraVista + giro);
    if (miraVista > mira) miraVista = math.max(mira, miraVista - giro);

    _animar(dt, rapidezNormal);
  }

  void _pasear(double desde, double hasta) {
    // Un lugar nuevo, no muy cerca de donde está.
    var destino = x;
    for (var intento = 0; intento < 6; intento++) {
      destino = _entre(desde, hasta);
      if ((destino - x).abs() >= (hasta - desde) * 0.3) break;
    }
    if ((destino - x).abs() < 0.01) return;
    _destino = destino;
    _paseando = true;
    corriendo = _azar.nextDouble() < AjustesBurbujas.parteQueCorre &&
        (destino - x).abs() > (hasta - desde) * 0.35;
    mira = destino > x ? 1 : -1;
  }

  /// Hace avanzar la animación.
  void _animar(double dt, double rapidezNormal) {
    final d = dibujo;
    final duracion = d == null ? 1.0 : math.max(0.1, d.composition.seconds);
    final rapido = corriendo ? AjustesBurbujas.rapidezCorriendo : 1.0;
    switch (como.andar) {
      case Andar.camina:
        if (velocidad > 0) {
          avance = (avance + dt / duracion * velocidad / rapidezNormal) % 1;
        } else {
          // Quieta: termina el paso hasta tener las patitas juntas.
          final siguiente = avance + dt / duracion;
          for (final p in <double>[...como.paradas, 1]) {
            if (avance < p && siguiente >= p || (avance - p).abs() < 1e-6) {
              avance = p % 1;
              return;
            }
          }
          avance = siguiente % 1;
        }
      case Andar.salta:
      case Andar.nada:
        avance = (avance + dt / duracion * (velocidad > 0 ? rapido : 1)) % 1;
    }
    // Los saltitos: siguen mientras camina; al parar termina el que está.
    if (velocidad > 0) {
      fase += dt * math.pi * (corriendo ? 3.4 : 2.4);
    } else if (fase % math.pi != 0) {
      final siguiente = fase + dt * math.pi * 2.4;
      final fin = (fase / math.pi).floor() * math.pi + math.pi;
      fase = siguiente >= fin ? 0 : siguiente;
    }
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
  final dibujo = m.dibujo;
  // Mientras se carga la animación (muy poquito) no se ve.
  if (dibujo == null && Animaciones.cargando(m.ruta)) return;
  final imagen = dibujo == null ? Dibujos.emoji(m.emoji, letra) : null;
  if (dibujo == null && imagen == null) return;
  final lugar = m.lugar(zona);
  final t = lugar.height;
  final grande = math.max(lugar.width, lugar.height);
  var centro = lugar.center;

  // Respira (sube y baja suavecito).
  var subir = math.sin(ahora * 2.2) * t * 0.02;
  var ancho = 1.0;
  var alto = 1.0 + 0.025 * math.sin(ahora * 2.2);
  var giro = 0.0;

  // Va dando saltitos (o nadando, sube y baja).
  switch (m.como.andar) {
    case Andar.salta:
      final s = math.sin(m.fase).abs();
      subir += s * t * 0.16;
      // Se aplasta un poquito al tocar el suelo.
      if (m.fase != 0 && s < 0.25) {
        ancho += 0.08 * (1 - s / 0.25);
        alto -= 0.08 * (1 - s / 0.25);
      }
    case Andar.nada:
      subir += math.sin(ahora * 2.4) * t * 0.08;
      if (m.velocidad > 0) giro = -m.miraVista.sign * 0.06;
    case Andar.camina:
      break;
  }

  // Llega dando un saltito.
  final llegada = (ahora - m.llega) / Mascota.duracionLlegada;
  var aparece = 1.0;
  if (llegada >= 0 && llegada < 1) {
    aparece = Curves.easeOutBack.transform(llegada);
    subir += math.sin(llegada * math.pi) * t * 0.4;
  }

  // Al soplar se infla un poquito.
  final soplo = (ahora - m.soplo) / Mascota.duracionSoplo;
  if (soplo >= 0 && soplo < 1) {
    final f = math.sin(soplo * math.pi);
    ancho += 0.1 * f;
    alto -= 0.05 * f;
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
  final piso = zona.height - 2 - t * 0.04;
  final enElAire =
      ((zona.height - 2 - lugar.bottom + subir) / t).clamp(0.0, 1.0);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(lugar.center.dx, piso),
      width: lugar.width * 0.7 * (1 - 0.4 * enElAire) * aparece,
      height: t * 0.12 * (1 - 0.4 * enElAire) * aparece,
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * (1 - 0.5 * enElAire)),
  );

  // Hacia dónde mira: la animación se da vuelta (y se ve finita justo
  // cuando gira).
  canvas.save();
  canvas.translate(centro.dx, centro.dy);
  canvas.rotate(giro);
  canvas.scale(ancho * aparece * m.espejo, alto * aparece);
  if (dibujo != null) {
    dibujo.setProgress(m.avance);
    dibujo.draw(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: lugar.width,
        height: lugar.height,
      ),
      fit: BoxFit.fill,
    );
  } else {
    dibujarImagen(canvas, imagen!, Offset.zero, t, 1);
  }
  if (m.mundo == Mundo.espacio) {
    final c = m.como.cabeza;
    _casco(
      canvas,
      Offset((c.dx - 0.5) * lugar.width, (c.dy - 0.5) * lugar.height),
      t * m.como.radioCasco,
    );
  }
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
      final p = centro +
          Offset(math.cos(a), math.sin(a)) * grande * (0.55 + 0.4 * salto);
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
        final p = centro + Offset(lado * (lugar.width / 2 + t * 0.2), -t * 0.2);
        dibujarImagen(canvas, manos, p, t * (0.42 + 0.12 * golpe), 1);
      }
    }
  }
}

/// El casco de astronauta (en el espacio), con centro [c] y radio [r].
void _casco(Canvas canvas, Offset c, double r) {
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
      ..strokeWidth = r * 0.075
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
      ..strokeWidth = r * 0.083
      ..color = Colors.white.withValues(alpha: 0.75),
  );
  // La antenita.
  final base = c - Offset(0, r);
  canvas.drawLine(
    base,
    base - Offset(0, r * 0.23),
    Paint()
      ..strokeWidth = r * 0.042
      ..color = Colors.white,
  );
  canvas.drawCircle(
    base - Offset(0, r * 0.27),
    r * 0.067,
    Paint()..color = const Color(0xFFFF5252),
  );
}
