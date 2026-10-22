import 'package:flutter/foundation.dart';
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
    _listas.clear();
    _cargando.clear();
    _fallaron.clear();
  }
}
