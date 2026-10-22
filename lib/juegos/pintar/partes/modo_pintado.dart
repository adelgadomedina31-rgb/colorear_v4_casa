import 'package:shared_preferences/shared_preferences.dart';

import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';

/// El modo de pintar que se eligió con el engranaje del menú. Vale para
/// todos los dibujos y queda guardado en el celular.
///
///  - [total] (Modo 1, "Pintado total"): se pinta libre con los colores del
///    dibujo, que no se acaban. Si un color cubre la mitad del dibujo, la voz
///    recomienda usar otro.
///  - [porObjeto] (Modo 2, "Pintado por objeto"): el personaje del dibujo se
///    pinta de un solo color, y ese color no sirve para el resto.
class ModoPintado {
  ModoPintado._();

  static const int total = 1;
  static const int porObjeto = 2;

  static const String _clave = 'modo_pintado';

  static int _actual = _valido(AjustesPintar.modoPorDefecto);

  /// Sube cada vez que se cambia el modo (para que una lectura que llega
  /// tarde no deshaga un cambio recién hecho).
  static int _cambios = 0;

  /// El modo elegido (1 o 2).
  static int get actual => _actual;

  static int _valido(int modo) => modo == porObjeto ? porObjeto : total;

  /// Lee el modo guardado (al abrir la app).
  static Future<void> cargar() async {
    final cambios = _cambios;
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getInt(_clave);
      if (guardado != null && cambios == _cambios) _actual = _valido(guardado);
    } catch (_) {
      // Si no se pudo leer, se queda el de pintar_ajustes.dart.
    }
  }

  /// Cambia el modo y lo guarda.
  static Future<void> cambiar(int modo) async {
    _actual = _valido(modo);
    _cambios++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_clave, _actual);
    } catch (_) {
      // Si no se pudo guardar, igual vale mientras la app siga abierta.
    }
  }
}
