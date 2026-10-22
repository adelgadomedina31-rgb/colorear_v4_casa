// =============================================================================
//  AJUSTES DEL JUEGO "BURBUJAS" (Revienta las burbujas)
// =============================================================================
//
//  Van saliendo burbujas, de a poco (por los lados de la pantalla o las
//  sopla la mascota), y flotan por todas partes. Con un toque revientan
//  ("¡AY!"). Hay que reventarlas TODAS para pasar al nivel siguiente.
//
//  Los niveles no se acaban nunca: cada nivel tiene un poquito más de
//  burbujas, más rápidas y que giran más, y cada pocos niveles aparece un
//  tipo de burbuja nuevo (súper, animalito, mega, rápidas). De vez en
//  cuando, al azar, sale un nivel más tranquilo, para que sienta que mejora
//  sin frustrarse, y otras veces un nivel de JEFE (una burbuja gigante).
//  El juego recuerda en qué nivel va.
//
//  Cada nivel pasa en un MUNDO distinto (cielo, mar, atardecer, noche o
//  espacio), con una MASCOTA abajo que sopla burbujas y aplaude. Las
//  burbujas tienen CARITA: parpadean, se ríen y dicen "¡ay!" al reventar.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Los textos van entre comillas simples. Los decimales llevan punto (0.3).
//
//  Más ayuda en lib/juegos/burbujas/LEEME.md
// =============================================================================

class AjustesBurbujas {
  AjustesBurbujas._();

  // ----------------------------------------------- cómo suben los niveles

  /// Cuántas burbujas normales hay en el nivel 1, cuántas se suman en cada
  /// nivel, y el máximo.
  static const int burbujasAlEmpezar = 6;
  static const int burbujasMasPorNivel = 1;
  static const int burbujasMaximo = 12;

  /// Cuántas puede haber en la pantalla al mismo tiempo: en el nivel 1, y
  /// lo más que llega a haber. Se suma una cada [nivelesParaUnaMasALaVez]
  /// niveles.
  static const int aLaVezAlEmpezar = 3;
  static const int aLaVezMaximo = 7;
  static const int nivelesParaUnaMasALaVez = 3;

  /// Qué tan rápido van: cuánto del ancho de la pantalla (con el teléfono
  /// parado) recorren en un segundo. 10 = cruzan la pantalla en unos 10
  /// segundos. Cada burbuja va un poco más lenta o más rápida que eso.
  static const double velocidadAlEmpezar = 8;
  static const double velocidadMasPorNivel = 0.7;
  static const double velocidadMaxima = 24;

  /// Cuánto cambian de dirección mientras flotan (0 = siempre derecho,
  /// 1 = normal, 2 = el doble).
  static const double girosAlEmpezar = 1.0;
  static const double girosMasPorNivel = 0.08;
  static const double girosMaximo = 2.4;

  /// Nunca más de esta cantidad de burbujas para reventar en un nivel
  /// (contando todas, también las que salen de las mega burbujas).
  static const int totalMaximo = 24;

  // ---------------------------------------------- niveles más tranquilos

  /// De vez en cuando sale un nivel más tranquilo (como uno anterior), así
  /// la dificultad sube "en escalera" y no siempre de golpe.
  /// 0.3 = 3 de cada 10 niveles (más o menos). 0 = nunca.
  static const double probabilidadNivelTranquilo = 0.3;

  /// Cuántos niveles más fácil puede ser un nivel tranquilo (de 1 a este).
  static const int nivelesMasFacil = 3;

  /// En cada nivel (desde el 2), un tipo de burbuja (al azar, de los que
  /// ya salieron) viene con esta cantidad extra, para que cada nivel sea
  /// distinto. 0 = nunca.
  static const int extraSorpresa = 2;

  // ------------------------------------------------ los tipos de burbuja
  //
  // Desde qué nivel sale cada tipo (0 = no sale nunca). La primera vez,
  // la voz lo presenta. Desde que aparece, cada [nivelesParaUnaMas] niveles
  // hay una más de ese tipo (hasta su máximo).

  static const int nivelesParaUnaMas = 5;

  /// SÚPER BURBUJA: grande, dorada, con una estrella. Hay que tocarla
  /// varias veces (los puntitos blancos dicen cuántas faltan).
  static const int superDesdeNivel = 3;
  static const int superMaximo = 4;
  static const int toquesSuper = 3;

  /// ANIMALITO: una burbuja con un animalito adentro. Al reventarla, el
  /// animalito sale volando contento.
  static const int animalitoDesdeNivel = 5;
  static const int animalitoMaximo = 3;
  static const List<String> animalitos = <String>[
    '🐥', '🐟', '🐸', '🐞', '🦋', '🐱', '🐶', '🐰', '🐢', '🐝', //
  ];

  /// MEGA BURBUJA: enorme, con burbujitas adentro. Con [toquesMega] toques
  /// explota y salen [hijasMega] burbujitas que también hay que reventar.
  static const int megaDesdeNivel = 7;
  static const int megaMaximo = 2;
  static const int toquesMega = 2;
  static const int hijasMega = 4;

  /// BURBUJITAS RÁPIDAS: chiquitas, brillantes y muy rápidas (dejan una
  /// estela). [velocidadRapidas] = cuántas veces más rápido que las demás.
  static const int rapidaDesdeNivel = 9;
  static const int rapidaMaximo = 6;
  static const double velocidadRapidas = 2.2;

  // ------------------------------------------------- niveles de jefe
  //
  // De vez en cuando sale un nivel de JEFE: una burbuja gigante que hay que
  // tocar muchas veces. Con cada toque se achica, se ríe y suelta
  // burbujitas; al final explota en muchas burbujitas más. Vienen unas
  // pocas burbujas normales con él.

  /// Desde qué nivel salen jefes (0 = nunca). En ese nivel sale siempre el
  /// primero de la lista [jefes].
  static const int jefeDesdeNivel = 4;

  /// Qué tan seguido: 0.25 = más o menos 1 de cada 4 niveles. Nunca hay
  /// dos niveles de jefe seguidos, y si pasan [nivelesSinJefeMaximo]
  /// niveles sin jefe, el siguiente lo tiene seguro.
  static const double probabilidadJefe = 0.25;
  static const int nivelesSinJefeMaximo = 6;

  /// Los jefes (borra uno de la lista para que no salga):
  ///  - 'rey': el REY BURBUJA, con corona. Se achica con cada toque.
  ///  - 'saltarina': con orejas de conejo; con cada toque salta a otro lado.
  ///  - 'dormilona': con gorro de dormir; duerme (va lentito) y al tocarla
  ///    se despierta riéndose y corre un ratito.
  ///  - 'pinata': una piñata de colores; con cada toque se sacude y le caen
  ///    burbujitas de dulce.
  static const List<String> jefes = <String>[
    'rey',
    'saltarina',
    'dormilona',
    'pinata',
  ];

  /// Cuántos toques necesita el jefe: al empezar, uno más cada
  /// [nivelesParaUnToqueMas] niveles, y el máximo.
  static const int toquesJefeAlEmpezar = 6;
  static const int nivelesParaUnToqueMas = 6;
  static const int toquesJefeMaximo = 9;

  /// Cuántas burbujitas suelta el jefe con cada toque, y cuántas al
  /// reventar.
  static const int burbujitasPorToqueJefe = 1;
  static const int burbujitasAlReventarJefe = 6;

  /// Cuántas burbujas normales vienen con el jefe.
  static const int normalesConJefe = 3;

  /// El tamaño del jefe al llegar (parte del ancho de la pantalla), y qué
  /// tan chiquito queda al final (0.45 = casi la mitad).
  static const double tamanoJefe = 0.6;
  static const double jefeAchicaHasta = 0.45;

  // ------------------------------------------------------------ mundos
  //
  // Cada nivel pasa en un mundo distinto, elegido al azar (nunca el mismo
  // dos veces seguidas). Los mundos que hay:
  //  'cielo' (de día, con sol y nubes), 'mar' (el fondo del mar, con
  //  peces), 'atardecer', 'noche' (con luna y estrellas) y 'espacio'
  //  (planetas y estrellas fugaces).
  // Para que uno no salga, bórralo de la lista.

  static const List<String> mundos = <String>[
    'cielo',
    'mar',
    'atardecer',
    'noche',
    'espacio',
  ];

  /// Fondos animados (Lottie, en assets/fondos/): el mundo que esté aquí se
  /// ve con esa animación en vez del dibujo de siempre. Se agranda hasta
  /// llenar la pantalla, con la parte de abajo (la arena) siempre a la vista.
  /// Bórralo de aquí para volver al fondo del mar dibujado.
  static const Map<String, String> fondosAnimados = <String, String>{
    'mar': 'assets/fondos/mar.json',
  };

  // ---------------------------------------------------------- mascotas
  //
  // Abajo, en cada mundo, hay una mascota (elegida al azar entre las de ese
  // mundo) que camina y corre de un lado a otro, sopla burbujas, se ríe si
  // la tocas y aplaude al pasar de nivel. En el espacio, el perrito lleva
  // casco de astronauta.

  static const Map<String, List<String>> mascotas = <String, List<String>>{
    'cielo': <String>['🐥', '🐶'],
    'mar': <String>['🐟'],
    'atardecer': <String>['🐱', '🐶'],
    'noche': <String>['🐱'],
    'espacio': <String>['🐶'],
  };

  /// Cómo se llama cada mascota (para la voz).
  static const Map<String, String> nombresMascotas = <String, String>{
    '🐥': 'el pollito',
    '🐶': 'el perrito',
    '🐱': 'el gatito',
    '🐟': 'el pececito',
    '🐳': 'la ballenita',
  };

  /// La animación de cada mascota (en assets/mascotas/, bajadas de
  /// lottiefiles.com como "Lottie JSON"). Si una mascota no está aquí (como
  /// la ballenita), o el archivo no se puede abrir, se ve su emoji.
  /// Para agregar una nueva, mándale el archivo a Claude: hay que
  /// prepararlo (recortarlo y decir cómo camina) en mascota.dart.
  static const Map<String, String> animacionesMascotas = <String, String>{
    '🐶': 'assets/mascotas/perrito.json',
    '🐱': 'assets/mascotas/gatito.json',
    '🐥': 'assets/mascotas/pollito.json',
    '🐟': 'assets/mascotas/pececito.json',
  };

  /// Qué tan grande es la mascota: su alto, como parte del lado más corto
  /// de la pantalla (0.22 = el 22%).
  static const double tamanoMascota = 0.22;

  /// true = la mascota camina y corre de un lado a otro. false = se queda
  /// quieta en el medio.
  static const bool mascotaCamina = true;

  /// Hasta dónde camina: la parte del ancho de la pantalla, en el medio
  /// (0.7 = el 70%; 1.0 = de borde a borde).
  static const double zonaDeLaMascota = 0.7;

  /// Cada cuánto corre en vez de caminar (0.3 = 3 de cada 10 paseos).
  static const double parteQueCorre = 0.3;

  /// Cuánto más rápido va cuando corre (2.0 = el doble).
  static const double rapidezCorriendo = 1.9;

  /// Cuánto se queda quieta entre un paseo y otro (segundos, al azar entre
  /// estos dos números).
  static const double segundosQuietaMinimo = 0.8;
  static const double segundosQuietaMaximo = 2.5;

  /// Cuántas burbujas sopla la mascota (las demás salen por los lados).
  /// 0.6 = 6 de cada 10. 0 = ninguna (todas por los lados).
  static const double parteQueSoplaLaMascota = 0.6;

  /// true = se ve la mascota.
  static const bool conMascota = true;

  // ------------------------------------------------------------ caritas

  /// true = las burbujas tienen carita (ojos que parpadean y sonrisa). Se
  /// ríen cuando las tocas sin reventarlas (súper, mega y jefes) y cuando
  /// revienta una que está al lado.
  static const bool caritas = true;

  /// La palabra que sale al reventar una burbuja con carita (y "¡POP!" si
  /// no tiene). Antes era '¡AY!'.
  static const String palabraAlReventar = '¡POP!';

  // -------------------------------------------------------------- tamaños
  //
  // Cuánto del ancho de la pantalla mide cada burbuja de lado a lado
  // (0.22 = el 22%).

  static const double tamanoMinimo = 0.19;
  static const double tamanoMaximo = 0.26;
  static const double tamanoSuper = 0.34;
  static const double tamanoAnimalito = 0.27;
  static const double tamanoMega = 0.46;
  static const double tamanoChica = 0.13; // rápidas y las de la mega

  /// Cada cuánto sale una burbuja nueva (en segundos, al azar entre estos
  /// dos números), mientras haya lugar en la pantalla.
  static const double segundosEntreBurbujasMinimo = 0.6;
  static const double segundosEntreBurbujasMaximo = 1.4;

  /// Los colores de las burbujas (se escriben igual que en la lista de
  /// colores de lib/app/ajustes_app.dart).
  static const List<String> colores = <String>[
    'Celeste',
    'Rosado',
    'Morado',
    'Amarillo',
    'Verde',
    'Azul',
    'Naranja',
  ];

  /// true = al reventar sale la palabra de colores ([palabraAlReventar]
  /// si tiene carita, "¡POP!" si no tiene).
  static const bool mostrarPop = true;

  // ------------------------------------------------------- entre niveles

  /// Cuánto se ve el cartel "NIVEL 3" (segundos).
  static const double segundosCartelNivel = 1.0;

  /// Cuánto dura el festejo corto al terminar cada nivel (segundos).
  static const double segundosFestejoCorto = 1.6;

  /// Cada cuántos niveles sale la celebración grande (con el cartel de
  /// estrellas), y cuántos segundos se queda (también se quita tocándola).
  static const int celebracionGrandeCada = 5;
  static const int segundosCelebracionGrande = 4;

  // ------------------------------------------------------------------- voz

  /// Lo que dice la voz al entrar (y con la orejita).
  static const String vozInicio = '¡Revienta todas las burbujas!';

  /// Al empezar cada nivel ({nivel} = el número).
  static const String vozNivel = '¡Nivel {nivel}!';

  /// Cuando aparece un tipo de burbuja por primera vez.
  static const String vozSuper = '¡Súper burbujas! ¡Tócalas muchas veces!';
  static const String vozAnimalito = '¡Burbujas con animalitos!';
  static const String vozMega = '¡Mega burbujas! ¡Tienen burbujitas adentro!';
  static const String vozRapida = '¡Burbujitas rápidas! ¡Atrápalas!';

  /// Cuando llega un jefe.
  static const Map<String, String> vozJefes = <String, String>{
    'rey': '¡Llegó el Rey Burbuja! ¡Tócalo muchas veces!',
    'saltarina': '¡La Burbuja Saltarina! ¡Atrápala!',
    'dormilona': '¡La Burbuja Dormilona! ¡Despiértala!',
    'pinata': '¡La Burbuja Piñata! ¡Tiene burbujitas de dulce!',
  };

  /// Al empezar cada nivel, después del número, dice a qué mundo van
  /// ({mascota} = el nombre de la mascota). Si el nivel trae una burbuja
  /// nueva o un jefe, dice eso en vez del mundo.
  static const Map<String, String> vozMundos = <String, String>{
    'cielo': '¡Al cielo con {mascota}!',
    'mar': '¡Al fondo del mar con {mascota}!',
    'atardecer': '¡Mira el atardecer con {mascota}!',
    'noche': '¡A la noche de estrellas con {mascota}!',
    'espacio': '¡Al espacio con {mascota}!',
  };

  /// Al terminar un nivel (una al azar).
  static const List<String> vozMuyBien = <String>[
    '¡Muy bien!',
    '¡Bravo!',
    '¡Genial!',
    '¡Lo lograste!',
  ];

  /// El texto grande del festejo corto.
  static const String festejoCorto = '¡MUY BIEN!';

  /// La celebración grande (cada [celebracionGrandeCada] niveles).
  static const String celebracionLinea1 = '¡MUY BIEN!';
  static const String celebracionLinea2 = 'REVENTASTE TODAS';
  static const String vozCelebracion =
      '¡Muy bien! ¡Reventaste todas las burbujas!';

  // -------------------------------------------------------------- sonidos
  //
  // Están en assets/sonidos/. Para cambiarlos, pon otro archivo con el
  // mismo nombre (o cambia aquí el nombre).

  /// Al reventar una burbuja suena una de estas explosiones bonitas (van
  /// turnándose, así cada una suena distinta a la anterior):
  ///   explosion1 = brillitos       explosion4 = arpa mágica que sube
  ///   explosion2 = campanitas      explosion5 = gotitas de agua
  ///   explosion3 = fuegos de color explosion6 = confeti
  /// Puedes borrar las que no te gusten o volver a poner los pop de antes
  /// ('burbujas/pop1.wav' ... 'burbujas/pop4.wav').
  static const List<String> sonidosPop = <String>[
    'burbujas/explosion1.wav',
    'burbujas/explosion2.wav',
    'burbujas/explosion3.wav',
    'burbujas/explosion4.wav',
    'burbujas/explosion5.wav',
    'burbujas/explosion6.wav',
  ];

  /// Cada toque a una súper burbuja o a una mega (antes de reventar).
  static const String sonidoSuperToque = 'burbujas/super_toque.wav';

  /// La súper burbuja, la mega o un jefe que revientan.
  static const String sonidoSuperPop = 'burbujas/super_pop.wav';

  /// El animalito que sale volando.
  static const String sonidoAnimalito = 'comunes/acierto.wav';

  /// El "¡ay!" de las burbujas con carita: está QUITADO (lista vacía), así
  /// que también suenan las explosiones de arriba. Para volver a ponerlo,
  /// escribe dentro de los corchetes 'burbujas/ay1.wav', 'burbujas/ay2.wav',
  /// 'burbujas/ay3.wav', 'burbujas/ay4.wav'.
  static const List<String> sonidosAy = <String>[];

  /// La risita ("¡jiji!") de las burbujas y de la mascota.
  static const String sonidoRisa = 'burbujas/jiji.wav';

  /// La mascota que sopla una burbuja (suavecito).
  static const String sonidoSoplo = 'burbujas/soplo.wav';

  /// La mascota que aplaude al pasar de nivel.
  static const String sonidoAplausos = 'burbujas/aplausos.wav';

  /// La música cuando llega un jefe.
  static const String sonidoJefe = 'burbujas/jefe.wav';

  /// La Burbuja Saltarina cuando salta.
  static const String sonidoSalto = 'comunes/boing.wav';
}
