import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';

/// Los colores del dibujo: tarritos redondos de pintura sobre una bandeja
/// blanca, en una sola fila (cada dibujo tiene como mucho 5 colores). Los
/// colores no se acaban.
///
/// - El elegido se agranda, rebota y muestra una estrellita.
/// - Si no hay ninguno elegido, los tarritos saltan uno tras otro, como
///   diciendo "¡elígeme!".
/// - Mientras la voz habla, la paleta queda [bloqueada].
class Paleta extends StatefulWidget {
  const Paleta({
    super.key,
    required this.colores,
    required this.seleccionado,
    required this.alElegir,
    this.bloqueada = false,
    this.cargando = false,
  });

  /// Los colores del dibujo (como mucho 5).
  final List<ColorConNombre> colores;

  /// El color elegido (null si no hay ninguno).
  final ColorConNombre? seleccionado;

  final ValueChanged<ColorConNombre> alElegir;

  final bool bloqueada;

  /// true mientras se lee la paleta del dibujo: la bandeja se ve vacía.
  final bool cargando;

  @override
  State<Paleta> createState() => _EstadoPaleta();
}

class _EstadoPaleta extends State<Paleta> with SingleTickerProviderStateMixin {
  /// Los saltitos de "¡elígeme!" (una vuelta cada 1,6 segundos).
  late final AnimationController _saltos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _pideColor =>
      widget.seleccionado == null && !widget.cargando && !widget.bloqueada;

  @override
  void initState() {
    super.initState();
    _actualizarSaltos();
  }

  @override
  void didUpdateWidget(covariant Paleta anterior) {
    super.didUpdateWidget(anterior);
    _actualizarSaltos();
  }

  void _actualizarSaltos() {
    if (_pideColor) {
      if (!_saltos.isAnimating) _saltos.repeat();
    } else if (_saltos.isAnimating || _saltos.value != 0) {
      _saltos.stop();
      _saltos.value = 0;
    }
  }

  @override
  void dispose() {
    _saltos.dispose();
    super.dispose();
  }

  /// Cuánto sube el tarrito [i] ahora (0 a 1): una ola que pasa de
  /// izquierda a derecha, con una pausa entre ola y ola.
  double _salto(int i) {
    final fase = _saltos.value * 1.6 - i * 0.12;
    if (fase < 0 || fase > 0.35) return 0;
    return math.sin(fase / 0.35 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final colores = widget.colores;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE0A3), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // Lugar para 5 tarritos en fila, aunque el dibujo tenga menos.
          final cupo = math.max(Ajustes.maxColoresPorDibujo, colores.length);
          final ranura =
              (restricciones.maxWidth / cupo).clamp(44.0, 90.0).toDouble();
          final tamano = (ranura / 1.22).clamp(36.0, 72.0).toDouble();
          if (widget.cargando) return SizedBox(height: ranura);
          return SizedBox(
            height: ranura,
            child: AnimatedBuilder(
              animation: _saltos,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < colores.length; i++)
                    SizedBox(
                      width: ranura,
                      child: Transform.translate(
                        offset: Offset(0, -tamano * 0.16 * _salto(i)),
                        child: _Tarrito(
                          color: colores[i].color,
                          tamano: tamano,
                          elegido:
                              colores[i].color == widget.seleccionado?.color,
                          apagado: widget.bloqueada &&
                              colores[i].color != widget.seleccionado?.color,
                          alTocar: widget.bloqueada
                              ? null
                              : () => widget.alElegir(colores[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tarrito extends StatelessWidget {
  const _Tarrito({
    required this.color,
    required this.tamano,
    required this.elegido,
    required this.apagado,
    required this.alTocar,
  });

  final Color color;
  final double tamano;
  final bool elegido;
  final bool apagado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final double escala = elegido ? 1.12 : 0.92;
    final double opacidad = apagado ? 0.35 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: SizedBox(
        width: tamano * 1.12,
        height: tamano * 1.12,
        child: Center(
          child: AnimatedOpacity(
            opacity: opacidad,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: escala,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: SizedBox(
                width: tamano,
                height: tamano,
                child: CustomPaint(
                  painter: _PintorTarrito(color: color, elegido: elegido),
                  child: Center(
                    child: elegido
                        ? Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: tamano * 0.5,
                            shadows: const <Shadow>[
                              Shadow(color: Color(0x66000000), blurRadius: 4),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja un tarrito redondo lleno de pintura, con un brillo de vidrio.
class _PintorTarrito extends CustomPainter {
  _PintorTarrito({required this.color, required this.elegido});

  final Color color;
  final bool elegido;

  Color _tono(double cambio) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + cambio).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final circulo = Rect.fromCircle(center: centro, radius: radio);
    final oscuro = _tono(-0.16);

    // Anillo de color cuando está elegido.
    if (elegido) {
      canvas.drawCircle(centro, radio + 4, Paint()..color = oscuro);
    }
    // Sombra.
    canvas.drawCircle(
      centro.translate(0, 3),
      radio,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // La pintura.
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: <Color>[_tono(0.18), color, oscuro],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(circulo),
    );
    // Borde.
    canvas.drawCircle(
      centro,
      radio - (elegido ? 2 : 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = elegido ? 4 : 2
        ..color = elegido ? Colors.white : oscuro,
    );
    // Brillo, para que parezca de vidrio.
    final brillo = Rect.fromLTWH(
      centro.dx - radio * 0.6,
      centro.dy - radio * 0.72,
      radio * 0.6,
      radio * 0.36,
    );
    canvas.drawOval(brillo, Paint()..color = const Color(0x99FFFFFF));
  }

  @override
  bool shouldRepaint(covariant _PintorTarrito oldDelegate) =>
      oldDelegate.color != color || oldDelegate.elegido != elegido;
}
