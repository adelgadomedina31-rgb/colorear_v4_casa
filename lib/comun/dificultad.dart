/// Cuántas opciones se muestran en un juego (2, 3, 4...) y cómo cambia:
///  - Empieza en [minimo].
///  - Sube una opción cuando acierta [aciertosParaSubir] rondas seguidas
///    sin equivocarse (hasta [maximo]).
///  - Baja una opción cuando en una ronda se equivoca [erroresParaBajar]
///    veces o más (nunca menos de [minimo]).
/// Así el juego se adapta solo, sin que ella note nada.
class Dificultad {
  Dificultad({
    required this.minimo,
    required this.maximo,
    required this.aciertosParaSubir,
    required this.erroresParaBajar,
  }) : opciones = minimo;

  final int minimo;
  final int maximo;
  final int aciertosParaSubir;
  final int erroresParaBajar;

  /// Cuántas opciones hay ahora.
  int opciones;

  int _seguidas = 0;

  /// Se llama al terminar cada ronda con las veces que se equivocó en ella.
  void terminoRonda(int errores) {
    if (errores == 0) {
      _seguidas++;
      if (_seguidas >= aciertosParaSubir && opciones < maximo) {
        opciones++;
        _seguidas = 0;
      }
    } else {
      _seguidas = 0;
      if (errores >= erroresParaBajar && opciones > minimo) opciones--;
    }
  }
}
