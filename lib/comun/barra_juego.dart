import 'package:flutter/material.dart';

import 'package:colorear_ninos/comun/botones.dart';

/// La barra de los juegos:
///  - la casita (vuelve al menú de juegos);
///  - las estrellas que ganó en este juego (y, si el juego la tiene, al
///    costadito, la barrita de cuánto le falta: [progreso]);
///  - la orejita (la voz repite lo que hay que hacer).
///
/// Normalmente va arriba, de izquierda a derecha. Si es [vertical] (con la
/// pantalla acostada) va a la izquierda, de arriba a abajo, así el juego
/// gana todo el alto de la pantalla.
class BarraJuego extends StatelessWidget {
  const BarraJuego({
    super.key,
    required this.estrellas,
    required this.alRepetir,
    this.progreso,
    this.vertical = false,
  });

  /// Cuántas estrellas lleva (una por acierto).
  final int estrellas;

  /// Qué hacer al tocar la orejita.
  final VoidCallback alRepetir;

  /// Lo que va al costadito de las estrellas (la barrita de cuánto falta).
  final Widget? progreso;

  /// true = de arriba a abajo, al costado de la pantalla.
  final bool vertical;

  static const double _boton = 64;

  @override
  Widget build(BuildContext context) {
    final casita = BotonGrande(
      key: const ValueKey<String>('casita'),
      icono: Icons.home_rounded,
      color: const Color(0xFF1E88E5),
      alTocar: () => Navigator.of(context).maybePop(),
    );
    final orejita = BotonGrande(
      key: const ValueKey<String>('repetir'),
      icono: Icons.hearing_rounded,
      color: const Color(0xFF8E24AA),
      alTocar: alRepetir,
    );
    final progreso = this.progreso;
    if (vertical) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: SizedBox(
          width: _boton,
          child: Column(
            children: [
              casita,
              const SizedBox(height: 10),
              _estrellas(enColumna: true),
              const SizedBox(height: 10),
              Expanded(child: progreso ?? const SizedBox.shrink()),
              const SizedBox(height: 10),
              orejita,
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          casita,
          if (progreso == null)
            Expanded(child: Center(child: _estrellas()))
          else ...[
            const SizedBox(width: 10),
            _estrellas(),
            const SizedBox(width: 10),
            Expanded(child: SizedBox(height: _boton, child: progreso)),
            const SizedBox(width: 10),
          ],
          orejita,
        ],
      ),
    );
  }

  /// Las estrellas: en fila (⭐ 12), o una sobre la otra si [enColumna].
  Widget _estrellas({bool enColumna = false}) {
    const estrella =
        Icon(Icons.star_rounded, color: Color(0xFFFDD835), size: 40);
    final numero = Text(
      '$estrellas',
      key: const ValueKey<String>('estrellas'),
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFB8C00),
      ),
    );
    return Container(
      padding: enColumna
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 6),
        ],
      ),
      child: enColumna
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                estrella,
                FittedBox(fit: BoxFit.scaleDown, child: numero),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [estrella, const SizedBox(width: 4), numero],
            ),
    );
  }
}
