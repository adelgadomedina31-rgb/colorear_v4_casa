import 'package:flutter/material.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';

/// En una tablet, toda la app se agranda en la misma proporción.
///
/// La app está pensada para el tamaño de un celular. En una pantalla grande
/// (como una tablet de 10 pulgadas), los botones y las letras se verían
/// chiquitos. Por eso aquí la app se arma como si la pantalla tuviera el
/// ancho de un celular grande ([AjustesApp.anchoComoCelular]) y después se
/// agranda hasta llenar la tablet: todo se ve igual que en el celular, pero
/// más grande y nítido (se dibuja directo al tamaño de la tablet, no es una
/// foto estirada).
///
/// En un celular no hace nada. Se activa o desactiva en ajustes_app.dart
/// ([AjustesApp.agrandarEnTablet]).
class PantallaGrande extends StatelessWidget {
  const PantallaGrande({super.key, required this.child});

  final Widget child;

  /// Cuánto se agranda todo en una pantalla de tamaño [tam] (1 = nada).
  static double cuantoAgrandar(Size tam) {
    if (!AjustesApp.agrandarEnTablet) return 1;
    final ancho = AjustesApp.anchoComoCelular.clamp(320.0, 2000.0);
    final lado = tam.shortestSide;
    if (lado <= ancho) return 1;
    // Nunca más del triple, por si acaso.
    return (lado / ancho).clamp(1.0, 3.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final datos = MediaQuery.of(context);
    final veces = cuantoAgrandar(datos.size);
    if (veces <= 1.01) return child;
    final tam = datos.size / veces;
    return MediaQuery(
      data: datos.copyWith(
        size: tam,
        // Así las imágenes que se arman por dentro (las líneas del dibujo)
        // salen con todos los puntitos de la tablet.
        devicePixelRatio: datos.devicePixelRatio * veces,
        padding: datos.padding / veces,
        viewPadding: datos.viewPadding / veces,
        viewInsets: datos.viewInsets / veces,
        systemGestureInsets: datos.systemGestureInsets / veces,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(width: tam.width, height: tam.height, child: child),
      ),
    );
  }
}
