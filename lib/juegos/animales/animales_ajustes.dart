// =============================================================================
//  AJUSTES DEL JUEGO "ANIMALES" (Sonidos de animales)
// =============================================================================
//
//  La voz pregunta "¿Quién hace guau guau?" y ella toca al animal correcto.
//  Cualquier animal que toque hace su sonido.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Los textos van entre comillas simples. {animal} se cambia solo por el
//  nombre del animal ("el perro") y {sonido} por su sonido ("guau guau").
//
//  SONIDOS DE VERDAD: si pones un archivo con el nombre del animal en
//  assets/sonidos/animales/ (por ejemplo perro.mp3 o gato.wav), se escucha
//  ese archivo en vez de la voz diciendo "guau guau".
//
//  Más ayuda en lib/juegos/animales/LEEME.md
// =============================================================================

/// Un animal del juego.
class Animal {
  const Animal(this.id, this.nombre, this.dibujo, this.sonido);

  /// Nombre corto, sin tildes ni espacios. Es el nombre de su archivo de
  /// sonido: assets/sonidos/animales/<id>.mp3 (o .wav, .m4a, .ogg).
  final String id;

  /// Cómo lo nombra la voz, con su artículo: "el perro", "la vaca".
  final String nombre;

  /// El dibujo (un emoji). Para cambiarlo, copia otro emoji y pégalo aquí.
  final String dibujo;

  /// Cómo hace, dicho por la voz si no hay archivo de sonido.
  final String sonido;
}

class AjustesAnimales {
  AjustesAnimales._();

  // -------------------------------------------------------------- animales

  /// Los animales del juego. Para quitar uno, borra su línea; para agregar
  /// otro, copia una línea y cambia sus datos.
  static const List<Animal> animales = <Animal>[
    Animal('perro', 'el perro', '🐶', 'guau guau'),
    Animal('gato', 'el gato', '🐱', 'miau miau'),
    Animal('vaca', 'la vaca', '🐮', 'muuu'),
    Animal('cerdito', 'el cerdito', '🐷', 'oinc oinc'),
    Animal('pollito', 'el pollito', '🐤', 'pío pío'),
    Animal('pato', 'el pato', '🦆', 'cuac cuac'),
    Animal('oveja', 'la oveja', '🐑', 'beee beee'),
    Animal('gallo', 'el gallo', '🐓', 'kikirikí'),
    Animal('rana', 'la rana', '🐸', 'croac croac'),
    ///Animal('buho', 'el búho', '🦉', 'uuu uuu'),
  ];

  // ------------------------------------------------------------ dificultad

  /// Cuántos animales hay al empezar y cuántos como máximo.
  static const int animalesAlEmpezar = 2;
  static const int animalesMaximo = 4;

  /// Sube un animal más cuando acierta estas rondas seguidas sin
  /// equivocarse.
  static const int aciertosParaSubir = 3;

  /// Baja un animal cuando en una ronda se equivoca estas veces.
  static const int erroresParaBajar = 2;

  /// Después de equivocarse estas veces en la misma ronda, el animal
  /// correcto brilla para ayudarla.
  static const int erroresParaAyuda = 2;

  // ------------------------------------------------------------------- voz

  /// La pregunta de cada ronda (cuando no hay archivo de sonido).
  static const String vozPregunta = '¿Quién hace {sonido}?';

  /// La pregunta cuando SÍ hay archivo de sonido: la voz dice esto y
  /// después suena el animal.
  static const String vozPreguntaConSonido = '¿Quién hace así?';

  /// Lo que dice al acertar (una al azar).
  static const List<String> vozAcierto = <String>[
    '¡Muy bien! ¡Es {animal}!',
    '¡Eso es! ¡Es {animal}!',
    '¡Bravo! ¡Es {animal}!',
  ];

  /// Lo que dice al tocar otro animal (y después ese animal hace su sonido).
  static const String vozError = '¡Ese es {animal}!';

  // ----------------------------------------------------------- celebración

  /// Cada cuántos aciertos sale la celebración grande.
  static const int aciertosParaCelebrar = 5;

  /// El cartel y la voz de la celebración.
  static const String celebracionLinea1 = '¡MUY BIEN!';
  static const String celebracionLinea2 = 'ARLETH';
  static const String vozCelebracion = '¡Muy bien! ¡Arleth!';

  // --------------------------------------------------------------- tiempos

  /// Milisegundos que espera, después de que la voz la felicita y el animal
  /// hace su sonido, para la siguiente pregunta (1000 = 1 segundo).
  static const int pausaSiguienteRonda = 900;

  // -------------------------------------------------------------- sonidos

  /// Carpeta de los sonidos de verdad de los animales (dentro de
  /// assets/sonidos/).
  static const String carpetaSonidos = 'animales';

  /// Cuando toca otro animal (un "boing" suave).
  static const String sonidoError = 'comunes/boing.wav';
}
