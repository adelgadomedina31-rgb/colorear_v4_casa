import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';

/// Los tipos de burbuja.
enum TipoBurbuja {
  /// La de siempre: un toque y revienta.
  normal,

  /// Grande y dorada: varios toques.
  superBurbuja,

  /// Con un animalito adentro, que sale volando.
  animalito,

  /// Enorme: con 2 toques explota en burbujitas.
  mega,

  /// Chiquita y muy rápida.
  rapida,

  /// Un jefe: gigante, muchos toques (ver [TipoJefe]).
  jefe,

  /// Las burbujitas que salen de una mega o de un jefe.
  chica,
}

/// Los jefes (ver burbujas_ajustes.dart).
enum TipoJefe {
  /// El Rey Burbuja, con corona: con cada toque se enoja de mentiritas y
  /// sale corriendo.
  rey,

  /// Con orejas de conejo: da saltitos, y con cada toque salta lejos.
  saltarina,

  /// Con gorro de dormir: duerme, y al tocarla se despierta y corre.
  dormilona,

  /// Una piñata que se hamaca: con cada toque le caen burbujitas de dulce.
  pinata,

  /// Un fantasma: flota en zigzag y con cada toque dice "¡buu!", se
  /// esconde y aparece en otro lado.
  fantasma,

  /// Un pulpo con tentáculos: nada a empujoncitos, y con cada toque sale
  /// disparado soltando burbujitas para atrás.
  pulpo,

  /// Un dragoncito con alas: vuela haciendo olas, y con cada toque
  /// estornuda chispitas de colores.
  dragon,

  /// Una pelota de playa: rebota y rebota en el piso, y con cada toque
  /// pega un salto muy alto.
  pelota,

  /// Un remolino: da vueltas y vueltas, y con cada toque gira rapidísimo
  /// y tira burbujitas en espiral.
  remolino;

  /// Los jefes que están en la lista de burbujas_ajustes.dart (en ese
  /// orden). Los nombres que no existen no cuentan.
  static List<TipoJefe> get deLosAjustes => <TipoJefe>[
        for (final nombre in AjustesBurbujas.jefes)
          for (final j in TipoJefe.values)
            if (j.name == nombre) j,
      ];
}

/// Cómo es un nivel: cuántas burbujas de cada tipo, qué tan rápido van...
/// Se arma con [PlanNivel.para], a partir de los números de
/// burbujas_ajustes.dart.
class PlanNivel {
  PlanNivel._({
    required this.numero,
    required this.dificultad,
    required this.tranquilo,
    required this.cantidades,
    required this.aLaVez,
    required this.velocidad,
    required this.giros,
    required this.nuevos,
    this.jefe,
    this.toquesJefe = 0,
  });

  /// El número del nivel (1, 2, 3...).
  final int numero;

  /// Qué tan difícil es (igual al número, o menos si es un nivel
  /// tranquilo).
  final int dificultad;

  /// true = es un nivel más tranquilo que el anterior.
  final bool tranquilo;

  /// Cuántas burbujas de cada tipo salen (sin contar las chicas de las
  /// mega).
  final Map<TipoBurbuja, int> cantidades;

  /// Cuántas puede haber en la pantalla al mismo tiempo.
  final int aLaVez;

  /// Qué tan rápido van (parte del ancho de la pantalla por segundo; 0.1 =
  /// el 10%).
  final double velocidad;

  /// Cuánto cambian de dirección.
  final double giros;

  /// Los tipos que aparecen por primera vez en este nivel.
  final List<TipoBurbuja> nuevos;

  /// El jefe del nivel (null = no es nivel de jefe).
  final TipoJefe? jefe;

  /// Cuántos toques necesita el jefe.
  final int toquesJefe;

  int cuantas(TipoBurbuja tipo) => cantidades[tipo] ?? 0;

  /// Cuántas burbujitas suelta el jefe en total (con cada toque y al
  /// reventar).
  int get burbujitasDelJefe {
    if (jefe == null) return 0;
    final porToque = math.max<int>(0, AjustesBurbujas.burbujitasPorToqueJefe);
    final alFinal = math.max<int>(0, AjustesBurbujas.burbujitasAlReventarJefe);
    return (toquesJefe - 1) * porToque + alFinal;
  }

  /// Cuántas hay que reventar en total (con las chicas de las mega y las
  /// que suelta el jefe).
  int get total {
    var suma = 0;
    cantidades.forEach((tipo, n) => suma += n);
    return suma +
        cuantas(TipoBurbuja.mega) * AjustesBurbujas.hijasMega +
        burbujitasDelJefe;
  }

  /// Desde qué nivel sale cada tipo.
  static int desdeNivel(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.normal => 1,
        TipoBurbuja.superBurbuja => AjustesBurbujas.superDesdeNivel,
        TipoBurbuja.animalito => AjustesBurbujas.animalitoDesdeNivel,
        TipoBurbuja.mega => AjustesBurbujas.megaDesdeNivel,
        TipoBurbuja.rapida => AjustesBurbujas.rapidaDesdeNivel,
        TipoBurbuja.jefe => AjustesBurbujas.jefeDesdeNivel,
        TipoBurbuja.chica => 0,
      };

  static int _maximo(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.normal => AjustesBurbujas.burbujasMaximo,
        TipoBurbuja.superBurbuja => AjustesBurbujas.superMaximo,
        TipoBurbuja.animalito => AjustesBurbujas.animalitoMaximo,
        TipoBurbuja.mega => AjustesBurbujas.megaMaximo,
        TipoBurbuja.rapida => AjustesBurbujas.rapidaMaximo,
        TipoBurbuja.jefe => 1,
        TipoBurbuja.chica => 0,
      };

  /// Los tipos especiales que van saliendo con los niveles (los jefes van
  /// aparte).
  static const List<TipoBurbuja> especiales = <TipoBurbuja>[
    TipoBurbuja.superBurbuja,
    TipoBurbuja.animalito,
    TipoBurbuja.mega,
    TipoBurbuja.rapida,
  ];

  /// Arma el nivel [numero]. Usa [azar] para los niveles tranquilos, la
  /// sorpresa de cada nivel y qué jefe viene. [nivelesSinJefe] = cuántos
  /// niveles seguidos van sin jefe. [jefesRecientes] = los últimos jefes
  /// que salieron (el último al final): no se repiten enseguida.
  factory PlanNivel.para(
    int numero,
    math.Random azar, {
    int nivelesSinJefe = 1,
    List<TipoJefe> jefesRecientes = const <TipoJefe>[],
  }) =>
      _armar(
        numero,
        azar,
        elegirJefe: (n) => _elegirJefe(n, azar, nivelesSinJefe, jefesRecientes),
      );

  /// El nivel [numero] con el jefe [jefe] (para las pruebas): sin nivel
  /// tranquilo.
  factory PlanNivel.deJefe(int numero, TipoJefe jefe) => _armar(
        numero,
        math.Random(numero),
        elegirJefe: (_) => jefe,
        conTranquilo: false,
      );

  static PlanNivel _armar(
    int numero,
    math.Random azar, {
    required TipoJefe? Function(int n) elegirJefe,
    bool conTranquilo = true,
  }) {
    final n = math.max(1, numero);

    // A veces, un nivel más tranquilo (nunca en los primeros).
    var d = n;
    var tranquilo = false;
    if (conTranquilo &&
        n > 3 &&
        AjustesBurbujas.nivelesMasFacil > 0 &&
        azar.nextDouble() < AjustesBurbujas.probabilidadNivelTranquilo) {
      d = math.max(1, n - 1 - azar.nextInt(AjustesBurbujas.nivelesMasFacil));
      tranquilo = d < n;
    }

    final cantidades = <TipoBurbuja, int>{
      TipoBurbuja.normal: math.min(
        AjustesBurbujas.burbujasMaximo,
        AjustesBurbujas.burbujasAlEmpezar +
            (d - 1) * AjustesBurbujas.burbujasMasPorNivel,
      ),
    };
    final nuevos = <TipoBurbuja>[];
    final saliendo = <TipoBurbuja>[];
    for (final tipo in especiales) {
      final desde = desdeNivel(tipo);
      if (desde <= 0 || n < desde) continue; // todavía no sale
      saliendo.add(tipo);
      if (n == desde) nuevos.add(tipo);
      final cuantas = 1 +
          math.max(0, d - desde) ~/
              math.max(1, AjustesBurbujas.nivelesParaUnaMas);
      cantidades[tipo] = math.min(_maximo(tipo), cuantas);
    }

    // El jefe del nivel (si le toca).
    final jefe = elegirJefe(n);
    var toques = jefe == null ? 0 : _toquesJefe(d);
    if (jefe != null) cantidades[TipoBurbuja.jefe] = 1;

    // La sorpresa (desde el nivel 2): un tipo viene con más (si no es el
    // nuevo del nivel), así cada nivel es un poco distinto.
    if (n > 1 && AjustesBurbujas.extraSorpresa > 0) {
      final paraSorpresa = <TipoBurbuja>[
        TipoBurbuja.normal,
        for (final t in saliendo)
          if (!nuevos.contains(t)) t,
      ];
      final sorpresa = paraSorpresa[azar.nextInt(paraSorpresa.length)];
      final extra =
          sorpresa == TipoBurbuja.mega ? 1 : AjustesBurbujas.extraSorpresa;
      cantidades[sorpresa] = math.min(
        _maximo(sorpresa) + (sorpresa == TipoBurbuja.normal ? 0 : 1),
        (cantidades[sorpresa] ?? 0) + extra,
      );
    }

    PlanNivel armar() => PlanNivel._(
          numero: n,
          dificultad: d,
          tranquilo: tranquilo,
          cantidades: cantidades,
          aLaVez: _aLaVez(d),
          velocidad: _velocidad(d),
          giros: _giros(d),
          nuevos: nuevos,
          jefe: jefe,
          toquesJefe: toques,
        );
    var plan = armar();
    // Que no pase del máximo: primero se sacan normales (quedan al menos
    // 3); si todavía sobran, de a una especial (queda al menos una de cada
    // tipo), y al final, toques del jefe (le quedan al menos 3).
    final sobra = plan.total - AjustesBurbujas.totalMaximo;
    if (sobra > 0) {
      cantidades[TipoBurbuja.normal] = math.max(
        3,
        plan.cuantas(TipoBurbuja.normal) - sobra,
      );
    }
    const turnos = <TipoBurbuja>[
      TipoBurbuja.rapida,
      TipoBurbuja.animalito,
      TipoBurbuja.superBurbuja,
      TipoBurbuja.mega,
    ];
    var sinSacar = 0;
    for (var k = 0;
        plan.total > AjustesBurbujas.totalMaximo && sinSacar < turnos.length;
        k++) {
      final tipo = turnos[k % turnos.length];
      final hay = plan.cuantas(tipo);
      if (hay > 1) {
        cantidades[tipo] = hay - 1;
        sinSacar = 0;
      } else {
        sinSacar++;
      }
    }
    while (plan.total > AjustesBurbujas.totalMaximo && toques > 3) {
      toques--;
      plan = armar();
    }
    return plan;
  }

  /// Qué jefe viene en el nivel [n] (null = ninguno). La primera vez, el
  /// primero de la lista; después, uno al azar que no haya salido hace
  /// poco.
  static TipoJefe? _elegirJefe(
    int n,
    math.Random azar,
    int nivelesSinJefe,
    List<TipoJefe> recientes,
  ) {
    final jefes = TipoJefe.deLosAjustes;
    final desde = AjustesBurbujas.jefeDesdeNivel;
    if (jefes.isEmpty || desde <= 0 || n < desde) return null;
    if (n == desde) return jefes.first;
    final toca = AjustesBurbujas.probabilidadJefe >= 1 ||
        nivelesSinJefe >= AjustesBurbujas.nivelesSinJefeMaximo ||
        azar.nextDouble() < AjustesBurbujas.probabilidadJefe;
    if (!toca) return null;
    // No se repiten los últimos (los que se puedan, dejando al menos dos
    // para elegir).
    final evitar = math.min(jefesSinRepetir, jefes.length - 2);
    final ultimos = evitar <= 0
        ? const <TipoJefe>[]
        : recientes.sublist(math.max(0, recientes.length - evitar));
    final opciones = jefes.where((j) => !ultimos.contains(j)).toList();
    final lista = opciones.isEmpty ? jefes : opciones;
    return lista[azar.nextInt(lista.length)];
  }

  /// Cuántos de los últimos jefes no se repiten.
  static const int jefesSinRepetir = 4;

  /// Cuántos toques necesita el jefe en un nivel de dificultad [d].
  static int _toquesJefe(int d) {
    final desde = math.max(1, AjustesBurbujas.jefeDesdeNivel);
    return math.max(
      2,
      math.min(
        AjustesBurbujas.toquesJefeMaximo,
        AjustesBurbujas.toquesJefeAlEmpezar +
            math.max(0, d - desde) ~/
                math.max(1, AjustesBurbujas.nivelesParaUnToqueMas),
      ),
    );
  }

  static int _aLaVez(int d) => math.min(
        AjustesBurbujas.aLaVezMaximo,
        AjustesBurbujas.aLaVezAlEmpezar +
            (d - 1) ~/ math.max(1, AjustesBurbujas.nivelesParaUnaMasALaVez),
      );

  static double _velocidad(int d) =>
      math.min(
        AjustesBurbujas.velocidadMaxima,
        AjustesBurbujas.velocidadAlEmpezar +
            (d - 1) * AjustesBurbujas.velocidadMasPorNivel,
      ) /
      100;

  static double _giros(int d) => math.min(
        AjustesBurbujas.girosMaximo,
        AjustesBurbujas.girosAlEmpezar +
            (d - 1) * AjustesBurbujas.girosMasPorNivel,
      );

  /// El orden en que salen: el jefe primero (si hay), después dos
  /// normales, y las demás mezcladas.
  List<TipoBurbuja> orden(math.Random azar) {
    final normales = cuantas(TipoBurbuja.normal);
    final primeras = math.min(2, normales);
    final resto = <TipoBurbuja>[
      for (var i = primeras; i < normales; i++) TipoBurbuja.normal,
      for (final tipo in especiales)
        for (var i = 0; i < cuantas(tipo); i++) tipo,
    ]..shuffle(azar);
    return <TipoBurbuja>[
      if (jefe != null) TipoBurbuja.jefe,
      for (var i = 0; i < primeras; i++) TipoBurbuja.normal,
      ...resto,
    ];
  }
}
