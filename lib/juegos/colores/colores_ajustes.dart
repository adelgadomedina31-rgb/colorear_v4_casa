// =============================================================================
//  AJUSTES DEL JUEGO "COLORES" (Encuentra el color)
// =============================================================================
//
//  La voz dice "¡Toca el globo rojo!" y ella toca el globo de ese color.
//  Si acierta, el globo revienta con estrellitas; si se equivoca, el globo
//  se mueve y la voz le dice qué color tocó.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Los textos van entre comillas simples. {color} se cambia solo por el
//  nombre del color ("rojo") y {otro} por el del globo que tocó.
//
//  Más ayuda en lib/juegos/colores/LEEME.md
// =============================================================================

class AjustesColores {
  AjustesColores._();

  // ---------------------------------------------------------------- globos

  /// Los colores de los globos. Se escriben igual que en la lista de colores
  /// de lib/app/ajustes_app.dart. Conviene que sean fáciles de distinguir
  /// (por eso no están el celeste, el gris ni el marrón).
  static const List<String> colores = <String>[
    'Rojo',
    'Azul',
    'Amarillo',
    'Verde',
    'Naranja',
    'Morado',
    'Rosado',
  ];

  // ------------------------------------------------------------ dificultad

  /// Cuántos globos hay al empezar y cuántos como máximo.
  static const int globosAlEmpezar = 2;
  static const int globosMaximo = 4;

  /// Sube un globo más cuando acierta estas rondas seguidas sin equivocarse.
  static const int aciertosParaSubir = 3;

  /// Baja un globo cuando en una ronda se equivoca estas veces.
  static const int erroresParaBajar = 2;

  /// Después de equivocarse estas veces en la misma ronda, el globo
  /// correcto brilla para ayudarla.
  static const int erroresParaAyuda = 2;

  // ------------------------------------------------------------------- voz

  /// Lo que pide la voz en cada ronda.
  static const String vozBusca = '¡Toca el globo {color}!';

  /// Si en assets/voces/ están las grabaciones "toca_el_globo" y la del
  /// color (por ejemplo "rojo"), se escuchan esas en vez de la voz del
  /// celular. Ver assets/voces/LEEME.txt.
  static const String grabacionBusca = 'toca_el_globo';

  /// Lo que dice al acertar (una al azar).
  static const List<String> vozAcierto = <String>[
    '¡Muy bien! ¡Es el {color}!',
    '¡Eso es! ¡El {color}!',
    '¡Bravo! ¡Es el {color}!',
  ];

  /// Lo que dice al tocar otro globo.
  static const String vozError = 'Ese es el {otro}. ¡Busca el {color}!';

  // ----------------------------------------------------------- celebración

  /// Cada cuántos globos reventados sale la celebración grande.
  static const int aciertosParaCelebrar = 5;

  /// El cartel y la voz de la celebración.
  static const String celebracionLinea1 = '¡MUY BIEN!';
  static const String celebracionLinea2 = 'ARLETH';
  static const String vozCelebracion = '¡Muy bien! ¡Arleth!';

  // --------------------------------------------------------------- tiempos

  /// Milisegundos que espera, después de que la voz la felicita, para la
  /// siguiente ronda (1000 = 1 segundo).
  static const int pausaSiguienteRonda = 600;

  // -------------------------------------------------------------- sonidos
  //
  // Están en assets/sonidos/. Para cambiarlos, pon otro archivo con el mismo
  // nombre (o cambia aquí el nombre).

  /// El globo que revienta.
  static const String sonidoReventar = 'colores/reventar.wav';

  /// Cuando toca otro globo (un "boing" suave).
  static const String sonidoError = 'comunes/boing.wav';
}
