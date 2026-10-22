// =============================================================================
//  AJUSTES DEL JUEGO "¿CUÁNTOS HAY?" (Contar)
// =============================================================================
//
//  Cada ronda aparecen unas cosas (manzanas, pollitos, estrellas...). Ella
//  las toca una por una y la voz cuenta: "uno, dos, tres". Cuando contó
//  todas, la voz pregunta "¿Cuántas manzanas hay?" y abajo salen botones
//  con números (y puntitos). Si acierta, gana una estrella. Si se equivoca,
//  la voz dice qué número tocó y cuentan juntas otra vez.
//
//  Empieza con hasta 3 cosas y, a medida que acierta, llega hasta 5.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" (o dentro de
//  los paréntesis) y guarda. Los textos van entre comillas simples.
//
//  Más ayuda en lib/juegos/contar/LEEME.md
// =============================================================================

/// Una cosa para contar.
class Cosa {
  const Cosa({
    required this.dibujo,
    required this.una,
    required this.varias,
    this.femenino = false,
  });

  /// El dibujo (un emoji).
  final String dibujo;

  /// Cómo se dice una sola ('manzana') y varias ('manzanas').
  final String una;
  final String varias;

  /// true si se dice "la manzana", "las manzanas"; false si se dice "el
  /// pollito", "los pollitos". (Así la voz dice "¿Cuántas manzanas hay?"
  /// y "¿Cuántos pollitos hay?").
  final bool femenino;
}

class AjustesContar {
  AjustesContar._();

  // ----------------------------------------------------------------- cosas

  /// Las cosas para contar. Cada ronda sale una al azar.
  /// Para agregar otra, copia una línea y cambia el emoji y los nombres.
  static const List<Cosa> cosas = <Cosa>[
    Cosa(dibujo: '🍎', una: 'manzana', varias: 'manzanas', femenino: true),
    Cosa(dibujo: '⭐', una: 'estrella', varias: 'estrellas', femenino: true),
    Cosa(dibujo: '🐥', una: 'pollito', varias: 'pollitos'),
    Cosa(dibujo: '🐟', una: 'pez', varias: 'peces'),
    Cosa(dibujo: '🎈', una: 'globo', varias: 'globos'),
    Cosa(dibujo: '🌸', una: 'flor', varias: 'flores', femenino: true),
    Cosa(dibujo: '🦋', una: 'mariposa', varias: 'mariposas', femenino: true),
    Cosa(dibujo: '🚗', una: 'auto', varias: 'autos'),
    Cosa(dibujo: '🐶', una: 'perrito', varias: 'perritos'),
    Cosa(dibujo: '🐢', una: 'tortuga', varias: 'tortugas', femenino: true),
  ];

  // ------------------------------------------------------------ dificultad

  /// Hasta cuántas cosas puede haber al empezar, y lo más que llega a
  /// haber (máximo 10).
  static const int hastaAlEmpezar = 3;
  static const int hastaMaximo = 5;

  /// Cuántas rondas seguidas sin equivocarse para que pueda haber una cosa
  /// más (hasta hastaMaximo).
  static const int aciertosParaSubir = 3;

  /// Si en una ronda se equivoca esta cantidad de veces, vuelve a haber una
  /// cosa menos (nunca menos de hastaAlEmpezar).
  static const int erroresParaBajar = 2;

  /// Cuántos botones con números salen para responder.
  static const int botones = 3;

  /// Después de equivocarse esta cantidad de veces en una ronda, el botón
  /// correcto brilla para ayudarla.
  static const int erroresParaAyuda = 2;

  // ------------------------------------------------------------------- voz
  //
  // En los textos, {cosas} es el nombre de la cosa ("manzanas"), {las} es
  // "las" o "los", {una} es "una" o "uno", {Cuantas} es "Cuántas" o
  // "Cuántos", {numero} es el número en palabras y {otro} el número que
  // tocó.

  /// Los números como los dice la voz al contar.
  static const List<String> numeros = <String>[
    'uno',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
    'nueve',
    'diez',
  ];

  /// Al empezar cada ronda (y con la orejita, mientras cuenta).
  static const String vozCuenta = '¡Cuenta {las} {cosas}! Toca cada {una}.';

  /// Cuando ya contó todas (y con la orejita, mientras responde).
  static const String vozPregunta = '¿{Cuantas} {cosas} hay?';

  /// Cuando acierta (una de estas, al azar).
  static const List<String> vozAcierto = <String>[
    '¡Sí! ¡Hay {numero} {cosas}!',
    '¡Muy bien! ¡Contaste {numero} {cosas}!',
  ];

  /// Cuando toca otro número. Después la voz cuenta con ella otra vez.
  static const String vozError = 'Ese es el {otro}. ¡Contemos otra vez!';

  // ----------------------------------------------------------- celebración

  /// Cada cuántos aciertos sale la celebración grande.
  static const int aciertosParaCelebrar = 5;

  static const String celebracionLinea1 = '¡MUY BIEN!';
  static const String celebracionLinea2 = 'SABES CONTAR';
  static const String vozCelebracion = '¡Muy bien! ¡Sabes contar!';

  /// Cuánto esperar (milisegundos) antes de la ronda siguiente.
  static const int pausaSiguienteRonda = 600;

  // -------------------------------------------------------------- sonidos
  //
  // Están en assets/sonidos/. Para cambiarlos, pon otro archivo con el
  // mismo nombre.

  /// Al contar cada cosa suena una notita que va subiendo ({n} = 1, 2, 3...).
  static const String sonidoContar = 'contar/nota{n}.wav';

  /// Cuando toca un número que no es.
  static const String sonidoError = 'comunes/boing.wav';
}
