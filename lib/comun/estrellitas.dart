import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Estrellitas de colores que salen volando desde el centro y se apagan
/// (cuando acierta). Se ponen encima de lo que acertó y desaparecen solas.
/// No se pueden tocar: los toques pasan a lo que está debajo.
class Estrellitas extends StatefulWidget {
  const Estrellitas({super.key, this.cantidad = 12, this.duracionMs = 1100});

  /// Cuántas estrellitas salen.
  final int cantidad;

  /// Cuánto dura el estallido (milisegundos).
  final int duracionMs;

  @override
  State<Estrellitas> createState() => _EstadoEstrellitas();
}

class _EstadoEstrellitas extends State<Estrellitas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.duracionMs),
  )..forward();

  static const List<Color> _colores = <Color>[
    Color(0xFFFDD835),
    Color(0xFFFB8C00),
    Color(0xFFEC407A),
    Color(0xFF1E88E5),
    Color(0xFF7CB342),
    Color(0xFF8E24AA),
  ];

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animacion,
        builder: (context, _) => LayoutBuilder(
          builder: (context, caja) {
            final t = Curves.easeOut.transform(_animacion.value);
            final tam = caja.biggest;
            final centro = Offset(tam.width / 2, tam.height / 2);
            final lejos = math.max(tam.width, tam.height) * 0.75;
            final estrellas = <Widget>[];
            for (var i = 0; i < widget.cantidad; i++) {
              final angulo = 2 * math.pi * i / widget.cantidad + 0.3;
              final donde = centro +
                  Offset(math.cos(angulo), math.sin(angulo)) * (lejos * t);
              final lado = 22.0 + 12 * (i % 3);
              estrellas.add(Positioned(
                left: donde.dx - lado / 2,
                top: donde.dy - lado / 2,
                width: lado,
                height: lado,
                child: Opacity(
                  opacity: (1 - _animacion.value).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: t * math.pi,
                    child: Icon(
                      Icons.star_rounded,
                      size: lado,
                      color: _colores[i % _colores.length],
                    ),
                  ),
                ),
              ));
            }
            return Stack(clipBehavior: Clip.none, children: estrellas);
          },
        ),
      ),
    );
  }
}
