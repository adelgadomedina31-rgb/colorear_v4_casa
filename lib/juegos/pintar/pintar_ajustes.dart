// =============================================================================
//  AJUSTES DEL JUEGO "PINTAR"
// =============================================================================
//
//  Aquí se cambia cómo se pinta: el tamaño de las manchas, los sonidos, lo
//  que dice la voz, los dos modos de pintar, el personaje y los colores de
//  cada dibujo, y la celebración al terminar.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Los textos van entre comillas simples: '¡Elige un color!'.
//
//  Más ayuda en lib/juegos/pintar/LEEME.md
// =============================================================================

/// El personaje de un dibujo, para el "Modo 2 - Pintado por objeto":
/// sus [partes] (los "id" de sus zonas) se pintan todas de un solo color,
/// y ese color no se puede usar en el resto del dibujo.
class Personaje {
  const Personaje(this.nombre, this.partes);

  /// Cómo lo nombra la voz, con su artículo: "el sol", "las alas"...
  final String nombre;

  /// Las zonas del personaje.
  final List<String> partes;
}

/// Los dibujos se definen en un cuadrado de 1000 x 1000 unidades; las medidas
/// de abajo usan esas mismas unidades (100 = un 10% del ancho del dibujo).
class AjustesPintar {
  AjustesPintar._();

  // ------------------------------------------------------ menú de dibujos

  /// El título de colores que se ve arriba de los dibujos.
  static const String tituloMenu = 'COLOREA ARLETH';

  // ---------------------------------------------------------------- pintura

  /// Las zonas con un área visible menor a esta se pintan completas con un
  /// solo toque. 30000 equivale a un cuadrado de unos 173 x 173.
  static const double areaUnToque = 30000;

  /// Cuántos toques, más o menos, hacen falta para llenar una zona que apenas
  /// pasa el tamaño de "un toque" y una zona enorme (el cielo, el fondo).
  /// Las zonas intermedias quedan entre esos dos números.
  /// Más toques = manchas más chicas.
  static const double toquesZonaChica = 3;
  static const double toquesZonaGrande = 10;

  /// Área que se considera "zona enorme" (casi todo el dibujo).
  static const double areaZonaGrande = 700000;

  /// Multiplica el tamaño de todas las manchas. 1.2 = un 20% más grandes.
  static const double escalaMancha = 1.2;

  /// Límites para el tamaño (radio) de cada mancha.
  static const double radioMinimo = 100;
  static const double radioMaximo = 310;

  /// Cuánto tarda la pintura en "derramarse" hasta su tamaño final
  /// (milisegundos).
  static const int duracionDerrame = 650;

  /// Al arrastrar el dedo se pinta una franja; su ancho es el radio de la
  /// mancha multiplicado por este número.
  static const double anchoArrastre = 1.2;

  /// Grosor de la línea negra de los contornos.
  static const double grosorContorno = 10;

  // --------------------------------------------------------------- sonidos

  /// true = suenan las gotas de pintura y el pincel al pintar.
  static const bool sonidoPintar = true;

  /// Volumen de la gota de pintura al tocar el dibujo (0 a 1).
  static const double volumenPintar = 0.8;

  /// Volumen del pincel al arrastrar el dedo (0 a 1).
  static const double volumenTrazo = 0.55;

  /// Al arrastrar el dedo, suena otra pasada de pincel cada esta distancia
  /// recorrida (más chico = suena más seguido).
  static const double distanciaEntreTrazos = 220;

  // ------------------------------------------------------------------- voz

  /// Pausa mínima (milisegundos) antes de poder elegir otro color, aunque la
  /// voz termine antes. La paleta también espera a que la voz termine.
  static const int pausaMinimaColor = 700;

  // ------------------------------------------------------ modos de pintar
  //
  // Hay dos modos. Se eligen en la app, con el engranaje del menú de juegos.
  //  - Modo 1, "Pintado total": se pinta libre, los colores no se acaban.
  //  - Modo 2, "Pintado por objeto": el personaje del dibujo (el pez, el
  //    sol...) se pinta de un solo color, y ese color no sirve para el resto.

  /// El modo que se usa si nunca se eligió otro (1 o 2).
  static const int modoPorDefecto = 1;

  /// Cuántos colores, como mucho, tiene la paleta de cada dibujo.
  static const int maxColoresPorDibujo = 5;

  /// Al entrar a un dibujo no hay ningún color elegido y la voz dice esto
  /// (también si toca el dibujo sin haber elegido un color).
  static const String vozEligeUnColor = '¡Elige un color!';

  /// Modo 1: cuando un mismo color cubre esta parte del dibujo (0.50 = la
  /// mitad), la voz recomienda usar otro. Se dice una vez por color.
  static const double parteParaRecomendar = 0.30;
  static const String vozUsaOtroColor =
      '¡Arleth elije otro color, para que se vea más bonito!';

  /// Modo 1: true = al recomendar otro color, el color se suelta y ella
  /// elige el siguiente (puede volver a elegir el mismo y seguir pintando).
  /// false = solo lo dice y el color sigue elegido.
  static const bool soltarColorAlRecomendar = false;

  /// Modo 2: el personaje se da por terminado cuando esta parte de él está
  /// pintada (0.97 = el 97%). Entonces la voz pide otro color y el color se
  /// suelta (nunca se elige otro solo).
  static const double personajeTerminado = 0.97;

  /// Modo 2: lo que dice la voz. {objeto} se cambia por el nombre del
  /// personaje ("el pez") y {color} por el nombre del color.
  static const String vozEligeOtroParaSeguir =
      '¡Elige otro color para seguir pintando!';
  static const String vozColorDelPersonaje = '¡Este color es para {objeto}!';
  static const String vozPintaPersonajeCon = '¡Pinta {objeto} con el {color}!';
  static const String vozOtroColorParaPersonaje =
      '¡Elige otro color para {objeto}!';

  /// Modo 2: cómo se nombra el personaje de los dibujos que no están en
  /// [personajes] (por ejemplo, los de la carpeta mis_dibujos).
  static const String personajeSinNombre = 'el personaje';

  /// Modo 2: el personaje de cada dibujo (por su "id"). Sus partes se pintan
  /// todas de un solo color: los rayos y la cara del sol, el cuerpo, la cola
  /// y las aletas del pez... Lo demás (el fondo y los detalles, como la
  /// puerta de la casa o las manchas de la mariposa) se pinta con otros
  /// colores, uno o varios.
  /// Los dibujos que no están aquí: el personaje es lo que no toca los bordes
  /// del dibujo, menos los detalles que quedan adentro de una zona más grande
  /// (un ojo, una mancha). Un dibujo agregado también puede traer su
  /// personaje en el JSON (campo "personaje", ver partes/dibujo.dart).
  static const Map<String, Personaje> personajes = <String, Personaje>{
    'sol': Personaje('el sol', <String>[
      'cara',
      'rayo1',
      'rayo2',
      'rayo3',
      'rayo4',
      'rayo5',
      'rayo6',
      'rayo7',
      'rayo8',
    ]),
    'flor': Personaje('la flor', <String>[
      'petalo1',
      'petalo2',
      'petalo3',
      'petalo4',
      'petalo5',
      'petalo6',
    ]),
    'pez': Personaje(
        'el pez', <String>['cuerpo', 'cola', 'aleta_arriba', 'aleta_abajo']),
    'casa': Personaje('la casa', <String>['pared', 'techo', 'chimenea']),
    'gato': Personaje('el gato', <String>['cabeza', 'oreja_izq', 'oreja_der']),
    'globos': Personaje('los globos', <String>['globo1', 'globo2', 'globo3']),
    'manzana': Personaje('la manzana', <String>['manzana']),
    'mariposa': Personaje('las alas', <String>[
      'ala_sup_izq',
      'ala_sup_der',
      'ala_inf_izq',
      'ala_inf_der',
    ]),
    'perro':
        Personaje('el perro', <String>['cabeza', 'oreja_izq', 'oreja_der']),
    'corazon': Personaje('el corazón', <String>['corazon']),
    'helado': Personaje('el helado', <String>['bola_baja', 'bola_alta']),
    'pollito':
        Personaje('el pollito', <String>['cuerpo', 'ala_izq', 'ala_der']),
    'carro': Personaje('el carro', <String>['cuerpo', 'cabina']),
    'arbol': Personaje('el árbol', <String>['copa']),
    'conejo':
        Personaje('el conejo', <String>['cabeza', 'oreja_izq', 'oreja_der']),
    'cupcake': Personaje(
        'la crema', <String>['crema_baja', 'crema_media', 'crema_alta']),
    'nube_lluvia': Personaje('la nube', <String>['nube']),
    'tortuga': Personaje('la tortuga', <String>[
      'caparazon',
      'cabeza',
      'cola',
      'pata_izq',
      'pata_der',
    ]),
    'barco':
        Personaje('el barco', <String>['casco', 'vela_grande', 'vela_chica']),
    'fresa': Personaje('la fresa', <String>['fresa']),
    'oso': Personaje('el oso', <String>['cabeza', 'oreja_izq', 'oreja_der']),
    'luna': Personaje('la luna', <String>['luna']),
    'pato': Personaje('el pato', <String>['cuerpo', 'cabeza', 'ala', 'cola']),
    'regalo': Personaje('el regalo', <String>['caja', 'tapa']),
    'cerdito':
        Personaje('el cerdito', <String>['cabeza', 'oreja_izq', 'oreja_der']),
    'cohete': Personaje(
        'el cohete', <String>['cuerpo', 'punta', 'aleta_izq', 'aleta_der']),
    'hongo': Personaje('el hongo', <String>['gorro']),
    'rana': Personaje('la rana', <String>['cabeza', 'ojo_izq', 'ojo_der']),
    'arcoiris': Personaje('las nubes', <String>['nube_izq', 'nube_der']),
    'abeja':
        Personaje('la abeja', <String>['banda1', 'banda2', 'banda3', 'banda4']),
    'paraguas':
        Personaje('el paraguas', <String>['gajo1', 'gajo2', 'gajo3', 'gajo4']),
    'pinguino':
        Personaje('el pingüino', <String>['cuerpo', 'ala_izq', 'ala_der']),
    'avion': Personaje('el avión', <String>['fuselaje', 'cola', 'ala']),
    'ballena': Personaje('la ballena', <String>[
      'cuerpo',
      'cola_arriba',
      'cola_abajo',
      'aleta',
    ]),
  };

  // ------------------------------------------------------------ celebración

  /// Cuando esta parte del dibujo queda pintada (0.95 = el 95%), con
  /// cualquier color, sale la celebración con estrellas. Sale una sola vez
  /// por dibujo (vuelve a salir si se borra y se pinta de nuevo).
  static const double porcentajeCelebracion = 1.0;

  /// Lo que se ve en grande en la celebración (dos líneas).
  static const String celebracionLinea1 = '¡FELICIDADES!';
  static const String celebracionLinea2 = 'LO PINTASTE MUY BIEN';

  /// Lo que dice la voz en la celebración. (Cuántos segundos dura se cambia
  /// en lib/app/ajustes_app.dart, porque es igual en todos los juegos.)
  static const String vozCelebracion = '¡Felicidades! ¡Lo pintaste muy bien!';

  // ---------------------------------------------------------------- colores

  /// Los colores de cada dibujo (como mucho 5), con su "id".
  /// Se escriben con el mismo nombre que en la lista de colores de
  /// lib/app/ajustes_app.dart ("Rojo", "Azul", "Marrón"...).
  /// Valen para los dos modos. Al entrar no queda ninguno elegido: ella elige.
  static const Map<String, List<String>> paletasDibujos =
      <String, List<String>>{
    'sol': <String>['Amarillo', 'Naranja', 'Celeste', 'Rojo', 'Rosado'],
    'flor': <String>['Rosado', 'Amarillo', 'Verde', 'Celeste', 'Morado'],
    'pez': <String>['Naranja', 'Amarillo', 'Celeste', 'Azul', 'Verde'],
    'casa': <String>['Rojo', 'Amarillo', 'Celeste', 'Verde', 'Marrón'],
    'gato': <String>['Naranja', 'Gris', 'Rosado', 'Amarillo', 'Celeste'],
    'globos': <String>['Rojo', 'Azul', 'Amarillo', 'Verde', 'Celeste'],
    'manzana': <String>['Rojo', 'Verde', 'Marrón', 'Amarillo', 'Celeste'],
    'mariposa': <String>['Morado', 'Amarillo', 'Rosado', 'Celeste', 'Negro'],
    'perro': <String>['Marrón', 'Amarillo', 'Rosado', 'Negro', 'Celeste'],
    'corazon': <String>['Rojo', 'Rosado', 'Morado', 'Amarillo', 'Celeste'],
    'helado': <String>['Rosado', 'Marrón', 'Naranja', 'Rojo', 'Celeste'],
    'pollito': <String>['Amarillo', 'Naranja', 'Rojo', 'Verde', 'Celeste'],
    'carro': <String>['Rojo', 'Celeste', 'Negro', 'Gris', 'Amarillo'],
    'arbol': <String>['Verde', 'Marrón', 'Rojo', 'Amarillo', 'Celeste'],
    'conejo': <String>['Gris', 'Rosado', 'Verde', 'Celeste', 'Amarillo'],
    'cupcake': <String>['Rosado', 'Marrón', 'Rojo', 'Celeste', 'Amarillo'],
    'nube_lluvia': <String>['Gris', 'Azul', 'Celeste', 'Amarillo', 'Morado'],
    'tortuga': <String>['Verde', 'Marrón', 'Amarillo', 'Celeste', 'Naranja'],
    'barco': <String>['Rojo', 'Azul', 'Amarillo', 'Celeste', 'Marrón'],
    'fresa': <String>['Rojo', 'Verde', 'Rosado', 'Amarillo', 'Celeste'],
    'oso': <String>['Marrón', 'Naranja', 'Rosado', 'Amarillo', 'Celeste'],
    'luna': <String>['Azul', 'Amarillo', 'Morado', 'Naranja', 'Celeste'],
    'pato': <String>['Amarillo', 'Naranja', 'Celeste', 'Azul', 'Verde'],
    'regalo': <String>['Rojo', 'Verde', 'Amarillo', 'Morado', 'Celeste'],
    'cerdito': <String>['Rosado', 'Rojo', 'Celeste', 'Verde', 'Amarillo'],
    'cohete': <String>['Rojo', 'Gris', 'Azul', 'Amarillo', 'Naranja'],
    'hongo': <String>['Rojo', 'Amarillo', 'Verde', 'Marrón', 'Celeste'],
    'rana': <String>['Verde', 'Amarillo', 'Celeste', 'Rosado', 'Azul'],
    'arcoiris': <String>['Rojo', 'Naranja', 'Amarillo', 'Verde', 'Celeste'],
    'abeja': <String>['Amarillo', 'Negro', 'Celeste', 'Naranja', 'Verde'],
    'paraguas': <String>['Rojo', 'Amarillo', 'Azul', 'Celeste', 'Morado'],
    'pinguino': <String>['Negro', 'Naranja', 'Celeste', 'Azul', 'Gris'],
    'avion': <String>['Rojo', 'Celeste', 'Azul', 'Gris', 'Amarillo'],
    'ballena': <String>['Azul', 'Celeste', 'Gris', 'Rosado', 'Amarillo'],
  };

  /// Colores de los dibujos que no están en [paletasDibujos] ni traen los
  /// suyos (por ejemplo, los de la carpeta mis_dibujos sin archivo .txt).
  static const List<String> paletaPorDefecto = <String>[
    'Rojo',
    'Amarillo',
    'Verde',
    'Azul',
    'Rosado',
  ];
}
