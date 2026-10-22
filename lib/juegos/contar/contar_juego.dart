import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:colorear_ninos/comun/barra_juego.dart';
import 'package:colorear_ninos/comun/celebracion.dart';
import 'package:colorear_ninos/comun/dificultad.dart';
import 'package:colorear_ninos/comun/estrellitas.dart';
import 'package:colorear_ninos/comun/repartir.dart';
import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/comun/voz.dart';
import 'package:colorear_ninos/juegos/contar/contar_ajustes.dart';

/// El juego "¿Cuántos hay?" (Contar).
///
/// Cada ronda:
///  1. Aparecen unas cosas (3 manzanas, 2 pollitos...) y la voz dice
///     "¡Cuenta las manzanas! Toca cada una.".
///  2. Al tocar cada una, salta, suena una notita que va subiendo, la voz
///     dice el número ("uno", "dos"...) y le queda puesto su número.
///     Arriba se ve el número grande.
///  3. Cuando contó todas, la voz pregunta "¿Cuántas manzanas hay?" y abajo
///     salen botones con números (con puntitos para ayudarla).
///  4. Si acierta: estrellitas, una estrella y la voz la felicita.
///     Si toca otro: el botón se mueve, la voz dice "Ese es el dos.
///     ¡Contemos otra vez!" y la voz cuenta con ella cada cosa. Después de
///     equivocarse varias veces, el botón correcto brilla.
///  5. Cada 5 aciertos sale la celebración grande.
///
/// La orejita de arriba repite lo que hay que hacer.
/// Lo que se puede cambiar está en contar_ajustes.dart.
class ContarJuego extends StatefulWidget {
  const ContarJuego({super.key, this.semilla});

  /// Para las pruebas: con el mismo número las rondas salen siempre
  /// iguales. Sin número, cada vez es distinto.
  final int? semilla;

  @override
  State<ContarJuego> createState() => _EstadoContarJuego();
}

/// En qué parte de la ronda va.
enum _Fase { contando, preguntando, acerto }

class _EstadoContarJuego extends State<ContarJuego>
    with TickerProviderStateMixin {
  late final math.Random _azar = math.Random(widget.semilla);

  final Dificultad _dificultad = Dificultad(
    minimo: AjustesContar.hastaAlEmpezar.clamp(1, 10),
    maximo: math
        .max(AjustesContar.hastaAlEmpezar, AjustesContar.hastaMaximo)
        .clamp(1, 10),
    aciertosParaSubir: AjustesContar.aciertosParaSubir,
    erroresParaBajar: AjustesContar.erroresParaBajar,
  );

  static const Cosa _cosaPorDefecto =
      Cosa(dibujo: '🍎', una: 'manzana', varias: 'manzanas', femenino: true);

  /// La cosa que salta cuando la cuentan.
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// El botón equivocado se mueve de lado a lado.
  late final AnimationController _temblor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// Para que las cosas se balanceen y el botón de ayuda brille.
  late final AnimationController _vaiven = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  Cosa _cosa = _cosaPorDefecto;
  int _cantidad = 0;

  /// El número que le tocó a cada cosa al contarla (null = sin contar).
  List<int?> _numeros = <int?>[];
  int _contadas = 0;

  /// Para que cada cosa quede un poquito corrida y girada (no en fila).
  List<Offset> _corridas = <Offset>[];
  List<double> _giros = <double>[];

  List<int> _opciones = <int>[];
  _Fase _fase = _Fase.contando;
  int _errores = 0;
  int? _saltando;
  int? _tembloroso;
  bool _contandoJuntas = false;
  int _estrellas = 0;
  int _ronda = 0;
  bool _celebrando = false;
  Cosa? _cosaAnterior;
  int _cantidadAnterior = 0;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    Sonidos.preparar(<String>[
      for (var n = 1; n <= _dificultad.maximo; n++) _sonidoNota(n),
      AjustesContar.sonidoError,
      Sonidos.aciertoArchivo,
    ]);
    _nuevaRonda();
  }

  @override
  void dispose() {
    _salto.dispose();
    _temblor.dispose();
    _vaiven.dispose();
    super.dispose();
  }

  String _sonidoNota(int n) =>
      AjustesContar.sonidoContar.replaceAll('{n}', '${n.clamp(1, 10)}');

  String _numero(int n) {
    final numeros = AjustesContar.numeros;
    return n >= 1 && n <= numeros.length ? numeros[n - 1] : '$n';
  }

  /// Arma una frase con el nombre de la cosa ("las manzanas", "¿Cuántos
  /// pollitos hay?"...). Con una sola cosa dice "una manzana", "un pez".
  String _frase(String texto, {int? numero, int? otro}) {
    final f = _cosa.femenino;
    final unaSola = numero == 1;
    return texto
        .replaceAll('{cosas}', unaSola ? _cosa.una : _cosa.varias)
        .replaceAll('{las}', f ? 'las' : 'los')
        .replaceAll('{una}', f ? 'una' : 'uno')
        .replaceAll('{Cuantas}', f ? 'Cuántas' : 'Cuántos')
        .replaceAll(
            '{numero}',
            numero == null
                ? ''
                : (unaSola ? (f ? 'una' : 'un') : _numero(numero)))
        .replaceAll('{otro}', otro == null ? '' : _numero(otro));
  }

  // ------------------------------------------------------- 1. cada ronda

  void _nuevaRonda() {
    final cosas = AjustesContar.cosas.isEmpty
        ? const <Cosa>[_cosaPorDefecto]
        : AjustesContar.cosas;
    // Otra cosa y otra cantidad que la ronda anterior.
    var cosa = cosas[_azar.nextInt(cosas.length)];
    if (cosas.length > 1 && cosa == _cosaAnterior) {
      cosa = cosas[(cosas.indexOf(cosa) + 1) % cosas.length];
    }
    final hasta = _dificultad.opciones;
    var cantidad = 1 + _azar.nextInt(hasta);
    if (hasta > 1 && cantidad == _cantidadAnterior) {
      cantidad = cantidad % hasta + 1;
    }
    _cosaAnterior = cosa;
    _cantidadAnterior = cantidad;

    // Los botones: el número correcto y otros cercanos, en orden.
    final botones = AjustesContar.botones.clamp(2, 5);
    final todos = <int>[
      for (var n = 1; n <= math.max(hasta, botones); n++)
        if (n != cantidad) n,
    ]..shuffle(_azar);
    final opciones = <int>[cantidad, ...todos.take(botones - 1)]..sort();

    setState(() {
      _cosa = cosa;
      _cantidad = cantidad;
      _numeros = List<int?>.filled(cantidad, null);
      _contadas = 0;
      _corridas = <Offset>[
        for (var i = 0; i < cantidad; i++)
          Offset(_azar.nextDouble() * 2 - 1, _azar.nextDouble() * 2 - 1),
      ];
      _giros = <double>[
        for (var i = 0; i < cantidad; i++) (_azar.nextDouble() * 2 - 1) * 0.2,
      ];
      _opciones = opciones;
      _fase = _Fase.contando;
      _errores = 0;
      _saltando = null;
      _tembloroso = null;
      _contandoJuntas = false;
      _ronda++;
    });
    Voz.decir(_frase(AjustesContar.vozCuenta));
  }

  /// La orejita: repite lo que hay que hacer ahora.
  void _repetir() {
    if (_contandoJuntas) return;
    switch (_fase) {
      case _Fase.contando:
        Voz.decir(_frase(AjustesContar.vozCuenta));
      case _Fase.preguntando:
        Voz.decir(_frase(AjustesContar.vozPregunta));
      case _Fase.acerto:
        break;
    }
  }

  // ------------------------------------------------------ 2. contar

  /// Le pone su número a la cosa [i]: salta, suena la notita y la voz dice
  /// el número.
  Future<void> _contar(int i) {
    final n = _contadas + 1;
    setState(() {
      _numeros[i] = n;
      _contadas = n;
      _saltando = i;
    });
    _salto.forward(from: 0);
    Sonidos.tocar(_sonidoNota(n));
    return Voz.decir(_numero(n), grabaciones: <String>[_numero(n)]);
  }

  void _alTocarCosa(int i) {
    if (_celebrando || _contandoJuntas || _fase != _Fase.contando) return;
    if (_numeros[i] != null) return; // ya la contó
    _contar(i);
    if (_contadas == _cantidad) {
      final ronda = _ronda;
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted && ronda == _ronda && !_contandoJuntas) _preguntar();
      });
    }
  }

  void _preguntar() {
    setState(() => _fase = _Fase.preguntando);
    Voz.decir(_frase(AjustesContar.vozPregunta));
  }

  /// Después de equivocarse: la voz cuenta con ella cada cosa, en orden, y
  /// vuelve a preguntar.
  Future<void> _contarJuntas() async {
    final ronda = _ronda;
    setState(() {
      _contandoJuntas = true;
      _fase = _Fase.contando;
      _numeros = List<int?>.filled(_cantidad, null);
      _contadas = 0;
    });
    // Un orden cómodo: de arriba hacia abajo y de izquierda a derecha (el
    // mismo en que están repartidas).
    for (var i = 0; i < _cantidad; i++) {
      if (!mounted || ronda != _ronda) return;
      await Future.wait(<Future<void>>[
        _contar(i),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || ronda != _ronda) return;
    setState(() => _contandoJuntas = false);
    _preguntar();
  }

  // --------------------------------------------------- 3. responder

  void _alResponder(int numero) {
    if (_celebrando || _contandoJuntas || _fase != _Fase.preguntando) return;
    if (numero == _cantidad) {
      _acerto();
    } else {
      _seEquivoco(numero);
    }
  }

  Future<void> _acerto() async {
    setState(() {
      _fase = _Fase.acerto;
      _estrellas++;
    });
    Sonidos.acierto();
    _dificultad.terminoRonda(_errores);
    final frases = AjustesContar.vozAcierto;
    await Future.wait(<Future<void>>[
      if (frases.isNotEmpty)
        Voz.decir(
            _frase(frases[_azar.nextInt(frases.length)], numero: _cantidad)),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    await Future<void>.delayed(
        const Duration(milliseconds: AjustesContar.pausaSiguienteRonda));
    if (!mounted) return;
    if (AjustesContar.aciertosParaCelebrar > 0 &&
        _estrellas % AjustesContar.aciertosParaCelebrar == 0) {
      _celebrar();
    } else {
      _nuevaRonda();
    }
  }

  Future<void> _seEquivoco(int numero) async {
    final ronda = _ronda;
    setState(() {
      _errores++;
      _tembloroso = numero;
      _contandoJuntas = true; // mientras habla no se puede tocar
    });
    _temblor.forward(from: 0);
    Sonidos.tocar(AjustesContar.sonidoError);
    await Voz.decir(_frase(AjustesContar.vozError, otro: numero));
    if (!mounted || ronda != _ronda) return;
    await _contarJuntas();
  }

  void _celebrar() {
    setState(() => _celebrando = true);
    Sonidos.felicidades();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _celebrando) Voz.decir(AjustesContar.vozCelebracion);
    });
  }

  void _terminoCelebracion() {
    if (!mounted) return;
    setState(() => _celebrando = false);
    _nuevaRonda();
  }

  // ------------------------------------------------------ 4. cómo se ve

  static const List<Color> _coloresNumeros = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
    Color(0xFF00ACC1),
    Color(0xFF7CB342),
    Color(0xFFF4511E),
    Color(0xFF5E35B1),
  ];

  Color _colorNumero(int n) =>
      _coloresNumeros[(n - 1) % _coloresNumeros.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Un pasto con cielo.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFFFF8E1),
                    Color(0xFFF1F8E9),
                    Color(0xFFDCEDC8),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BarraJuego(estrellas: _estrellas, alRepetir: _repetir),
                SizedBox(height: 64, child: _contador()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: LayoutBuilder(
                      builder: (context, caja) => _lasCosas(caja.biggest),
                    ),
                  ),
                ),
                SizedBox(height: 150, child: _botones()),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                linea1: AjustesContar.celebracionLinea1,
                linea2: AjustesContar.celebracionLinea2,
                alTerminar: _terminoCelebracion,
              ),
            ),
        ],
      ),
    );
  }

  /// El número grande de arriba: cuántas lleva contadas.
  Widget _contador() {
    if (_contadas == 0) return const SizedBox.shrink();
    return Center(
      child: AnimatedBuilder(
        animation: _salto,
        builder: (context, hijo) {
          final t = _salto.value;
          final escala = 1 + 0.35 * math.sin(math.pi * t);
          return Transform.scale(scale: escala, child: hijo);
        },
        child: Text(
          '$_contadas',
          key: const ValueKey<String>('contador'),
          style: TextStyle(
            fontSize: 52,
            height: 1,
            fontWeight: FontWeight.w900,
            color: _colorNumero(_contadas),
            shadows: const <Shadow>[
              Shadow(color: Colors.white, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lasCosas(Size tam) {
    final lugares = repartir(tam, _cantidad, relleno: 0.78);
    final hijos = <Widget>[];
    for (var i = 0; i < _cantidad && i < lugares.length; i++) {
      var lugar = lugares[i];
      // Un poquito corrida (sin salirse).
      final libre = (lugar.width / 0.78 - lugar.width) / 2;
      lugar = lugar.shift(_corridas[i] * libre * 0.9);
      hijos.add(Positioned.fromRect(rect: lugar, child: _unaCosa(i)));
    }
    return Stack(clipBehavior: Clip.none, children: hijos);
  }

  Widget _unaCosa(int i) {
    final numero = _numeros[i];
    return GestureDetector(
      key: ValueKey<String>('cosa_$i'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _alTocarCosa(i),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_salto, _vaiven]),
        builder: (context, _) {
          var subir = 0.0;
          var escala = 1.0;
          if (_saltando == i) {
            final t = _salto.value;
            subir = -math.sin(math.pi * t) * 28;
            escala = 1 + 0.18 * math.sin(math.pi * t);
          }
          final balanceo = _giros[i] +
              math.sin(_vaiven.value * 2 * math.pi + i * 1.3) * 0.05;
          return Transform.translate(
            offset: Offset(0, subir),
            child: Transform.scale(
              scale: escala,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Las que ya contó quedan con un círculo de color atrás.
                  if (numero != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorNumero(numero).withValues(alpha: 0.16),
                          border: Border.all(
                            color: _colorNumero(numero).withValues(alpha: 0.6),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Transform.rotate(
                        angle: balanceo,
                        child: FittedBox(
                          child: Text(
                            _cosa.dibujo,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (numero != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: _globito(numero, key: 'numero_$i'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// El número que le queda puesto a cada cosa contada.
  Widget _globito(int n, {required String key}) {
    return Container(
      key: ValueKey<String>(key),
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _colorNumero(n),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        '$n',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  /// Los botones con números (salen cuando ya contó todas).
  Widget _botones() {
    final visibles = _fase != _Fase.contando;
    return AnimatedOpacity(
      opacity: visibles ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !visibles,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final n in _opciones)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _boton(n),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boton(int n) {
    final correcto = n == _cantidad;
    final conAyuda = correcto &&
        _fase == _Fase.preguntando &&
        _errores >= AjustesContar.erroresParaAyuda;
    final acertado = correcto && _fase == _Fase.acerto;
    final color = _colorNumero(n);
    return GestureDetector(
      key: ValueKey<String>('respuesta_$n'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _alResponder(n),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_temblor, _vaiven]),
        builder: (context, _) {
          var giro = 0.0;
          if (_tembloroso == n) {
            final t = _temblor.value;
            giro = math.sin(t * math.pi * 6) * 0.2 * (1 - t);
          }
          final brillo = conAyuda
              ? 0.5 + 0.5 * math.sin(_vaiven.value * 2 * math.pi * 3)
              : 0.0;
          return Transform.rotate(
            angle: giro,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: acertado ? color : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: color, width: 5),
                      boxShadow: <BoxShadow>[
                        const BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3)),
                        if (brillo > 0)
                          BoxShadow(
                            color: const Color(0xFFFFD600)
                                .withValues(alpha: 0.4 + 0.6 * brillo),
                            blurRadius: 10 + 18 * brillo,
                            spreadRadius: 2 + 6 * brillo,
                          ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: Text(
                              '$n',
                              style: TextStyle(
                                fontSize: 80,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: acertado ? Colors.white : color,
                              ),
                            ),
                          ),
                        ),
                        _puntitos(n, acertado ? Colors.white : color),
                      ],
                    ),
                  ),
                ),
                if (acertado)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.6,
                      child: Estrellitas(
                          key: ValueKey<String>('estrellitas_$_ronda')),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Puntitos debajo del número (tantos como el número), para que pueda
  /// contarlos aunque todavía no conozca los números.
  Widget _puntitos(int n, Color color) {
    final filas = n <= 5 ? 1 : 2;
    final porFila = (n / filas).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var f = 0; f < filas; f++)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = f * porFila;
                    k < math.min(n, (f + 1) * porFila);
                    k++)
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
