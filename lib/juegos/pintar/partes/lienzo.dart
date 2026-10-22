import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:colorear_ninos/juegos/pintar/partes/sonidos_pintar.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';

final Paint _suave = Paint()..filterQuality = FilterQuality.medium;

void _dibujarImagen(Canvas canvas, ui.Image imagen, Rect destino) {
  canvas.drawImageRect(
    imagen,
    Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
    destino,
    _suave,
  );
}

/// Miniatura de un dibujo para el menú: papel blanco, lo pintado y las líneas.
/// Se redibuja sola cuando cambia lo pintado ([Pintura.cambios]).
class MiniaturaPainter extends CustomPainter {
  MiniaturaPainter(this.dibujo) : super(repaint: Pintura.cambios);

  final Dibujo dibujo;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(todo, Paint()..color = Colors.white);
    final pintado = Pintura.miniatura(dibujo.id);
    if (pintado != null) _dibujarImagen(canvas, pintado, todo);
    final lineas = Pintura.lineasMiniatura(dibujo);
    if (lineas != null) _dibujarImagen(canvas, lineas, todo);
  }

  @override
  bool shouldRepaint(covariant MiniaturaPainter oldDelegate) =>
      oldDelegate.dibujo != dibujo;
}

/// Una mancha que se está pintando ahora (todavía no horneada).
class _Activo {
  _Activo(this.trazo, this.nacio);

  final Trazo trazo;
  final int nacio; // milisegundos
}

class _PintorLienzo extends CustomPainter {
  _PintorLienzo({
    required this.dibujo,
    required this.activos,
    required this.avances,
    required this.lineas,
  }) : super(repaint: Pintura.cambios);

  final Dibujo dibujo;
  final List<Trazo> activos;
  final List<double> avances;
  final ui.Image? lineas;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(todo, Paint()..color = Colors.white);
    // Se lee aquí (no antes) porque la imagen se reemplaza de vez en cuando.
    final base = Pintura.completa(dibujo.id);
    if (base != null) _dibujarImagen(canvas, base, todo);
    if (activos.isNotEmpty) {
      final escala = size.width / dibujo.lado;
      canvas.save();
      canvas.scale(escala, escala);
      for (var k = 0; k < activos.length; k++) {
        Dibujante.trazo(canvas, dibujo, activos[k], avances[k]);
      }
      canvas.restore();
    }
    final lineasActuales = lineas;
    if (lineasActuales != null) _dibujarImagen(canvas, lineasActuales, todo);
  }

  @override
  bool shouldRepaint(covariant _PintorLienzo oldDelegate) => true;
}

/// El lienzo donde se pinta con el dedo.
///
/// Cómo funciona:
///  - Cada toque deja una mancha de color que se "derrama" desde el dedo,
///    con el sonido de una gota de pintura. El tamaño de la mancha depende
///    del tamaño de la zona: las zonas grandes necesitan varios toques y las
///    pequeñas se llenan de un solo toque (ver Ajustes).
///  - Si el dedo se arrastra, la pintura lo sigue (con sonido de pincel).
///  - La pintura queda "pegada" a la zona donde empezó el dedo y se recorta a
///    su forma, así que aunque el dedo se salga de las líneas el color no se sale.
///  - Antes de pintar en una zona pregunta si se puede ([puedePintar]): así
///    la pantalla decide (por ejemplo, en el Modo 2 el color del personaje no
///    pinta el fondo).
///  - Cuando una mancha termina, se "hornea" dentro de la imagen del dibujo;
///    por eso pintar cuesta siempre lo mismo, aunque se pinte muchísimo.
///  - Mientras se pinta, mide cada tanto cuánto del dibujo cubre cada color
///    de la paleta y cuánto está pintado ([alMedir]).
class Lienzo extends StatefulWidget {
  const Lienzo({
    super.key,
    required this.dibujo,
    required this.color,
    this.colores = const <Color>[],
    this.puedePintar,
    this.personaje = const <int>{},
    this.alMedir,
  });

  final Dibujo dibujo;

  /// El color elegido (transparente = ninguno).
  final Color color;

  /// Los colores de la paleta del dibujo (los que se miden).
  final List<Color> colores;

  /// Se pregunta al empezar a pintar en una zona (su número).
  /// false = no se pinta (por ejemplo, no hay color elegido).
  final bool Function(int zona)? puedePintar;

  /// Las zonas del personaje del dibujo, para medir cuánto de él está
  /// pintado (vacío = no se mide).
  final Set<int> personaje;

  /// Recibe cuánto del dibujo cubre cada uno de [colores] (0 a 1), cuánto
  /// está pintado en total y cuánto del personaje.
  final ValueChanged<Medida>? alMedir;

  @override
  State<Lienzo> createState() => _EstadoLienzo();
}

class _EstadoLienzo extends State<Lienzo>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final int _version;
  final Stopwatch _reloj = Stopwatch()..start();
  final math.Random _azar = math.Random();
  final List<_Activo> _activos = <_Activo>[];

  bool _listo = false; // ya se cargó lo pintado antes
  ui.Image? _lineas;
  int _pxLineas = 0;

  int? _puntero; // el dedo que está pintando (se ignoran los demás)
  Trazo? _trazo; // la mancha que se está pintando ahora
  double _recorrido =
      0; // distancia arrastrada desde el último sonido de pincel
  bool _detenido = false; // esta pasada del dedo ya no pinta

  // Medición de cuánto cubre cada color.
  static const int _msEntreMediciones = 250;
  bool _midiendo = false;
  bool _otraMedicion = false;
  Timer? _esperaMedicion;
  int _ultimaMedicion = -100000;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_alTick);
    _version = Pintura.version(widget.dibujo.id);
    WidgetsBinding.instance.addObserver(this);
    _abrir();
    // Se calcula de una vez el tamaño de cada zona, justo después de mostrar
    // el dibujo, para que el primer toque no tenga que esperar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // (Los dibujos hechos desde imagen lo calculan al tocar cada zona.)
      if (!mounted || !widget.dibujo.capas) return;
      for (var i = 0; i < widget.dibujo.regiones.length; i++) {
        widget.dibujo.areaVisible(i);
      }
    });
  }

  Future<void> _abrir() async {
    await Pintura.abrir(widget.dibujo);
    if (!mounted) return;
    setState(() => _listo = true);
    // Se mide lo que ya estaba pintado, para que la pantalla quede al día.
    _pedirMedicion();
  }

  /// Pide una medición. Se hacen de a una, y como mucho cada
  /// [_msEntreMediciones] milisegundos.
  void _pedirMedicion() {
    if (widget.alMedir == null || widget.colores.isEmpty || !mounted) return;
    if (_midiendo) {
      _otraMedicion = true;
      return;
    }
    if (_esperaMedicion != null) return;
    final espera =
        _msEntreMediciones - (_reloj.elapsedMilliseconds - _ultimaMedicion);
    if (espera > 0) {
      _esperaMedicion = Timer(Duration(milliseconds: espera), () {
        _esperaMedicion = null;
        _pedirMedicion();
      });
      return;
    }
    _medir();
  }

  Future<void> _medir() async {
    _midiendo = true;
    _ultimaMedicion = _reloj.elapsedMilliseconds;
    Medida? medida;
    try {
      medida = await Pintura.medirColores(
        widget.dibujo,
        <Trazo>[for (final a in _activos) a.trazo],
        widget.colores,
        personaje: widget.personaje,
      );
    } finally {
      _midiendo = false;
    }
    if (!mounted) return;
    // Si mientras se medía se borró el dibujo, esta medida ya no vale.
    if (Pintura.version(widget.dibujo.id) != _version) return;
    if (medida != null) widget.alMedir?.call(medida);
    if (_otraMedicion) {
      _otraMedicion = false;
      _pedirMedicion();
    }
  }

  /// Hornea ya mismo todo lo que se estaba pintando.
  void _hornearTodo() {
    final pendientes = _activos.map((a) => a.trazo).toList();
    _activos.clear();
    _trazo = null;
    _puntero = null;
    Pintura.hornear(widget.dibujo, pendientes, _version);
  }

  /// Si la app se va a segundo plano, se hornea y se guarda lo que haya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // "inactive" (bajar la barra de notificaciones, un aviso del sistema)
    // no interrumpe la pintura; solo cuando la app se oculta de verdad.
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      return;
    }
    if (_activos.isNotEmpty) {
      _hornearTodo();
      if (mounted) setState(() {});
    }
    Pintura.guardarPendientes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _esperaMedicion?.cancel();
    _esperaMedicion = null;
    _ticker.dispose();
    // Lo que se estaba pintando se guarda igual.
    _hornearTodo();
    Pintura.cerrar(widget.dibujo);
    _lineas?.dispose();
    _lineas = null;
    super.dispose();
  }

  void _alTick(Duration _) {
    final ahora = _reloj.elapsedMilliseconds;
    // Las manchas que ya terminaron de derramarse (y no se están arrastrando)
    // se hornean en la imagen, en orden.
    var listas = 0;
    while (listas < _activos.length) {
      final a = _activos[listas];
      final termino = ahora - a.nacio >= AjustesPintar.duracionDerrame &&
          !identical(a.trazo, _trazo);
      if (!termino) break;
      listas++;
    }
    if (listas > 0) {
      final horneadas =
          _activos.sublist(0, listas).map((a) => a.trazo).toList();
      _activos.removeRange(0, listas);
      Pintura.hornear(widget.dibujo, horneadas, _version);
    }
    if (_activos.isEmpty) _ticker.stop();
    setState(() {});
  }

  int? _regionEn(Offset p) {
    final regiones = widget.dibujo.regiones;
    for (var i = regiones.length - 1; i >= 0; i--) {
      if (regiones[i].path.contains(p)) return i;
    }
    return null;
  }

  /// Tamaño de la mancha para una zona con este área visible.
  double _radioPara(double area) {
    final t = ((math.log(area) - math.log(AjustesPintar.areaUnToque)) /
            (math.log(AjustesPintar.areaZonaGrande) -
                math.log(AjustesPintar.areaUnToque)))
        .clamp(0.0, 1.0);
    final toques = AjustesPintar.toquesZonaChica +
        (AjustesPintar.toquesZonaGrande - AjustesPintar.toquesZonaChica) * t;
    // El 2 compensa que los toques siempre se enciman un poco.
    final radio =
        math.sqrt(2 * area / (math.pi * toques)) * AjustesPintar.escalaMancha;
    return radio
        .clamp(AjustesPintar.radioMinimo, AjustesPintar.radioMaximo)
        .toDouble();
  }

  void _empezar(Offset p, int i) {
    final dibujo = widget.dibujo;
    final area = dibujo.areaVisible(i);
    final Trazo trazo;
    if (area < AjustesPintar.areaUnToque) {
      // Zona pequeña: un círculo que la cubre entera.
      final caja = dibujo.limites(i);
      var radio = 0.0;
      for (final esquina in <Offset>[
        caja.topLeft,
        caja.topRight,
        caja.bottomLeft,
        caja.bottomRight,
      ]) {
        radio = math.max(radio, (esquina - p).distance);
      }
      trazo = Trazo(
        region: i,
        color: widget.color,
        radio: radio + 4,
        semilla: 0,
        inicio: p,
      );
    } else {
      trazo = Trazo(
        region: i,
        color: widget.color,
        radio: _radioPara(area),
        semilla: 1 + _azar.nextInt(1 << 30),
        inicio: p,
      );
    }
    _trazo = trazo;
    _recorrido = 0;
    _activos.add(_Activo(trazo, _reloj.elapsedMilliseconds));
    if (!_ticker.isActive) _ticker.start();
    SonidosPintar.gota();
    _pedirMedicion();
  }

  Offset _aDibujo(Offset local, double lado) =>
      local * (widget.dibujo.lado / lado);

  bool _puedePintar(int zona) => widget.puedePintar?.call(zona) ?? true;

  void _alBajar(PointerDownEvent e, double lado) {
    if (_puntero != null || !_listo) return;
    _puntero = e.pointer;
    _trazo = null;
    _detenido = false;
    final p = _aDibujo(e.localPosition, lado);
    final i = _regionEn(p);
    if (i == null) return;
    if (!_puedePintar(i)) {
      _detenido = true;
      return;
    }
    setState(() => _empezar(p, i));
  }

  void _alMover(PointerMoveEvent e, double lado) {
    if (e.pointer != _puntero || _detenido) return;
    final p = _aDibujo(e.localPosition, lado);
    final trazo = _trazo;
    if (trazo == null) {
      // Empezó fuera del dibujo: se pega a la primera zona que toque.
      final i = _regionEn(p);
      if (i == null) return;
      if (!_puedePintar(i)) {
        _detenido = true;
        return;
      }
      setState(() => _empezar(p, i));
      return;
    }
    if (trazo.color != widget.color) {
      // Se soltó o se cambió el color: esta pasada termina aquí.
      _detenido = true;
      _trazo = null;
      if (_activos.isNotEmpty && !_ticker.isActive) _ticker.start();
      return;
    }
    final paso = (p - trazo.puntos.last).distance;
    if (paso < 6) return; // movimiento muy chiquito: se ignora
    trazo.sumar(p);
    _recorrido += paso;
    if (_recorrido >= AjustesPintar.distanciaEntreTrazos) {
      _recorrido = 0;
      SonidosPintar.trazo();
    }
    _pedirMedicion();
    setState(() {});
  }

  void _alSoltar(PointerEvent e) {
    if (e.pointer != _puntero) return;
    _puntero = null;
    _trazo = null;
    _detenido = false;
    // Para que la mancha se hornee aunque ya haya terminado de derramarse.
    if (_activos.isNotEmpty && !_ticker.isActive) _ticker.start();
  }

  void _asegurarLineas(int px) {
    if (_pxLineas == px) return;
    _pxLineas = px;
    if (widget.dibujo.lineasPng != null) {
      _leerLineasDeImagen(px); // dibujo hecho desde una imagen
      return;
    }
    _lineas?.dispose();
    _lineas = Dibujante.lineas(widget.dibujo, px);
  }

  Future<void> _leerLineasDeImagen(int px) async {
    final imagen = await Pintura.lineasDeImagen(widget.dibujo, px);
    if (imagen == null) {
      // No se pudo leer: se vuelven a hacer las líneas desde las zonas.
      if (mounted) setState(() => _pxLineas = 0);
      return;
    }
    if (!mounted || _pxLineas != px) {
      imagen.dispose();
      return;
    }
    final vieja = _lineas;
    setState(() => _lineas = imagen);
    vieja?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final densidad = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, restricciones) {
        final lado = math.min(restricciones.maxWidth, restricciones.maxHeight);
        _asegurarLineas((lado * densidad).round().clamp(200, 2048).toInt());
        final ahora = _reloj.elapsedMilliseconds;
        final avances = <double>[
          for (final a in _activos)
            ((ahora - a.nacio) / AjustesPintar.duracionDerrame)
                .clamp(0.0, 1.0)
                .toDouble(),
        ];
        return Center(
          child: SizedBox(
            width: lado,
            height: lado,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _alBajar(e, lado),
              onPointerMove: (e) => _alMover(e, lado),
              onPointerUp: _alSoltar,
              onPointerCancel: _alSoltar,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(lado, lado),
                  painter: _PintorLienzo(
                    dibujo: widget.dibujo,
                    activos: <Trazo>[for (final a in _activos) a.trazo],
                    avances: avances,
                    lineas: _lineas,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
