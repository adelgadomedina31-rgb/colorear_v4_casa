import 'dart:async';
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
import 'package:colorear_ninos/juegos/animales/animales_ajustes.dart';

/// El juego "Animales" (Sonidos de animales).
///
/// Cada ronda:
///  1. Aparecen unos animales (2 al empezar, hasta 4) y la voz pregunta
///     "¿Quién hace guau guau?" (o suena el perro de verdad, si está su
///     archivo en assets/sonidos/animales/).
///  2. Si toca el correcto: salta con estrellitas, gana una estrella, la
///     voz la felicita y el animal hace su sonido. Después viene otra ronda.
///  3. Si toca otro: se mueve, la voz le dice cuál es y hace su sonido.
///     Después de equivocarse varias veces, el correcto brilla.
///  4. Cada 5 aciertos sale la celebración grande.
///
/// La orejita de arriba repite la pregunta.
/// Lo que se puede cambiar está en animales_ajustes.dart.
class AnimalesJuego extends StatefulWidget {
  const AnimalesJuego({super.key});

  @override
  State<AnimalesJuego> createState() => _EstadoAnimalesJuego();
}

class _EstadoAnimalesJuego extends State<AnimalesJuego>
    with TickerProviderStateMixin {
  final math.Random _azar = math.Random();

  final Dificultad _dificultad = Dificultad(
    minimo: AjustesAnimales.animalesAlEmpezar,
    maximo: AjustesAnimales.animalesMaximo,
    aciertosParaSubir: AjustesAnimales.aciertosParaSubir,
    erroresParaBajar: AjustesAnimales.erroresParaBajar,
  );

  /// Para que el animal de ayuda brille.
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  /// El animal equivocado se mueve de lado a lado.
  late final AnimationController _temblor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// El animal salta cuando hace su sonido.
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Los archivos de sonido de verdad que hay (id del animal -> archivo).
  Map<String, String> _archivos = <String, String>{};

  List<Animal> _animales = <Animal>[];
  int _buscado = 0; // cuál hay que tocar
  int _errores = 0; // cuántas veces se equivocó en esta ronda
  int? _tembloroso; // el que se está moviendo
  int? _saltando; // el que está haciendo su sonido
  bool _yaAcerto = false; // ya acertó en esta ronda
  int _estrellas = 0;
  int _ronda = 0;
  bool _celebrando = false;
  Animal? _anterior;

  /// Sube cada vez que empieza algo nuevo: así lo que quedó a medias (una
  /// voz y después un sonido) no sigue sonando.
  int _turno = 0;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    Sonidos.preparar(<String>[
      AjustesAnimales.sonidoError,
      Sonidos.aciertoArchivo,
    ]);
    _nuevaRonda(preguntar: false);
    // La primera pregunta, apenas se sepa qué sonidos de verdad hay.
    _buscarSonidos().then((_) {
      if (mounted) _preguntar();
    });
  }

  @override
  void dispose() {
    _turno++;
    _brillo.dispose();
    _temblor.dispose();
    _salto.dispose();
    super.dispose();
  }

  /// Busca qué animales tienen su archivo de sonido de verdad.
  Future<void> _buscarSonidos() async {
    final encontrados = <String, String>{};
    for (final animal in AjustesAnimales.animales) {
      final archivo = await Sonidos.buscar(
          '${AjustesAnimales.carpetaSonidos}/${animal.id}');
      if (archivo != null) encontrados[animal.id] = archivo;
    }
    if (mounted) _archivos = encontrados;
  }

  // ------------------------------------------------------- 1. cada ronda

  /// Elige los animales de la ronda y cuál hay que tocar.
  void _nuevaRonda({bool preguntar = true}) {
    final todos = AjustesAnimales.animales;
    if (todos.isEmpty) return;
    final cantidad = math.min(_dificultad.opciones, todos.length);
    final mezcla = <Animal>[...todos]..shuffle(_azar);
    // El que hay que buscar no repite el de la ronda anterior.
    final buscado = mezcla.firstWhere(
      (a) => a != _anterior,
      orElse: () => mezcla.first,
    );
    final ronda = <Animal>[
      buscado,
      ...mezcla.where((a) => a != buscado).take(cantidad - 1),
    ]..shuffle(_azar);
    _anterior = buscado;
    setState(() {
      _animales = ronda;
      _buscado = ronda.indexOf(buscado);
      _errores = 0;
      _tembloroso = null;
      _saltando = null;
      _yaAcerto = false;
      _ronda++;
    });
    if (preguntar) _preguntar();
  }

  /// La voz pregunta quién hace el sonido (también con la orejita).
  Future<void> _preguntar() async {
    if (_animales.isEmpty || _yaAcerto) return;
    final turno = ++_turno;
    final animal = _animales[_buscado];
    final archivo = _archivos[animal.id];
    if (archivo == null) {
      await Voz.decir(
          AjustesAnimales.vozPregunta.replaceAll('{sonido}', animal.sonido));
      return;
    }
    await Voz.decir(AjustesAnimales.vozPreguntaConSonido);
    if (!mounted || turno != _turno) return;
    await Sonidos.tocarYEsperar(archivo);
  }

  // --------------------------------------------------- 2. cuando toca

  void _alTocar(int i) {
    if (_yaAcerto || _celebrando) return;
    if (i == _buscado) {
      _acerto();
    } else {
      _seEquivoco(i);
    }
  }

  /// Dice [frase] y después el animal [i] hace su sonido (el archivo de
  /// verdad, o la voz diciendo "¡guau guau!").
  Future<void> _decirYSonar(String frase, int i, int turno) async {
    final animal = _animales[i];
    final archivo = _archivos[animal.id];
    if (archivo == null) {
      _saltar(i);
      await Voz.decir('$frase ¡${animal.sonido}!');
      return;
    }
    await Voz.decir(frase);
    if (!mounted || turno != _turno) return;
    _saltar(i);
    await Sonidos.tocarYEsperar(archivo);
  }

  void _saltar(int i) {
    if (!mounted) return;
    setState(() => _saltando = i);
    _salto.forward(from: 0);
  }

  Future<void> _acerto() async {
    final turno = ++_turno;
    final animal = _animales[_buscado];
    setState(() {
      _yaAcerto = true;
      _estrellas++;
    });
    Sonidos.acierto();
    _dificultad.terminoRonda(_errores);
    final frases = AjustesAnimales.vozAcierto;
    await _decirYSonar(
      frases[_azar.nextInt(frases.length)]
          .replaceAll('{animal}', animal.nombre),
      _buscado,
      turno,
    );
    await Future<void>.delayed(
        const Duration(milliseconds: AjustesAnimales.pausaSiguienteRonda));
    if (!mounted || turno != _turno) return;
    if (_estrellas % AjustesAnimales.aciertosParaCelebrar == 0) {
      _celebrar();
    } else {
      _nuevaRonda();
    }
  }

  void _seEquivoco(int i) {
    final turno = ++_turno;
    setState(() {
      _errores++;
      _tembloroso = i;
    });
    _temblor.forward(from: 0);
    Sonidos.tocar(AjustesAnimales.sonidoError);
    _decirYSonar(
      AjustesAnimales.vozError.replaceAll('{animal}', _animales[i].nombre),
      i,
      turno,
    );
  }

  void _celebrar() {
    final turno = ++_turno;
    setState(() => _celebrando = true);
    Sonidos.felicidades();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _celebrando && turno == _turno) {
        Voz.decir(AjustesAnimales.vozCelebracion);
      }
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
          // El pasto.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AjustesApp.fondoApp, Color(0xFFC5E1A5)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BarraJuego(estrellas: _estrellas, alRepetir: _preguntar),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    child: LayoutBuilder(
                      builder: (context, caja) => _losAnimales(caja.biggest),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                linea1: AjustesAnimales.celebracionLinea1,
                linea2: AjustesAnimales.celebracionLinea2,
                alTerminar: _terminoCelebracion,
              ),
            ),
        ],
      ),
    );
  }

  /// Reparte las tarjetas lo más grandes posible (ver comun/repartir.dart).
  Widget _losAnimales(Size tam) {
    final lugares = repartir(tam, _animales.length);
    final hijos = <Widget>[];
    for (var i = 0; i < lugares.length; i++) {
      final lugar = lugares[i];
      hijos.add(Positioned.fromRect(rect: lugar, child: _tarjeta(i)));
      if (_yaAcerto && i == _buscado) {
        hijos.add(Positioned.fromRect(
          rect: lugar.inflate(lugar.width * 0.2),
          child: Estrellitas(key: ValueKey<String>('estrellitas_$_ronda')),
        ));
      }
    }
    return Stack(clipBehavior: Clip.none, children: hijos);
  }

  static const List<Color> _bordes = <Color>[
    Color(0xFFFB8C00),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  Widget _tarjeta(int i) {
    final animal = _animales[i];
    final esBuscado = i == _buscado;
    final conAyuda =
        esBuscado && !_yaAcerto && _errores >= AjustesAnimales.erroresParaAyuda;
    final gano = esBuscado && _yaAcerto;
    return GestureDetector(
      key: ValueKey<String>('animal_${animal.id}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _alTocar(i),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_brillo, _temblor, _salto]),
        builder: (context, _) {
          // Se mueve de lado a lado si se equivocó con este.
          var giro = 0.0;
          if (_tembloroso == i) {
            final t = _temblor.value;
            giro = math.sin(t * math.pi * 6) * 0.15 * (1 - t);
          }
          // Salta cuando hace su sonido.
          var subir = 0.0;
          if (_saltando == i) {
            subir = -math.sin(_salto.value * math.pi) * 30;
          }
          final brillo = conAyuda
              ? 0.5 + 0.5 * math.sin(_brillo.value * 2 * math.pi)
              : 0.0;
          final borde = gano
              ? const Color(0xFF43A047)
              : Color.lerp(_bordes[i % _bordes.length], const Color(0xFFFDD835),
                  brillo)!;
          return Transform.translate(
            offset: Offset(0, subir),
            child: Transform.rotate(
              angle: giro,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: borde, width: 7 + 5 * brillo),
                  boxShadow: <BoxShadow>[
                    const BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                    if (brillo > 0)
                      BoxShadow(
                        color: const Color(0xFFFDD835)
                            .withValues(alpha: 0.7 * brillo),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: FittedBox(
                  child: Text(
                    animal.dibujo,
                    style: const TextStyle(fontSize: 120),
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
