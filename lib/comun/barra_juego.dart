import 'package:flutter/material.dart';

import 'package:colorear_ninos/comun/botones.dart';

/// La barra de arriba de los juegos:
///  - a la izquierda, la casita (vuelve al menú de juegos);
///  - en el medio, las estrellas que ganó en este juego;
///  - a la derecha, la orejita (la voz repite lo que hay que hacer).
class BarraJuego extends StatelessWidget {
  const BarraJuego({
    super.key,
    required this.estrellas,
    required this.alRepetir,
  });

  /// Cuántas estrellas lleva (una por acierto).
  final int estrellas;

  /// Qué hacer al tocar la orejita.
  final VoidCallback alRepetir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          BotonGrande(
            key: const ValueKey<String>('casita'),
            icono: Icons.home_rounded,
            color: const Color(0xFF1E88E5),
            alTocar: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x22000000), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFDD835), size: 40),
                    const SizedBox(width: 4),
                    Text(
                      '$estrellas',
                      key: const ValueKey<String>('estrellas'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFB8C00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BotonGrande(
            key: const ValueKey<String>('repetir'),
            icono: Icons.hearing_rounded,
            color: const Color(0xFF8E24AA),
            alTocar: alRepetir,
          ),
        ],
      ),
    );
  }
}
