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
  /// El Rey Burbuja, con corona: se achica con cada toque.
  rey,

  /// Con orejas de conejo: con cada toque salta a otro lado.
  saltarina,

  /// Con gorro de dormir: duerme, y al tocarla se despierta y corre.
  dormilona,

  /// Una piñata: con cada toque le caen burbujitas de dulce.
  pinata;

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
  /// sorpresa de cada nivel y los jefes. [nivelesSinJefe] = cuántos
  /// niveles seguidos van sin jefe (0 = el anterior tuvo jefe: este no
  /// tiene). [jefeAnterior] = el último jefe que salió (no se repite).
  factory PlanNivel.para(
    int numero,
    math.Random azar, {
    int nivelesSinJefe = 1,
    TipoJefe? jefeAnterior,
  }) {
    final n = math.max(1, numero);

    // A veces, un nivel más tranquilo (nunca en los primeros).
    var d = n;
    var tranquilo = false;
    if (n > 3 &&
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

    final aLaVez = _aLaVez(d);
    final velocidad = _velocidad(d);
    final giros = _giros(d);

    // ¿Nivel de jefe? Nunca dos seguidos, ni cuando aparece una burbuja
    // nueva. La primera vez, el primero de la lista.
    final jefes = TipoJefe.deLosAjustes;
    final desdeJefe = AjustesBurbujas.jefeDesdeNivel;
    if (jefes.isNotEmpty &&
        desdeJefe > 0 &&
        n >= desdeJefe &&
        nuevos.isEmpty &&
        nivelesSinJefe > 0) {
      TipoJefe? jefe;
      if (n == desdeJefe) {
        jefe = jefes.first;
      } else if (nivelesSinJefe >= AjustesBurbujas.nivelesSinJefeMaximo ||
          azar.nextDouble() < AjustesBurbujas.probabilidadJefe) {
        final otros = jefes.where((j) => j != jefeAnterior).toList();
        final opciones = otros.isEmpty ? jefes : otros;
        jefe = opciones[azar.nextInt(opciones.length)];
      }
      if (jefe != null) {
        return PlanNivel._conJefe(
          numero: n,
          dificultad: d,
          tranquilo: tranquilo,
          jefe: jefe,
          aLaVez: aLaVez,
          velocidad: velocidad,
          giros: giros,
        );
      }
    }

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

    final plan = PlanNivel._(
      numero: n,
      dificultad: d,
      tranquilo: tranquilo,
      cantidades: cantidades,
      aLaVez: aLaVez,
      velocidad: velocidad,
      giros: giros,
      nuevos: nuevos,
    );
    // Primero se sacan normales (quedan al menos 3) y, si todavía sobran,
    // de a una especial (queda al menos una de cada tipo).
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
    return plan;
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

  /// El nivel [numero] con el jefe [jefe] (para las pruebas).
  factory PlanNivel.deJefe(int numero, TipoJefe jefe) {
    final n = math.max(1, numero);
    return PlanNivel._conJefe(
      numero: n,
      dificultad: n,
      tranquilo: false,
      jefe: jefe,
      aLaVez: _aLaVez(n),
      velocidad: _velocidad(n),
      giros: _giros(n),
    );
  }

  /// Un nivel de jefe: el jefe y unas pocas burbujas normales.
  factory PlanNivel._conJefe({
    required int numero,
    required int dificultad,
    required bool tranquilo,
    required TipoJefe jefe,
    required int aLaVez,
    required double velocidad,
    required double giros,
  }) {
    final desde = math.max(1, AjustesBurbujas.jefeDesdeNivel);
    var toques = math.min(
      AjustesBurbujas.toquesJefeMaximo,
      AjustesBurbujas.toquesJefeAlEmpezar +
          math.max(0, dificultad - desde) ~/
              math.max(1, AjustesBurbujas.nivelesParaUnToqueMas),
    );
    toques = math.max(2, toques);
    final cantidades = <TipoBurbuja, int>{
      TipoBurbuja.normal: math.max(0, AjustesBurbujas.normalesConJefe),
      TipoBurbuja.jefe: 1,
    };
    PlanNivel armar() => PlanNivel._(
          numero: numero,
          dificultad: dificultad,
          tranquilo: tranquilo,
          cantidades: cantidades,
          aLaVez: aLaVez,
          velocidad: velocidad,
          giros: giros,
          nuevos: const <TipoBurbuja>[],
          jefe: jefe,
          toquesJefe: toques,
        );
    // Que no pase del máximo: primero menos toques, después menos normales.
    var plan = armar();
    while (plan.total > AjustesBurbujas.totalMaximo && toques > 2) {
      toques--;
      plan = armar();
    }
    while (plan.total > AjustesBurbujas.totalMaximo &&
        plan.cuantas(TipoBurbuja.normal) > 0) {
      cantidades[TipoBurbuja.normal] = plan.cuantas(TipoBurbuja.normal) - 1;
      plan = armar();
    }
    return plan;
  }

  /// El orden en que salen: el jefe primero; si no hay jefe, las dos
  /// primeras siempre normales. Las demás, mezcladas.
  List<TipoBurbuja> orden(math.Random azar) {
    if (jefe != null) {
      return <TipoBurbuja>[
        TipoBurbuja.jefe,
        for (var i = 0; i < cuantas(TipoBurbuja.normal); i++)
          TipoBurbuja.normal,
      ];
    }
    final normales = cuantas(TipoBurbuja.normal);
    final primeras = math.min(2, normales);
    final resto = <TipoBurbuja>[
      for (var i = primeras; i < normales; i++) TipoBurbuja.normal,
      for (final tipo in especiales)
        for (var i = 0; i < cuantas(tipo); i++) tipo,
    ]..shuffle(azar);
    return <TipoBurbuja>[
      for (var i = 0; i < primeras; i++) TipoBurbuja.normal,
      ...resto,
    ];
  }
}
