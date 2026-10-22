import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/comun/barra_juego.dart';
import 'package:colorear_ninos/comun/celebracion.dart';
import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/comun/titulo_colores.dart';
import 'package:colorear_ninos/comun/voz.dart';
import 'package:colorear_ninos/juegos/burbujas/burbuja.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_papas.dart';
import 'package:colorear_ninos/juegos/burbujas/carita.dart';
import 'package:colorear_ninos/juegos/burbujas/mascota.dart';
import 'package:colorear_ninos/juegos/burbujas/mundos.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';

/// El juego "Burbujas" (Revienta las burbujas).
///
/// Cada nivel:
///  1. Cambia el mundo (cielo, mar, atardecer, noche o espacio) y llega su
///     mascota. Sale el cartel "NIVEL 3" y empiezan a salir burbujas, de a
///     poco: la mascota sopla unas desde abajo y otras entran por los lados.
///  2. Flotan por toda la pantalla, cada una a su velocidad, cambiando de
///     dirección y rebotando en los bordes y entre ellas. Tienen carita:
///     parpadean y se ríen.
///  3. Con un toque revientan: "¡AY!", gotitas, papelitos y estrellitas.
///     Hay tipos especiales (súper, animalito, mega, rápidas) y, de vez en
///     cuando, niveles de jefe: ver burbujas_ajustes.dart.
///  4. Arriba se ve cuántas lleva y cuántas faltan. Cuando revienta todas,
///     la mascota aplaude, un festejo corto (o la celebración grande cada 5
///     niveles) y empieza el nivel siguiente. Los niveles no se acaban
///     nunca, y el juego recuerda en qué nivel va.
///
/// Para que vaya fluido, las burbujas se dibujan todas juntas en un solo
/// dibujo que se repinta en cada cuadro (sin rehacer la pantalla).
///
/// La orejita de arriba repite lo que hay que hacer.
/// Lo que se puede cambiar está en burbujas_ajustes.dart.
class BurbujasJuego extends StatefulWidget {
  const BurbujasJuego({super.key, this.nivelInicial, this.semilla, this.jefe});

  /// En qué nivel empieza. Si no se dice, en el que quedó guardado.
  final int? nivelInicial;

  /// Para las pruebas: con el mismo número las burbujas salen siempre
  /// igual. Sin número, cada vez es distinto.
  final int? semilla;

  /// Para las pruebas: el primer nivel es un nivel de este jefe.
  final TipoJefe? jefe;

  @override
  State<BurbujasJuego> createState() => EstadoBurbujasJuego();
}

class EstadoBurbujasJuego extends State<BurbujasJuego>
    with TickerProviderStateMixin {
  late final math.Random _azar = math.Random(widget.semilla);

  /// Avisa en cada cuadro de la pantalla (unas 60 veces por segundo) para
  /// mover las burbujas.
  late final Ticker _reloj = createTicker(_cadaCuadro);

  /// Cambia en cada cuadro: el dibujo de las burbujas se repinta solo.
  final ValueNotifier<int> _cuadro = ValueNotifier<int>(0);

  /// El cartel grande ("NIVEL 3", "¡MUY BIEN!").
  late final AnimationController _cartel = AnimationController(vsync: this);
  String _textoCartel = '';
  double _segundosCartel = 1;

  /// Los colores de las burbujas (los de burbujas_ajustes.dart que existen
  /// en la lista de colores de la app).
  final List<Color> _colores = <Color>[
    for (final nombre in AjustesBurbujas.colores)
      if (AjustesApp.colorLlamado(nombre) != null)
        AjustesApp.colorLlamado(nombre)!.color,
  ];

  /// Segundos desde que entró al juego.
  double _ahora = 0;

  /// El tamaño de la zona donde flotan las burbujas.
  Size? _tam;

  /// El mundo de este nivel (el fondo) y la mascota.
  final VistaMundo _vista = VistaMundo();
  bool _hayMundo = false;
  Mascota? _mascota;

  /// Para que los jefes salgan de vez en cuando (nunca dos seguidos).
  int _nivelesSinJefe = 1;
  TipoJefe? _ultimoJefe;

  int _numeroNivel = 0; // 0 = todavía no empezó
  PlanNivel? _plan;
  final List<Burbuja> _burbujas = <Burbuja>[];
  final List<Estallido> _estallidos = <Estallido>[];
  final List<AnimalLibre> _animales = <AnimalLibre>[];

  /// Las que faltan por salir en este nivel.
  List<TipoBurbuja> _porSalir = <TipoBurbuja>[];
  int _reventadas = 0; // en este nivel
  int _total = 0; // las que hay que reventar en este nivel
  int _estrellas = 0; // en total
  double _proximaSalida = 0;
  bool _terminoNivel = false;
  bool _celebrando = false;
  int _siguienteId = 0;
  int _ultimoLado = -1;
  int _turnoPop = 0;
  int _turnoAy = 0;
  Color? _ultimoColor;

  // Para las pruebas.
  @visibleForTesting
  List<Burbuja> get burbujas => List<Burbuja>.unmodifiable(_burbujas);
  @visibleForTesting
  PlanNivel? get plan => _plan;
  @visibleForTesting
  int get nivel => _numeroNivel;
  @visibleForTesting
  int get reventadas => _reventadas;
  @visibleForTesting
  int get total => _total;
  @visibleForTesting
  int get animalesVolando => _animales.length;
  @visibleForTesting
  double get ahora => _ahora;
  @visibleForTesting
  Mundo get mundo => _vista.mundo;
  @visibleForTesting
  Mascota? get mascota => _mascota;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    Sonidos.preparar(<String>[
      ...AjustesBurbujas.sonidosPop,
      AjustesBurbujas.sonidoSuperToque,
      AjustesBurbujas.sonidoSuperPop,
      AjustesBurbujas.sonidoAnimalito,
      ...AjustesBurbujas.sonidosAy,
      AjustesBurbujas.sonidoRisa,
      AjustesBurbujas.sonidoSoplo,
      AjustesBurbujas.sonidoAplausos,
      AjustesBurbujas.sonidoJefe,
    ]);
    _reloj.start();
    _arrancar();
  }

  @override
  void dispose() {
    _reloj.dispose();
    _cartel.dispose();
    _cuadro.dispose();
    super.dispose();
  }

  double _entre(double a, double b) => a + (b - a) * _azar.nextDouble();

  void _decirQueHacer() => Voz.decir(AjustesBurbujas.vozInicio);

  String _vozDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => AjustesBurbujas.vozSuper,
        TipoBurbuja.animalito => AjustesBurbujas.vozAnimalito,
        TipoBurbuja.mega => AjustesBurbujas.vozMega,
        TipoBurbuja.rapida => AjustesBurbujas.vozRapida,
        _ => '',
      };

  /// Lo que dice la voz del mundo de este nivel ("¡Al fondo del mar con la
  /// ballenita!").
  String? _vozDelMundo() {
    final frase = AjustesBurbujas.vozMundos[_vista.mundo.name];
    if (frase == null || frase.isEmpty) return null;
    final m = _mascota;
    final nombre = m == null ? null : AjustesBurbujas.nombresMascotas[m.emoji];
    if (nombre == null) {
      return frase.replaceAll(' con {mascota}', '').replaceAll('{mascota}', '');
    }
    return frase.replaceAll('{mascota}', nombre);
  }

  /// Elige el mundo del nivel (distinto al anterior) y su mascota.
  void _cambiarMundo() {
    final mundos = Mundo.deLosAjustes;
    if (mundos.isNotEmpty) {
      final otros = <Mundo>[
        for (final m in mundos)
          if (!_hayMundo || m != _vista.mundo) m,
      ];
      final opciones = otros.isEmpty ? mundos : otros;
      final nuevo = opciones[_azar.nextInt(opciones.length)];
      if (_hayMundo) {
        _vista.cambiarA(nuevo, _ahora);
      } else {
        _vista.mundo = nuevo;
      }
      _hayMundo = true;
    }
    final lista =
        AjustesBurbujas.mascotas[_vista.mundo.name] ?? const <String>[];
    if (!AjustesBurbujas.conMascota || lista.isEmpty) {
      _mascota = null;
      return;
    }
    final emoji = lista[_azar.nextInt(lista.length)];
    final antes = _mascota;
    if (antes != null && antes.emoji == emoji && antes.mundo == _vista.mundo) {
      return; // la misma: se queda
    }
    _mascota = Mascota(emoji, _vista.mundo)..llega = _ahora;
  }

  // ------------------------------------------------------- 1. cada nivel

  /// Empieza en el nivel guardado (o en el que se pidió).
  Future<void> _arrancar() async {
    final nivel = widget.nivelInicial ?? await ProgresoBurbujas.cargar();
    if (!mounted) return;
    _empezarNivel(nivel, alEntrar: true);
  }

  void _empezarNivel(int numero, {bool alEntrar = false}) {
    final jefePedido = alEntrar ? widget.jefe : null;
    final plan = jefePedido != null
        ? PlanNivel.deJefe(numero, jefePedido)
        : PlanNivel.para(
            numero,
            _azar,
            nivelesSinJefe: _nivelesSinJefe,
            jefeAnterior: _ultimoJefe,
          );
    if (plan.jefe != null) {
      _nivelesSinJefe = 0;
      _ultimoJefe = plan.jefe;
    } else {
      _nivelesSinJefe++;
    }
    setState(() {
      _numeroNivel = plan.numero;
      _plan = plan;
      _porSalir = plan.orden(_azar);
      _total = plan.total;
      _burbujas.clear();
      _reventadas = 0;
      _terminoNivel = false;
      _proximaSalida = _ahora + 0.5;
      _cambiarMundo();
    });
    ProgresoBurbujas.guardar(plan.numero);
    _mostrarCartel('NIVEL ${plan.numero}', AjustesBurbujas.segundosCartelNivel);

    // La voz: al entrar, qué hacer; en cada nivel, su número y lo nuevo (el
    // jefe, una burbuja nueva o el mundo).
    final jefe = plan.jefe;
    String? queHay = jefe == null ? null : AjustesBurbujas.vozJefes[jefe.name];
    if (queHay == null && plan.nuevos.isNotEmpty) {
      queHay = _vozDe(plan.nuevos.first);
    }
    if (jefe != null) Sonidos.tocar(AjustesBurbujas.sonidoJefe);
    final numeroNivel = AjustesBurbujas.vozNivel.replaceAll(
      '{nivel}',
      '${plan.numero}',
    );
    if (alEntrar) {
      Voz.decir(queHay ?? AjustesBurbujas.vozInicio);
    } else {
      queHay ??= _vozDelMundo();
      Voz.decir(queHay == null ? numeroNivel : '$numeroNivel $queHay');
    }
  }

  void _mostrarCartel(String texto, double segundos) {
    _textoCartel = texto;
    _segundosCartel = math.max(0.3, segundos);
    _cartel.duration = Duration(milliseconds: (_segundosCartel * 1000).round());
    _cartel.forward(from: 0);
  }

  // ----------------------------------------- 2. salen y flotan (cada cuadro)

  void _cadaCuadro(Duration tiempo) {
    final t = tiempo.inMicroseconds / 1e6;
    // Si un cuadro tardó mucho, no saltan de golpe.
    final dt = (t - _ahora).clamp(0.0, 0.05);
    _ahora = t;
    _vista.ahora = t;
    _mover(dt);
    _salir();
    _estallidos.removeWhere((e) => e.terminado(_ahora));
    _animales.removeWhere((a) => a.terminado(_ahora));
    _cuadro.value++;
  }

  double _radioDe(TipoBurbuja tipo, double lado) {
    final tamano = switch (tipo) {
      TipoBurbuja.superBurbuja => AjustesBurbujas.tamanoSuper,
      TipoBurbuja.animalito => AjustesBurbujas.tamanoAnimalito,
      TipoBurbuja.mega => AjustesBurbujas.tamanoMega,
      TipoBurbuja.jefe => AjustesBurbujas.tamanoJefe,
      TipoBurbuja.rapida ||
      TipoBurbuja.chica =>
        AjustesBurbujas.tamanoChica * _entre(0.9, 1.1),
      TipoBurbuja.normal => _entre(
          AjustesBurbujas.tamanoMinimo,
          AjustesBurbujas.tamanoMaximo,
        ),
    };
    return tamano * lado / 2;
  }

  /// Cuánto más lento o más rápido que las normales.
  double _rapidezDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => 0.75,
        TipoBurbuja.mega => 0.55,
        TipoBurbuja.animalito => 0.9,
        TipoBurbuja.jefe => 0.4,
        TipoBurbuja.rapida => AjustesBurbujas.velocidadRapidas,
        TipoBurbuja.chica => 1.3,
        TipoBurbuja.normal => 1.0,
      };

  int _toquesDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => math.max(2, AjustesBurbujas.toquesSuper),
        TipoBurbuja.mega => math.max(1, AjustesBurbujas.toquesMega),
        TipoBurbuja.jefe => math.max(2, _plan?.toquesJefe ?? 2),
        _ => 1,
      };

  Color _otroColor() {
    if (_colores.isEmpty) return const Color(0xFF4FC3F7);
    var color = _colores[_azar.nextInt(_colores.length)];
    if (_colores.length > 1 && color == _ultimoColor) {
      color = _colores[(_colores.indexOf(color) + 1) % _colores.length];
    }
    _ultimoColor = color;
    return color;
  }

  /// Sale una burbuja nueva si le toca y hay lugar.
  void _salir() {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || tam.isEmpty || plan == null || _celebrando) return;
    if (_porSalir.isEmpty || _burbujas.length >= math.max(1, plan.aLaVez)) {
      return;
    }
    if (_ahora < _proximaSalida) return;

    final tipo = _porSalir.removeAt(0);
    final lado = tam.shortestSide;
    final radio = _radioDe(tipo, lado);
    final w = tam.width;
    final h = tam.height;
    final mascota = _mascota;
    final jefe = tipo == TipoBurbuja.jefe ? plan.jefe : null;

    final Offset inicio;
    final double rumbo;
    var soplada = false;
    if (jefe != null) {
      // El jefe baja desde arriba, por el medio.
      inicio = Offset(w / 2, -radio);
      rumbo = math.pi / 2;
    } else if (mascota != null &&
        _azar.nextDouble() < AjustesBurbujas.parteQueSoplaLaMascota) {
      // La sopla la mascota: sale de su boca, chiquita, y sube.
      soplada = true;
      inicio = mascota.boca(tam);
      rumbo = -math.pi / 2 + _entre(-0.6, 0.6);
      mascota.soplo = _ahora;
      Sonidos.tocar(AjustesBurbujas.sonidoSoplo);
    } else {
      // Sale por un lado distinto al de la anterior, desde afuera.
      var borde = _azar.nextInt(4);
      if (borde == _ultimoLado) borde = (borde + 1 + _azar.nextInt(3)) % 4;
      _ultimoLado = borde;
      double a(double largo) => _entre(radio, math.max(radio, largo - radio));
      inicio = switch (borde) {
        0 => Offset(a(w), -radio), // arriba
        1 => Offset(w + radio, a(h)), // derecha
        2 => Offset(a(w), h + radio), // abajo
        _ => Offset(-radio, a(h)), // izquierda
      };
      // Va hacia un punto al azar del medio de la pantalla.
      final destino = Offset(_entre(0.25, 0.75) * w, _entre(0.25, 0.75) * h);
      rumbo = math.atan2(destino.dy - inicio.dy, destino.dx - inicio.dx);
    }
    final animales = AjustesBurbujas.animalitos;

    _burbujas.add(
      Burbuja(
        id: _siguienteId++,
        tipo: tipo,
        centro: inicio,
        radio: radio,
        color: jefe != null ? colorDeJefe(jefe) : _otroColor(),
        velocidad: plan.velocidad * lado * _entre(0.7, 1.3) * _rapidezDe(tipo),
        rumbo: rumbo,
        fase: _azar.nextDouble() * 2 * math.pi,
        nace: soplada ? _ahora : -10,
        toques: _toquesDe(tipo),
        animal: tipo == TipoBurbuja.animalito && animales.isNotEmpty
            ? animales[_azar.nextInt(animales.length)]
            : null,
        jefe: jefe,
        soplada: soplada,
      )..proximoCambio = _ahora + _entre(0.8, 2.0),
    );
    _proximaSalida = _ahora +
        _entre(
          AjustesBurbujas.segundosEntreBurbujasMinimo,
          AjustesBurbujas.segundosEntreBurbujasMaximo,
        );
  }

  /// Mueve las burbujas: cada una a su velocidad (que sube y baja un poco),
  /// cambiando de dirección de a poco y rebotando en los bordes.
  void _mover(double dt) {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || plan == null || dt <= 0) return;
    final w = tam.width;
    final h = tam.height;
    final centroZona = Offset(w / 2, h / 2);
    for (final b in _burbujas) {
      b.golpe = math.max(0, b.golpe - dt * 2.2);
      final r = b.radio;
      // La saltarina en el aire: va de un lugar al otro dando un salto.
      if (b.saltando(_ahora)) {
        final f = ((_ahora - b.saltoInicio) / Burbuja.duracionSalto).clamp(
          0.0,
          1.0,
        );
        final e = Curves.easeInOut.transform(f);
        b.centro = Offset.lerp(b.saltoDesde, b.saltoHasta, e)! -
            Offset(0, math.sin(f * math.pi) * r * 0.9);
        continue;
      }
      if (b.adentro) {
        if (_ahora >= b.proximoCambio) {
          final rapida = b.tipo == TipoBurbuja.rapida;
          b.giroBuscado = (_azar.nextDouble() * 2 - 1) *
              1.3 *
              plan.giros *
              (rapida ? 1.6 : 1);
          b.proximoCambio =
              _ahora + _entre(rapida ? 0.5 : 1.0, rapida ? 1.4 : 2.6);
        }
        b.giro += (b.giroBuscado - b.giro) * math.min(1.0, dt * 2);
        b.rumbo += b.giro * dt;
      } else {
        // Mientras entra, si se está alejando, vuelve hacia el medio.
        final hacia = centroZona - b.centro;
        final va = Offset(math.cos(b.rumbo), math.sin(b.rumbo));
        if (hacia.dx * va.dx + hacia.dy * va.dy < 0) {
          b.rumbo = math.atan2(hacia.dy, hacia.dx);
        }
      }
      var v = b.velocidad * (1 + 0.25 * math.sin(_ahora * 0.9 + b.fase));
      // La dormilona va lentito mientras duerme, y corre cuando la despiertan.
      if (b.jefe == TipoJefe.dormilona) v *= b.despierta(_ahora) ? 2.2 : 0.35;
      b.centro += Offset(math.cos(b.rumbo), math.sin(b.rumbo)) * v * dt;

      final c = b.centro;
      final arriba = b.margenArriba;
      if (!b.adentro) {
        if (c.dx >= r && c.dx <= w - r && c.dy >= arriba && c.dy <= h - r) {
          b.adentro = true;
        }
        continue;
      }
      // Rebota en los bordes.
      var dx = math.cos(b.rumbo);
      var dy = math.sin(b.rumbo);
      var reboto = false;
      if ((c.dx < r && dx < 0) || (c.dx > w - r && dx > 0)) {
        dx = -dx;
        reboto = true;
      }
      if ((c.dy < arriba && dy < 0) || (c.dy > h - r && dy > 0)) {
        dy = -dy;
        reboto = true;
      }
      if (reboto) {
        b.rumbo = math.atan2(dy, dx);
        b.giroBuscado = -b.giroBuscado;
        b.giro = -b.giro;
      }
    }
    _chocar();
  }

  /// Dos burbujas que se tocan se empujan y rebotan una con la otra (así no
  /// quedan una encima de la otra).
  void _chocar() {
    for (var i = 0; i < _burbujas.length; i++) {
      final a = _burbujas[i];
      if (!a.adentro || a.saltando(_ahora)) continue;
      for (var j = i + 1; j < _burbujas.length; j++) {
        final b = _burbujas[j];
        if (!b.adentro || b.saltando(_ahora)) continue;
        final entre = a.centro - b.centro;
        final distancia = entre.distance;
        final juntas = (a.radio + b.radio) * 0.95;
        if (distancia >= juntas || distancia == 0) continue;
        // Se separan (la más grande se mueve menos).
        final n = entre / distancia;
        final sobra = juntas - distancia;
        final parteA = b.radio / (a.radio + b.radio);
        a.centro = _dentro(a, a.centro + n * sobra * parteA);
        b.centro = _dentro(b, b.centro - n * sobra * (1 - parteA));
        // Rebotan (solo si iban una hacia la otra).
        a.rumbo = _reflejar(a.rumbo, n);
        b.rumbo = _reflejar(b.rumbo, -n);
      }
    }
  }

  /// [p], sin salirse de la pantalla (para la burbuja [b]).
  Offset _dentro(Burbuja b, Offset p) {
    final tam = _tam;
    if (tam == null) return p;
    final r = b.radio;
    final arriba = math.min(b.margenArriba, tam.height / 2);
    return Offset(
      p.dx.clamp(r, math.max(r, tam.width - r)),
      p.dy.clamp(arriba, math.max(arriba, tam.height - r)),
    );
  }

  /// La nueva dirección de una burbuja que choca: si iba contra [n] (la
  /// dirección que la aleja de la otra), rebota.
  double _reflejar(double rumbo, Offset n) {
    final dx = math.cos(rumbo);
    final dy = math.sin(rumbo);
    final contra = dx * n.dx + dy * n.dy;
    if (contra >= 0) return rumbo;
    return math.atan2(dy - 2 * contra * n.dy, dx - 2 * contra * n.dx);
  }

  // --------------------------------------------------- 3. cuando toca

  void _alTocar(PointerDownEvent evento) {
    if (_celebrando) return;
    final p = evento.localPosition;
    // La burbuja más cerca del dedo (con un poquito de ayuda alrededor; las
    // chiquitas con más ayuda).
    Burbuja? tocada;
    if (!_terminoNivel) {
      var mejor = double.infinity;
      for (final b in _burbujas) {
        final limite = b.radio * 1.15 + (b.chiquita ? 18 : 8);
        final cerca = (b.centro - p).distance / limite;
        if (cerca <= 1 && cerca < mejor) {
          mejor = cerca;
          tocada = b;
        }
      }
    }
    if (tocada != null) {
      _tocar(tocada);
      return;
    }
    // Si no tocó ninguna burbuja pero sí a la mascota: salta y se ríe.
    final m = _mascota;
    final tam = _tam;
    if (m != null && tam != null && m.lugar(tam).inflate(8).contains(p)) {
      if (!m.saltando(_ahora)) {
        m.salto = _ahora;
        Sonidos.tocar(AjustesBurbujas.sonidoRisa);
      }
    }
  }

  void _tocar(Burbuja b) {
    // Le faltan toques: "boing", se achica un poco y se ríe.
    if (b.toques > 1) {
      setState(() {
        b.toques--;
        b.golpe = 1;
        b.risa = _ahora;
        final jefe = b.jefe;
        if (jefe != null) {
          // El jefe se va achicando hasta [jefeAchicaHasta] y suelta
          // burbujitas.
          final f = (b.toques - 1) / math.max(1, b.toquesTotales - 1);
          final hasta = AjustesBurbujas.jefeAchicaHasta.clamp(0.1, 1.0);
          b.radio = b.radioInicial * (hasta + (1 - hasta) * f);
          _soltarChicas(b, AjustesBurbujas.burbujitasPorToqueJefe);
          switch (jefe) {
            case TipoJefe.saltarina:
              _saltar(b);
            case TipoJefe.dormilona:
              b.despiertaHasta = _ahora + 2.5;
            default:
              break;
          }
        } else {
          b.radio *= b.tipo == TipoBurbuja.mega ? 0.95 : 0.93;
        }
        _estallidos.add(
          Estallido(
            centro: b.centro,
            radio: b.radio,
            color: b.color,
            inicio: _ahora,
            chico: true,
            conPalabra: false,
          ),
        );
      });
      Sonidos.tocar(AjustesBurbujas.sonidoSuperToque);
      if (b.conCarita) Sonidos.tocar(AjustesBurbujas.sonidoRisa);
      if (b.jefe == TipoJefe.saltarina) {
        Sonidos.tocar(AjustesBurbujas.sonidoSalto);
      }
      return;
    }
    _reventar(b);
  }

  /// La saltarina salta a otro lugar de la pantalla (lejos de donde está).
  void _saltar(Burbuja b) {
    final tam = _tam;
    if (tam == null) return;
    final r = b.radio;
    final arriba = b.margenArriba;
    final w = tam.width;
    final h = tam.height;
    var destino = b.centro;
    for (var intento = 0; intento < 8; intento++) {
      destino = Offset(
        _entre(r, math.max(r, w - r)),
        _entre(arriba, math.max(arriba, h - r)),
      );
      if ((destino - b.centro).distance > r * 1.2) break;
    }
    b
      ..saltoDesde = b.centro
      ..saltoHasta = destino
      ..saltoInicio = _ahora
      ..adentro = true;
  }

  /// ¡Revienta!
  void _reventar(Burbuja b) {
    if (!_burbujas.contains(b)) return;
    final grande = b.tipo == TipoBurbuja.superBurbuja ||
        b.tipo == TipoBurbuja.mega ||
        b.tipo == TipoBurbuja.jefe;

    // El sonido: "¡ay!" si tiene carita, si no "¡blup!".
    final ay = AjustesBurbujas.sonidosAy;
    if (b.conCarita && ay.isNotEmpty) {
      Sonidos.tocar(ay[_turnoAy++ % ay.length]);
    } else if (!grande) {
      final sonidos = AjustesBurbujas.sonidosPop;
      if (sonidos.isNotEmpty) {
        Sonidos.tocar(sonidos[_turnoPop++ % sonidos.length]);
      }
    }
    if (grande) Sonidos.tocar(AjustesBurbujas.sonidoSuperPop);
    if (b.tipo == TipoBurbuja.animalito) {
      Sonidos.tocar(AjustesBurbujas.sonidoAnimalito);
    }

    setState(() {
      _burbujas.remove(b);
      _estallidos.add(
        Estallido(
          centro: b.centro,
          radio: b.radio,
          color: b.color,
          inicio: _ahora,
          grande: grande,
          arcoiris: b.jefe == TipoJefe.pinata,
          conPalabra: AjustesBurbujas.mostrarPop,
          carita: b.conCarita,
        ),
      );
      _reventadas++;
      _estrellas++;

      // Las que estaban al lado se ríen.
      for (final o in _burbujas) {
        if ((o.centro - b.centro).distance < (o.radio + b.radio) * 1.8) {
          o.risa = _ahora;
        }
      }

      switch (b.tipo) {
        case TipoBurbuja.mega:
          _soltarChicas(b, AjustesBurbujas.hijasMega);
        case TipoBurbuja.jefe:
          // ¡El jefe explota en muchas burbujitas, y la mascota aplaude!
          _soltarChicas(b, AjustesBurbujas.burbujitasAlReventarJefe);
          final m = _mascota;
          if (m != null) {
            m
              ..aplaudeDesde = _ahora
              ..aplaudeHasta = _ahora + 1.2;
          }
          Sonidos.tocar(AjustesBurbujas.sonidoAplausos);
        case TipoBurbuja.animalito:
          if (b.animal != null) {
            _animales.add(AnimalLibre(b.animal!, b.centro, b.radio, _ahora));
          }
        default:
          break;
      }

      // Si no queda ninguna en la pantalla, la siguiente sale enseguida.
      if (_burbujas.isEmpty) {
        _proximaSalida = math.min(_proximaSalida, _ahora + 0.3);
      }
    });
    _revisarFin();
  }

  /// Salen [n] burbujitas de la burbuja [de] (una mega o un jefe), para
  /// todos lados. Las de la piñata son de colores de dulce y caen.
  List<Burbuja> _soltarChicas(Burbuja de, int n) {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || plan == null || n <= 0) return const <Burbuja>[];
    final lado = tam.shortestSide;
    final pinata = de.jefe == TipoJefe.pinata;
    final hijas = <Burbuja>[];
    final giro = _azar.nextDouble() * 2 * math.pi;
    for (var i = 0; i < n; i++) {
      final angulo = pinata
          ? math.pi / 2 + _entre(-0.9, 0.9)
          : giro + i * 2 * math.pi / n + _entre(-0.3, 0.3);
      final direccion = Offset(math.cos(angulo), math.sin(angulo));
      final radio = _radioDe(TipoBurbuja.chica, lado);
      var centro = de.centro + direccion * de.radio * 0.45;
      // Que no queden afuera de la pantalla.
      centro = Offset(
        centro.dx.clamp(radio, math.max(radio, tam.width - radio)),
        centro.dy.clamp(radio, math.max(radio, tam.height - radio)),
      );
      hijas.add(
        Burbuja(
          id: _siguienteId++,
          tipo: TipoBurbuja.chica,
          centro: centro,
          radio: radio,
          color: pinata
              ? coloresDulces[_azar.nextInt(coloresDulces.length)]
              : _otroColor(),
          velocidad: plan.velocidad * lado * _rapidezDe(TipoBurbuja.chica),
          rumbo: angulo,
          fase: _azar.nextDouble() * 2 * math.pi,
          nace: _ahora,
        )
          ..adentro = true
          ..proximoCambio = _ahora + _entre(0.8, 2.0),
      );
    }
    _burbujas.addAll(hijas);
    return hijas;
  }

  void _revisarFin() {
    if (_terminoNivel || _burbujas.isNotEmpty || _porSalir.isNotEmpty) {
      return;
    }
    _terminoNivel = true;
    // Ya queda guardado que el próximo es el siguiente.
    ProgresoBurbujas.guardar(_numeroNivel + 1);
    // Se deja ver la última explosión antes del festejo.
    Future<void>.delayed(const Duration(milliseconds: 450), _festejar);
  }

  void _festejar() {
    if (!mounted) return;
    // La mascota aplaude.
    final m = _mascota;
    if (m != null) {
      m
        ..aplaudeDesde = _ahora
        ..aplaudeHasta = _ahora + AjustesBurbujas.segundosFestejoCorto + 0.2;
    }
    Sonidos.tocar(AjustesBurbujas.sonidoAplausos);
    final cada = AjustesBurbujas.celebracionGrandeCada;
    if (cada > 0 && _numeroNivel % cada == 0) {
      // La celebración grande.
      setState(() => _celebrando = true);
      Sonidos.felicidades();
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _celebrando) Voz.decir(AjustesBurbujas.vozCelebracion);
      });
      return;
    }
    // El festejo corto: fuegos artificiales de burbujas y "¡MUY BIEN!".
    final tam = _tam;
    if (tam != null) {
      for (var k = 0; k < 5; k++) {
        _estallidos.add(
          Estallido(
            centro: Offset(
              _entre(0.15, 0.85) * tam.width,
              _entre(0.15, 0.7) * tam.height,
            ),
            radio: tam.shortestSide * _entre(0.08, 0.13),
            color: _otroColor(),
            inicio: _ahora + k * 0.2,
            grande: true,
            arcoiris: k.isOdd,
            conPalabra: false,
          ),
        );
      }
    }
    Sonidos.acierto();
    final frases = AjustesBurbujas.vozMuyBien;
    if (frases.isNotEmpty) Voz.decir(frases[_azar.nextInt(frases.length)]);
    _mostrarCartel(
      AjustesBurbujas.festejoCorto,
      AjustesBurbujas.segundosFestejoCorto,
    );
    final nivel = _numeroNivel;
    Future<void>.delayed(
      Duration(
        milliseconds: (AjustesBurbujas.segundosFestejoCorto * 1000).round(),
      ),
      () {
        if (mounted && _numeroNivel == nivel && _terminoNivel) {
          _empezarNivel(nivel + 1);
        }
      },
    );
  }

  void _terminoCelebracion() {
    if (!mounted) return;
    setState(() => _celebrando = false);
    _empezarNivel(_numeroNivel + 1);
  }

  // ------------------------------------------------------ 4. cómo se ve

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // El mundo de este nivel (cielo, mar...), que se mueve.
          Positioned.fill(
            child: RepaintBoundary(
              child: Builder(
                builder: (context) => CustomPaint(
                  painter: PintorMundo(
                    _vista,
                    repaint: _cuadro,
                    abajo: MediaQuery.paddingOf(context).bottom,
                    letra: DefaultTextStyle.of(context).style,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BarraJuego(estrellas: _estrellas, alRepetir: _decirQueHacer),
                _progreso(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, caja) {
                      _tam = caja.biggest;
                      return _zonaDeJuego(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                linea1: AjustesBurbujas.celebracionLinea1,
                linea2: AjustesBurbujas.celebracionLinea2,
                segundos: AjustesBurbujas.segundosCelebracionGrande,
                alTerminar: _terminoCelebracion,
              ),
            ),
        ],
      ),
    );
  }

  /// Cuántas lleva y cuántas faltan: una burbujita por cada burbuja del
  /// nivel (las que ya reventó son estrellas). Si son muchas, una barra.
  Widget _progreso() {
    final total = _total;
    final Widget contenido;
    if (total <= 24) {
      contenido = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: i < _reventadas
                    ? const Icon(
                        Icons.star_rounded,
                        key: ValueKey<String>('hecha'),
                        size: 28,
                        color: Color(0xFFFFC107),
                      )
                    : Container(
                        key: const ValueKey<String>('falta'),
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.6),
                          border: Border.all(
                            color: const Color(0xFF4FC3F7),
                            width: 2.5,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      );
    } else {
      final parte = total == 0 ? 0.0 : _reventadas / total;
      contenido = Row(
        children: [
          const Icon(Icons.star_rounded, size: 28, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                key: const ValueKey<String>('barra'),
                value: parte,
                minHeight: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                color: const Color(0xFFFFC107),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      key: const ValueKey<String>('progreso'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(height: 30, child: contenido),
    );
  }

  Widget _zonaDeJuego(BuildContext context) {
    final letra = DefaultTextStyle.of(context).style;
    return Listener(
      key: const ValueKey<String>('zona'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _alTocar,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PintorJuego(this, letra)),
              ),
            ),
            // El cartel grande ("NIVEL 3", "¡MUY BIEN!").
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _cartel,
                  builder: (context, _) {
                    if (!_cartel.isAnimating || _celebrando) {
                      return const SizedBox.shrink();
                    }
                    final s = _cartel.value * _segundosCartel;
                    final crece = Curves.easeOutBack.transform(
                      (s / 0.25).clamp(0.0, 1.0),
                    );
                    final queda = _segundosCartel - s;
                    final opacidad = (queda / 0.25).clamp(0.0, 1.0);
                    return Center(
                      child: Opacity(
                        opacity: opacidad,
                        child: Transform.scale(
                          scale: 0.3 + 0.7 * crece,
                          child: TituloColores(
                            _textoCartel,
                            key: const ValueKey<String>('cartel'),
                            tamano: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja todo lo que se mueve (la mascota, las burbujas, las explosiones y
/// los animalitos) en un solo dibujo, que se repinta en cada cuadro.
class _PintorJuego extends CustomPainter {
  _PintorJuego(this.juego, this.letra) : super(repaint: juego._cuadro);

  final EstadoBurbujasJuego juego;
  final TextStyle letra;

  @override
  void paint(Canvas canvas, Size tam) {
    final ahora = juego._ahora;
    final mascota = juego._mascota;
    if (mascota != null)
      pintarMascota(canvas, tam, mascota, ahora, letra: letra);
    for (final b in juego._burbujas) {
      pintarBurbuja(canvas, b, ahora, letra: letra);
    }
    pintarEstallidos(canvas, juego._estallidos, ahora, letra: letra);
    pintarAnimales(canvas, juego._animales, ahora, letra: letra);
  }

  @override
  bool shouldRepaint(covariant _PintorJuego viejo) =>
      viejo.juego != juego || viejo.letra != letra;
}
