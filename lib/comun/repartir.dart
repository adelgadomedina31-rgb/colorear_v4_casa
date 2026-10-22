import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Reparte [cantidad] cosas (globos, tarjetas...) en un espacio de tamaño
/// [tam], lo más grandes posible: prueba con 1, 2, 3... columnas y se queda
/// con la forma en que cada una sale más grande. Por ejemplo, en un celular
/// 2 cosas van una arriba de otra, y 4 van de dos en dos.
///
/// [proporcion] es ancho / alto de cada cosa (1 = cuadrada).
/// [relleno] es cuánto de su lugar ocupa cada una (0.88 = deja un poco de
/// espacio entre ellas).
/// Devuelve dónde va cada una.
List<Rect> repartir(
  Size tam,
  int cantidad, {
  double proporcion = 1,
  double relleno = 0.88,
}) {
  if (cantidad <= 0) return const <Rect>[];
  var mejorColumnas = 1;
  var mejorAncho = 0.0;
  for (var columnas = 1; columnas <= cantidad; columnas++) {
    final filas = (cantidad / columnas).ceil();
    final ancho = math.min(
      tam.width / columnas,
      tam.height / filas * proporcion,
    );
    if (ancho > mejorAncho + 0.5) {
      mejorAncho = ancho;
      mejorColumnas = columnas;
    }
  }
  final columnas = mejorColumnas;
  final filas = (cantidad / columnas).ceil();
  final anchoCelda = tam.width / columnas;
  final altoCelda = tam.height / filas;
  final ancho = mejorAncho * relleno;
  final alto = ancho / proporcion;
  final lugares = <Rect>[];
  for (var i = 0; i < cantidad; i++) {
    final fila = i ~/ columnas;
    final columna = i % columnas;
    // La última fila, si tiene menos, queda centrada.
    final enEstaFila = math.min(columnas, cantidad - fila * columnas);
    final izquierda = (tam.width - enEstaFila * anchoCelda) / 2;
    final centro = Offset(
      izquierda + (columna + 0.5) * anchoCelda,
      (fila + 0.5) * altoCelda,
    );
    lugares.add(Rect.fromCenter(center: centro, width: ancho, height: alto));
  }
  return lugares;
}
