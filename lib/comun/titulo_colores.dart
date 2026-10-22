import 'package:flutter/material.dart';

/// Un título grande con cada letra de un color (por ejemplo, "COLOREA
/// ARLETH"). Si no cabe, se achica en vez de cortarse.
class TituloColores extends StatelessWidget {
  const TituloColores(this.texto, {super.key, this.tamano = 40});

  final String texto;
  final double tamano;

  static const List<Color> _colores = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    final letras = <TextSpan>[];
    // Cuenta solo las letras, para que los colores no salten con el espacio.
    var n = 0;
    for (var i = 0; i < texto.length; i++) {
      final letra = texto[i];
      if (letra == ' ') {
        letras.add(const TextSpan(text: ' '));
      } else {
        letras.add(
          TextSpan(
            text: letra,
            style: TextStyle(color: _colores[n % _colores.length]),
          ),
        );
        n++;
      }
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          children: letras,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
