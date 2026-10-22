import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/comun/barra_juego.dart';
import 'package:colorear_ninos/comun/celebracion.dart';
import 'package:colorear_ninos/comun/dificultad.dart';
import 'package:colorear_ninos/comun/estrellitas.dart';
import 'package:colorear_ninos/comun/repartir.dart';
import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/comun/voz.dart';
import 'package:colorear_ninos/juegos/colores/colores_ajustes.dart';
import 'package:colorear_ninos/juegos/colores/globo.dart';

/// El juego "Colores" (Encuentra el color).
///
/// Cada ronda:
///  1. Aparecen unos globos de colores (2 al empezar, hasta 4) y la voz
///     pide uno: "¡Toca el globo rojo!".
///  2. Si toca el correcto: revienta con estrellitas, gana una estrella y
///     la voz la felicita. Después viene otra ronda.
///  3. Si toca otro: ese globo se mueve y la voz le dice qué color es
///     ("Ese es el azul. ¡Busca el rojo!"). Después de equivocarse varias
///     veces, el globo correcto brilla para ayudarla.
///  4. Cada 5 globos reventados sale la celebración grande.
///
/// La orejita de arriba repite lo que hay que buscar.
/// Lo que se puede cambiar está en colores_ajustes.dart.
class ColoresJuego extends StatefulWidget {
  const ColoresJuego({super.key});

  @override
  State<ColoresJuego> createState() => _EstadoColoresJuego();
}

class _EstadoColoresJuego extends State<ColoresJuego>
    with TickerProviderStateMixin {
  final math.Random _azar = math.Random();

  final Dificultad _dificultad = Dificultad(
    minimo: AjustesColores.globosAlEmpezar,
    maximo: AjustesColores.globosMaximo,
    aciertosParaSubir: AjustesColores.aciertosParaSubir,
    erroresParaBajar: AjustesColores.erroresParaBajar,
  );

  /// Los colores de los globos (los de colores_ajustes.dart que existen en
  /// la lista de colores de la app).
  final List<ColorConNombre> _colores = <ColorConNombre>[
    for (final nombre in AjustesColores.colores)
      if (AjustesApp.colorLlamado(nombre) != null)
        AjustesApp.colorLlamado(nombre)!,
  ];

  /// Los globos suben y bajan despacito (y el de ayuda brilla).
  late final AnimationController _flotar = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  /// El globo equivocado se mueve de lado a lado.
  late final AnimationController _temblor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// El globo correcto se infla y desaparece.
  late final AnimationController _reventar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  List<ColorConNombre> _globos = <ColorConNombre>[];
  int _buscado = 0; // cuál de los globos hay que tocar
  int _errores = 0; // cuántas veces se equivocó en esta ronda
  int? _tembloroso; // el globo que se está moviendo
  bool _reventado = false; // ya acertó en esta ronda
  int _estrellas = 0;
  int _ronda = 0;
  bool _celebrando = false;
  ColorConNombre? _anterior;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    Sonidos.preparar(<String>[
      AjustesColores.sonidoReventar,
      AjustesColores.sonidoError,
      Sonidos.aciertoArchivo,
    ]);
    _nuevaRonda();
  }

  @override
  void dispose() {
    _flotar.dispose();
    _temblor.dispose();
    _reventar.dispose();
    super.dispose();
  }

  // ------------------------------------------------------- 1. cada ronda

  /// Elige los globos de la ronda y cuál hay que tocar.
  void _nuevaRonda() {
    if (_colores.isEmpty) return;
    final cantidad = math.min(_dificultad.opciones, _colores.length);
    final mezcla = <ColorConNombre>[..._colores]..shuffle(_azar);
    // El que hay que buscar no repite el de la ronda anterior.
    final buscado = mezcla.firstWhere(
      (c) => c != _anterior,
      orElse: () => mezcla.first,
    );
    final globos = <ColorConNombre>[
      buscado,
      ...mezcla.where((c) => c != buscado).take(cantidad - 1),
    ]..shuffle(_azar);
    _anterior = buscado;
    _reventar.reset();
    setState(() {
      _globos = globos;
      _buscado = globos.indexOf(buscado);
      _errores = 0;
      _tembloroso = null;
      _reventado = false;
      _ronda++;
    });
    _pedirColor();
  }

  String _nombre(ColorConNombre c) => c.nombre.toLowerCase();

  /// La voz dice qué globo tocar (también con la orejita).
  void _pedirColor() {
    if (_globos.isEmpty || _reventado) return;
    final color = _globos[_buscado];
    Voz.decir(
      AjustesColores.vozBusca.replaceAll('{color}', _nombre(color)),
      grabaciones: <String>[AjustesColores.grabacionBusca, color.nombre],
    );
  }

  // --------------------------------------------------- 2. cuando toca

  void _alTocar(int i) {
    if (_reventado || _celebrando) return;
    if (i == _buscado) {
      _acerto();
    } else {
      _seEquivoco(i);
    }
  }

  Future<void> _acerto() async {
    final color = _globos[_buscado];
    setState(() {
      _reventado = true;
      _estrellas++;
    });
    _reventar.forward(from: 0);
    Sonidos.tocar(AjustesColores.sonidoReventar);
    Sonidos.acierto();
    _dificultad.terminoRonda(_errores);
    // La voz la felicita. Se espera a que termine (y a que se vean las
    // estrellitas) antes de la siguiente ronda.
    final frases = AjustesColores.vozAcierto;
    await Future.wait(<Future<void>>[
      Voz.decir(frases[_azar.nextInt(frases.length)]
          .replaceAll('{color}', _nombre(color))),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    await Future<void>.delayed(
        const Duration(milliseconds: AjustesColores.pausaSiguienteRonda));
    if (!mounted) return;
    if (_estrellas % AjustesColores.aciertosParaCelebrar == 0) {
      _celebrar();
    } else {
      _nuevaRonda();
    }
  }

  void _seEquivoco(int i) {
    setState(() {
      _errores++;
      _tembloroso = i;
    });
    _temblor.forward(from: 0);
    Sonidos.tocar(AjustesColores.sonidoError);
    Voz.decir(AjustesColores.vozError
        .replaceAll('{otro}', _nombre(_globos[i]))
        .replaceAll('{color}', _nombre(_globos[_buscado])));
  }

  void _celebrar() {
    setState(() => _celebrando = true);
    Sonidos.felicidades();
    // La voz entra después de las primeras campanitas.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _celebrando) Voz.decir(AjustesColores.vozCelebracion);
    });
  }

  void _terminoCelebracion() {
    if (!mounted) return;
    setState(() => _celebrando = false);
    _nuevaRonda();
  }

  // ------------------------------------------------------ 3. cómo se ve

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // El cielo.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFB3E5FC), AjustesApp.fondoApp],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BarraJuego(estrellas: _estrellas, alRepetir: _pedirColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    child: LayoutBuilder(
                      builder: (context, caja) => _losGlobos(caja.biggest),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                linea1: AjustesColores.celebracionLinea1,
                linea2: AjustesColores.celebracionLinea2,
                alTerminar: _terminoCelebracion,
              ),
            ),
        ],
      ),
    );
  }

  /// Reparte los globos lo más grandes posible (ver comun/repartir.dart).
  Widget _losGlobos(Size tam) {
    final n = _globos.length;
    final lugares = repartir(tam, n, proporcion: 0.72);
    // Si quedaron uno arriba del otro, se corren un poco a los lados
    // (como globos sueltos).
    final enColumna = n > 1 &&
        lugares.every((r) => (r.center.dx - lugares.first.center.dx).abs() < 1);
    final hijos = <Widget>[];
    for (var i = 0; i < n; i++) {
      var lugar = lugares[i];
      if (enColumna) {
        final lado = (tam.width - lugar.width) / 2 * 0.7;
        lugar = lugar.shift(Offset(i.isEven ? -lado : lado, 0));
      }
      hijos.add(Positioned.fromRect(rect: lugar, child: _globo(i)));
      if (_reventado && i == _buscado) {
        hijos.add(Positioned.fromRect(
          rect: lugar.inflate(lugar.width * 0.3),
          child: Estrellitas(key: ValueKey<String>('estrellitas_$_ronda')),
        ));
      }
    }
    return Stack(clipBehavior: Clip.none, children: hijos);
  }

  Widget _globo(int i) {
    final color = _globos[i];
    final esBuscado = i == _buscado;
    final conAyuda =
        esBuscado && !_reventado && _errores >= AjustesColores.erroresParaAyuda;
    return GestureDetector(
      key: ValueKey<String>('globo_${color.nombre}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _alTocar(i),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_flotar, _temblor, _reventar]),
        builder: (context, _) {
          // Sube y baja (cada globo a su ritmo).
          final fase = _flotar.value * 2 * math.pi + i * 1.7;
          final subir = math.sin(fase) * 10;
          // Se mueve de lado a lado si se equivocó con este.
          var giro = 0.0;
          if (_tembloroso == i) {
            final t = _temblor.value;
            giro = math.sin(t * math.pi * 6) * 0.2 * (1 - t);
          }
          // Se infla y desaparece si acertó.
          var escala = 1.0;
          var opacidad = 1.0;
          if (esBuscado && _reventado) {
            escala = 1 + 0.45 * _reventar.value;
            opacidad = 1 - _reventar.value;
          }
          final ayuda = conAyuda
              ? 0.5 + 0.5 * math.sin(_flotar.value * 2 * math.pi * 3)
              : 0.0;
          return Transform.translate(
            offset: Offset(0, subir),
            child: Transform.rotate(
              angle: giro,
              child: Transform.scale(
                scale: escala,
                child: Opacity(
                  opacity: opacidad.clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: PintorGlobo(color.color, ayuda: ayuda),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
