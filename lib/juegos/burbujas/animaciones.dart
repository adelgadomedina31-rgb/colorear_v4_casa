import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';

/// Las animaciones (archivos Lottie .json de lottiefiles.com) de las mascotas
/// y de los fondos. Se cargan una sola vez, la primera vez que se abre el
/// juego, y quedan guardadas.
///
/// Mientras se cargan (o si un archivo no se puede abrir) se ve el emoji de
/// la mascota o el fondo dibujado de siempre.
class Animaciones {
  Animaciones._();

  static final Map<String, LottieDrawable> _listas = <String, LottieDrawable>{};
  static final Set<String> _cargando = <String>{};
  static final Set<String> _fallaron = <String>{};

  /// Empieza a cargar las animaciones de [rutas] (las que ya se pidieron no
  /// se vuelven a cargar).
  static void preparar(Iterable<String> rutas) {
    for (final ruta in rutas) {
      if (_listas.containsKey(ruta) ||
          _cargando.contains(ruta) ||
          _fallaron.contains(ruta)) {
        continue;
      }
      _cargando.add(ruta);
      AssetLottie(ruta, backgroundLoading: true).load().then(
        (composicion) {
          _cargando.remove(ruta);
          _listas[ruta] = LottieDrawable(composicion);
        },
        onError: (Object error) {
          _cargando.remove(ruta);
          _fallaron.add(ruta);
          debugPrint('No se pudo abrir la animación $ruta: $error');
        },
      );
    }
  }

  /// La animación de [ruta] lista para dibujar, o null si todavía no está
  /// (o si no hay).
  static LottieDrawable? de(String? ruta) =>
      ruta == null ? null : _listas[ruta];

  // --------------------------------------------- cuadros ya preparados
  //
  // Armar un cuadro de una animación Lottie (calcular cada forma, cada
  // capa) cuesta bastante, sobre todo en una tablet o un celular sencillo.
  // Como las animaciones se repiten, cada cuadro se arma UNA sola vez y se
  // guarda listo para dibujar (como una lista de trazos, no como una foto:
  // sigue viéndose nítido). Las vueltas siguientes solo se repiten.

  static final Map<String, ui.Picture> _cuadros = <String, ui.Picture>{};

  /// Como mucho tantos cuadros guardados (si hay más, se empieza de nuevo).
  static const int _cuadrosMaximo = 600;

  /// Dibuja la animación de [ruta] en el punto [avance] (de 0 a 1) dentro
  /// de [donde]. Devuelve false si todavía no está cargada.
  static bool dibujar(
    Canvas canvas,
    String? ruta,
    double avance,
    Rect donde, {
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    final dibujo = de(ruta);
    if (dibujo == null) return false;
    final composicion = dibujo.composition;
    final cuadros = math.max(1, composicion.durationFrames.round());
    final cuadro =
        ((avance % 1) * cuadros).floor().clamp(0, cuadros - 1).toInt();
    final tam = donde.size;
    final clave = '$ruta|$cuadro|${tam.width.round()}|${tam.height.round()}'
        '|${fit.index}|${alignment.x}|${alignment.y}';
    var foto = _cuadros[clave];
    if (foto == null) {
      if (_cuadros.length >= _cuadrosMaximo) olvidarCuadros();
      final grabadora = ui.PictureRecorder();
      dibujo.setProgress(cuadro / cuadros);
      dibujo.draw(
        Canvas(grabadora),
        Offset.zero & tam,
        fit: fit,
        alignment: alignment,
      );
      foto = grabadora.endRecording();
      _cuadros[clave] = foto;
    }
    canvas.save();
    canvas.translate(donde.left, donde.top);
    canvas.drawPicture(foto);
    canvas.restore();
    return true;
  }

  /// Se olvida de los cuadros ya preparados (por ejemplo, al salir del
  /// juego, para dejar libre la memoria).
  static void olvidarCuadros() {
    for (final foto in _cuadros.values) {
      foto.dispose();
    }
    _cuadros.clear();
  }

  /// Para las pruebas: cuántos cuadros hay preparados.
  @visibleForTesting
  static int get cuadrosPreparados => _cuadros.length;

  /// true = todavía se está cargando.
  static bool cargando(String? ruta) =>
      ruta != null && _cargando.contains(ruta);

  /// Para las pruebas: pone una animación ya cargada.
  @visibleForTesting
  static void poner(String ruta, LottieComposition composicion) {
    _cargando.remove(ruta);
    _listas[ruta] = LottieDrawable(composicion);
  }

  /// Para las pruebas: se olvida de todo lo cargado.
  @visibleForTesting
  static void olvidar() {
    olvidarCuadros();
    _listas.clear();
    _cargando.clear();
    _fallaron.clear();
  }
}
