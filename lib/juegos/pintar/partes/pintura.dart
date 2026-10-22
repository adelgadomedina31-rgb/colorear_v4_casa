import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:path_provider/path_provider.dart';

import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';

/// Una mancha de pintura. Al tocar queda una mancha que se "derrama" desde el
/// dedo; si el dedo se arrastra, una franja sigue al dedo.
///
/// Las manchas solo existen como formas mientras se están pintando. Cuando
/// terminan, se "hornean" dentro de la imagen del dibujo (ver [Pintura]), así
/// la app no se pone lenta aunque se pinte muchísimo.
class Trazo {
  Trazo({
    required this.region,
    required this.color,
    required this.radio,
    required this.semilla,
    required Offset inicio,
  }) : puntos = <Offset>[inicio];

  Trazo._(this.region, this.color, this.radio, this.semilla, this.puntos);

  /// Índice de la zona del dibujo donde se pinta.
  final int region;

  final Color color;

  /// Tamaño de la mancha (en unidades del dibujo).
  final double radio;

  /// Forma de la mancha. 0 = círculo perfecto (se usa cuando la mancha llena
  /// toda la zona de un toque); otro número = una mancha con bordes ondulados.
  final int semilla;

  /// Dónde tocó el dedo (el primero) y por dónde se arrastró (los demás).
  final List<Offset> puntos;

  Path? _mancha;
  Path? _franja;

  Offset get centro => puntos.first;

  double get anchoFranja => radio * AjustesPintar.anchoArrastre;

  /// La forma final de la mancha (ya derramada).
  Path get mancha => _mancha ??= formaMancha(puntos.first, radio, semilla, 1.0);

  /// El camino del arrastre, o null si fue solo un toque.
  Path? get franja {
    if (puntos.length < 2) return null;
    final existente = _franja;
    if (existente != null) return existente;
    final nueva = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var i = 1; i < puntos.length; i++) {
      nueva.lineTo(puntos[i].dx, puntos[i].dy);
    }
    _franja = nueva;
    return nueva;
  }

  /// Agrega un punto del arrastre (si se alejó lo suficiente del anterior).
  /// Devuelve true si se agregó.
  bool sumar(Offset punto) {
    if ((punto - puntos.last).distance < 6) return false;
    puntos.add(punto);
    _franja?.lineTo(punto.dx, punto.dy);
    return true;
  }

  /// Rectángulo que contiene toda la pintura de este trazo.
  Rect limites() {
    var caja = Rect.fromCircle(
      center: puntos.first,
      radius: radio * (semilla == 0 ? 1.02 : 1.45),
    );
    final camino = franja;
    if (camino != null) {
      caja =
          caja.expandToInclude(camino.getBounds().inflate(anchoFranja / 2 + 2));
    }
    return caja;
  }

  /// Forma de una mancha mientras se "derrama".
  /// [avance] va de 0 (recién tocada) a 1 (tamaño final): la mancha crece
  /// desde el dedo, con el borde ondulándose como pintura líquida, y al final
  /// aparecen unas gotitas salpicadas alrededor.
  static Path formaMancha(Offset c, double r, int semilla, double avance) {
    final t = avance.clamp(0.0, 1.0).toDouble();
    // Crece rápido al principio y se frena al final (como un líquido).
    final crecido = 1 - math.pow(1 - t, 3).toDouble();
    final escala = 0.15 + 0.85 * crecido;
    if (semilla == 0) {
      return Path()..addOval(Rect.fromCircle(center: c, radius: r * escala));
    }
    final azar = math.Random(semilla);
    final f1 = azar.nextDouble() * 2 * math.pi;
    final f2 = azar.nextDouble() * 2 * math.pi;
    final f3 = azar.nextDouble() * 2 * math.pi;
    // Mientras se derrama, el borde se mueve y ondula más.
    final ondas = 1.0 + 0.9 * (1 - t);
    final giro = 1.4 * (1 - t);
    final rr0 = r * escala;
    const lados = 48;
    final forma = Path();
    for (var i = 0; i < lados; i++) {
      final a = i * 2 * math.pi / lados;
      final rr = rr0 *
          (0.92 +
              ondas *
                  (0.06 * math.sin(3 * a + f1 + giro) +
                      0.04 * math.sin(5 * a + f2 - giro) +
                      0.03 * math.sin(7 * a + f3 + 2 * giro)));
      final x = c.dx + rr * math.cos(a);
      final y = c.dy + rr * math.sin(a);
      if (i == 0) {
        forma.moveTo(x, y);
      } else {
        forma.lineTo(x, y);
      }
    }
    forma.close();
    // Gotitas salpicadas (aparecen en la segunda mitad del derrame).
    final gotas = 3 + azar.nextInt(3);
    final aparicion = ((t - 0.45) / 0.55).clamp(0.0, 1.0).toDouble();
    for (var g = 0; g < gotas; g++) {
      final a = azar.nextDouble() * 2 * math.pi;
      final distancia = r * (1.02 + azar.nextDouble() * 0.2);
      final tamano = r * (0.06 + azar.nextDouble() * 0.07);
      if (aparicion <= 0) continue;
      final centro = Offset(
        c.dx + distancia * escala * math.cos(a),
        c.dy + distancia * escala * math.sin(a),
      );
      forma
          .addOval(Rect.fromCircle(center: centro, radius: tamano * aparicion));
    }
    return forma;
  }

  /// Lee un trazo guardado por las versiones 3 y 4 de la app (se usa solo
  /// para pasar lo pintado al formato nuevo). Devuelve null si no sirve.
  static Trazo? desdeJson(Object? datos, int region) {
    if (datos is! Map) return null;
    final c = datos['c'];
    final r = datos['r'];
    final s = datos['s'];
    final p = datos['p'];
    if (c is! int || r is! num || s is! int || p is! List || p.length < 2) {
      return null;
    }
    final puntos = <Offset>[];
    for (var i = 0; i + 1 < p.length; i += 2) {
      final x = p[i];
      final y = p[i + 1];
      if (x is! num || y is! num) return null;
      puntos.add(Offset(x.toDouble(), y.toDouble()));
    }
    return Trazo._(region, Color(c), r.toDouble(), s, puntos);
  }
}

/// Funciones de dibujo que comparten el lienzo, las miniaturas y el guardado.
class Dibujante {
  Dibujante._();

  static final Paint _capa = Paint();
  static final Paint _borrar = Paint()..blendMode = BlendMode.dstOut;
  static final Paint _suave = Paint()..filterQuality = FilterQuality.medium;

  /// Dibuja la mancha [t] (con su [avance]) solo en la parte visible de su
  /// zona: se recorta a la zona y se borra lo que tapan las zonas de encima.
  /// El canvas debe estar en unidades del dibujo.
  static void trazo(Canvas canvas, Dibujo d, Trazo t, double avance) {
    final i = t.region;
    if (i < 0 || i >= d.regiones.length) return;
    final caja = t.limites();
    canvas.saveLayer(caja, _capa);
    canvas.save();
    canvas.clipPath(d.regiones[i].path);
    final relleno = Paint()
      ..color = t.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      avance >= 1.0
          ? t.mancha
          : Trazo.formaMancha(t.centro, t.radio, t.semilla, avance),
      relleno,
    );
    final camino = t.franja;
    if (camino != null) {
      canvas.drawPath(
        camino,
        Paint()
          ..color = t.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.anchoFranja
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
    for (var j = i + 1; d.capas && j < d.regiones.length; j++) {
      if (d.limites(j).overlaps(caja)) {
        canvas.drawPath(d.regiones[j].path, _borrar);
      }
    }
    canvas.restore();
  }

  /// Imagen con solo las líneas negras del dibujo (las que se ven) y los
  /// adornos; el resto es transparente. Se pone encima de la pintura.
  static Image lineas(Dibujo d, int px) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    final escala = px / d.lado;
    canvas.scale(escala, escala);
    canvas.saveLayer(Rect.fromLTWH(0, 0, d.lado, d.lado), Paint());
    final limpiar = Paint()..blendMode = BlendMode.clear;
    final contorno = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AjustesPintar.grosorContorno
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final region in d.regiones) {
      // Cada zona tapa las líneas de las zonas que tiene debajo.
      canvas.drawPath(region.path, limpiar);
      canvas.drawPath(region.path, contorno);
    }
    canvas.restore();
    final detalleRelleno = Paint()..style = PaintingStyle.fill;
    final detalleLinea = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final detalle in d.detalles) {
      final color = detalle.relleno;
      if (color != null) {
        detalleRelleno.color = color;
        canvas.drawPath(detalle.path, detalleRelleno);
      }
      if (detalle.grosor > 0) {
        detalleLinea.strokeWidth = detalle.grosor;
        canvas.drawPath(detalle.path, detalleLinea);
      }
    }
    return _aImagen(grabadora, px);
  }

  /// Nueva imagen de pintura: la [base] (si hay) más estos [trazos].
  static Image hornear(Image? base, Dibujo d, List<Trazo> trazos, int px) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    if (base != null) {
      canvas.drawImageRect(base, _rect(base), _cuadro(px), _suave);
    }
    final escala = px / d.lado;
    canvas.scale(escala, escala);
    for (final t in trazos) {
      trazo(canvas, d, t, 1.0);
    }
    return _aImagen(grabadora, px);
  }

  /// Nueva imagen de pintura: estos [trazos] por DEBAJO y la [base] encima.
  /// Sirve para rellenar los puntitos que quedaron sin pintar sin tapar
  /// nada de lo que ya estaba pintado.
  static Image rellenarDebajo(Image base, Dibujo d, List<Trazo> trazos, int px) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    final escala = px / d.lado;
    canvas.save();
    canvas.scale(escala, escala);
    for (final t in trazos) {
      trazo(canvas, d, t, 1.0);
    }
    canvas.restore();
    canvas.drawImageRect(base, _rect(base), _cuadro(px), _suave);
    return _aImagen(grabadora, px);
  }

  /// Copia "plana" de una imagen, del tamaño pedido. Se hace de verdad
  /// (no queda enlazada a la imagen original), así la original se puede
  /// soltar de la memoria.
  static Future<Image> copiaPlana(Image imagen, int px) async {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    canvas.drawImageRect(imagen, _rect(imagen), _cuadro(px), _suave);
    final foto = grabadora.endRecording();
    try {
      return await foto.toImage(px, px);
    } finally {
      foto.dispose();
    }
  }

  static Rect _rect(Image i) =>
      Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());

  static Rect _cuadro(int px) =>
      Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble());

  static Image _aImagen(PictureRecorder grabadora, int px) {
    final foto = grabadora.endRecording();
    final imagen = foto.toImageSync(px, px);
    foto.dispose();
    return imagen;
  }
}

/// Lo que midió [Pintura.medirColores].
class Medida {
  const Medida(
    this.colores,
    this.pintado, {
    this.personaje = 0,
    this.enPersonaje = const <double>[],
    this.fueraDelPersonaje = const <double>[],
    this.completo = false,
  });

  /// Qué parte del dibujo (0 a 1) cubre cada color, en el mismo orden que
  /// los colores que se pidieron medir.
  final List<double> colores;

  /// Qué parte del dibujo (0 a 1) está pintada, con cualquier color.
  final double pintado;

  /// Qué parte del personaje (0 a 1) está pintada, con cualquier color
  /// (0 si no se pidió medir un personaje).
  final double personaje;

  /// Qué parte del personaje (0 a 1) cubre cada color.
  final List<double> enPersonaje;

  /// Qué parte del dibujo (0 a 1) cubre cada color fuera del personaje.
  final List<double> fueraDelPersonaje;

  /// true si el dibujo está pintado entero (el 100%): todas sus partes
  /// pintadas. No cuentan los puntos tapados por las líneas negras ni unos
  /// poquitos puntitos sueltos tan chiquitos que no se ven.
  final bool completo;
}

/// Lo que se ha pintado de cada dibujo.
///
/// La pintura de cada dibujo es UNA imagen (de [resolucion] x [resolucion]),
/// no una lista de manchas: así pintar cuesta siempre lo mismo, aunque se
/// pinte durante horas. Se guarda en el celular como PNG (un archivo por
/// dibujo), un ratito después de pintar, al salir del dibujo y cuando la app
/// se va a segundo plano.
///
/// En memoria solo está la imagen grande del dibujo abierto; los demás se
/// guardan como miniaturas para el menú.
class Pintura {
  Pintura._();

  static const int resolucion = 1024;
  static const int resolucionMiniatura = 320;

  /// Cambia cuando cambia alguna imagen (el menú y el lienzo se redibujan).
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  static final Map<String, Image> _completas = <String, Image>{};
  static final Map<String, Image> _miniaturas = <String, Image>{};
  static final Map<String, Image> _lineasMini = <String, Image>{};
  static final Map<String, int> _abiertos = <String, int>{};
  static final Map<String, int> _versiones = <String, int>{};
  static final Set<String> _sucios = <String>{};
  static final Set<String> _revisados = <String>{};
  static Timer? _temporizador;
  static Future<Directory?>? _carpeta;

  /// Las lecturas y escrituras se hacen una detrás de otra para no pisarse.
  static Future<void> _cola = Future<void>.value();

  /// Imagen de pintura del dibujo abierto (null = todavía sin pintar).
  static Image? completa(String id) => _completas[id];

  static Image? miniatura(String id) => _miniaturas[id];

  /// Cambia cuando se borra lo pintado: así se ignoran manchas viejas.
  static int version(String id) => _versiones[id] ?? 0;

  /// Líneas del dibujo en tamaño miniatura (se crean una vez).
  /// Para los dibujos hechos desde una imagen se preparan en [cargar]; hasta
  /// entonces devuelve null.
  static Image? lineasMiniatura(Dibujo d) {
    final hecha = _lineasMini[d.id];
    if (hecha != null) return hecha;
    if (d.lineasPng != null) return null;
    final nueva = Dibujante.lineas(d, resolucionMiniatura);
    _lineasMini[d.id] = nueva;
    return nueva;
  }

  /// Lee la imagen de líneas de un dibujo hecho desde una imagen, del tamaño
  /// pedido. Devuelve null si no tiene o no se pudo leer.
  static Future<Image?> lineasDeImagen(Dibujo d, int px) async {
    final png = d.lineasPng;
    if (png == null) return null;
    try {
      final imagen = await _decodificar(png, px);
      if (imagen == null) d.lineasPng = null;
      return imagen;
    } catch (_) {
      // Imagen dañada: las líneas se dibujan a partir de las zonas.
      d.lineasPng = null;
      return null;
    }
  }

  /// Olvida las líneas guardadas de un dibujo (cuando se reemplaza).
  static void olvidarLineas(String id) {
    _lineasMini.remove(id)?.dispose();
    _mapas.remove(id);
  }

  /// Lee las miniaturas de lo pintado (solo las que faltan). Si encuentra
  /// pintura guardada por una versión anterior de la app, la convierte.
  /// Nunca lanza errores.
  static Future<void> cargar(List<Dibujo> dibujos) async {
    // Líneas de las miniaturas de los dibujos hechos desde una imagen.
    for (final d in dibujos) {
      if (d.lineasPng == null || _lineasMini.containsKey(d.id)) continue;
      final lineas = await lineasDeImagen(d, resolucionMiniatura);
      if (lineas == null) continue;
      _lineasMini.remove(d.id)?.dispose();
      _lineasMini[d.id] = lineas;
    }
    await _cola;
    final carpeta = await _obtenerCarpeta();
    if (carpeta == null) return;
    final pendientes =
        dibujos.where((d) => !_revisados.contains(d.id)).toList();
    for (final d in pendientes) {
      _revisados.add(d.id);
    }
    for (final d in pendientes) {
      await _cargarMiniatura(carpeta, d);
    }
    cambios.value++;
  }

  static Future<void> _cargarMiniatura(Directory carpeta, Dibujo d) async {
    try {
      final png = File(_ruta(carpeta, d.id, 'png'));
      if (!await png.exists()) await _migrar(carpeta, d);
      if (!await png.exists()) return;
      final imagen =
          await _decodificar(await png.readAsBytes(), resolucionMiniatura);
      if (imagen != null) _ponerMiniatura(d.id, imagen);
    } catch (_) {
      // Un archivo dañado no debe impedir que se abra la app.
    }
  }

  /// Convierte lo pintado con la versión anterior (lista de manchas en un
  /// .json) a imagen .png. Si no hay nada que convertir, no hace nada.
  static Future<void> _migrar(Directory carpeta, Dibujo d) async {
    final viejo = File(_ruta(carpeta, d.id, 'json'));
    final versionInicial = version(d.id);
    try {
      if (!await viejo.exists()) return;
      final datos = jsonDecode(await viejo.readAsString());
      final trazos = <Trazo>[];
      if (datos is Map) {
        final regiones = datos['regiones'];
        if (regiones is Map) {
          for (var i = 0; i < d.regiones.length; i++) {
            final lista = regiones[d.regiones[i].id];
            if (lista is! List) continue;
            for (final t in lista) {
              final trazo = Trazo.desdeJson(t, i);
              if (trazo != null) trazos.add(trazo);
            }
          }
        }
      }
      if (trazos.isNotEmpty) {
        final dibujada = Dibujante.hornear(null, d, trazos, resolucion);
        final plana = await Dibujante.copiaPlana(dibujada, resolucion);
        dibujada.dispose();
        try {
          await _escribirPng(carpeta, d.id, plana, versionInicial);
        } finally {
          plana.dispose();
        }
      }
      await viejo.delete();
    } catch (_) {
      // Si no se pudo convertir, el .json queda para intentarlo otra vez.
    }
  }

  /// Prepara la imagen grande para pintar. Hay que llamar a [cerrar] después.
  static Future<void> abrir(Dibujo d) async {
    _abiertos[d.id] = (_abiertos[d.id] ?? 0) + 1;
    if (_completas.containsKey(d.id)) return;
    final versionInicial = version(d.id);
    await _cola; // por si se está guardando o borrando
    final carpeta = await _obtenerCarpeta();
    if (carpeta == null) return;
    final png = File(_ruta(carpeta, d.id, 'png'));
    try {
      if (!await png.exists()) await _migrar(carpeta, d);
      if (!await png.exists()) return;
      final imagen = await _decodificar(await png.readAsBytes(), resolucion);
      if (imagen == null) throw const FormatException('imagen vacía');
      if (_completas.containsKey(d.id) ||
          version(d.id) != versionInicial ||
          (_abiertos[d.id] ?? 0) == 0) {
        imagen.dispose();
        return;
      }
      _completas[d.id] = imagen;
    } catch (_) {
      // El archivo está dañado: se aparta (no se borra) y se empieza en blanco.
      try {
        await png.rename('${png.path}.danado');
      } catch (_) {}
    }
  }

  /// Agrega estas manchas terminadas a la imagen del dibujo.
  /// [versionLienzo] es la [version] que había al abrir el dibujo.
  static void hornear(Dibujo d, List<Trazo> trazos, int versionLienzo) {
    if (trazos.isEmpty || versionLienzo != version(d.id)) return;
    final base = _completas[d.id];
    final nueva = Dibujante.hornear(base, d, trazos, resolucion);
    _completas[d.id] = nueva;
    base?.dispose();
    _aplanar(d.id, nueva);
    _sucios.add(d.id);
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 2), () {
      guardarPendientes();
    });
  }

  /// En algunos celulares, una imagen recién horneada sigue "enlazada" a la
  /// anterior (y esa a la anterior...), lo que llenaría la memoria. Aquí se
  /// reemplaza por una copia plana, sin enlaces.
  static Future<void> _aplanar(String id, Image imagen) async {
    final copia = imagen.clone();
    try {
      final plana = await Dibujante.copiaPlana(copia, resolucion);
      if (identical(_completas[id], imagen)) {
        _completas[id] = plana;
        imagen.dispose();
        cambios.value++;
      } else {
        plana.dispose();
      }
    } catch (_) {
      // Si no se pudo, se queda la imagen como estaba.
    } finally {
      copia.dispose();
    }
  }

  /// Se terminó de usar el dibujo: actualiza su miniatura, lo guarda y
  /// libera la imagen grande.
  static Future<void> cerrar(Dibujo d) async {
    final quedan = (_abiertos[d.id] ?? 1) - 1;
    if (quedan <= 0) {
      _abiertos.remove(d.id);
    } else {
      _abiertos[d.id] = quedan;
    }
    await guardarPendientes();
    if ((_abiertos[d.id] ?? 0) == 0) {
      _completas.remove(d.id)?.dispose();
    }
  }

  /// Guarda ya mismo lo que cambió (y actualiza sus miniaturas).
  static Future<void> guardarPendientes() {
    _temporizador?.cancel();
    _temporizador = null;
    if (_sucios.isEmpty) return _cola;
    final ids = _sucios.toList();
    _sucios.clear();
    final copias = <String, Image>{};
    final versiones = <String, int>{};
    for (final id in ids) {
      final imagen = _completas[id];
      if (imagen == null) continue;
      copias[id] = imagen.clone();
      versiones[id] = version(id);
    }
    return _enCola((carpeta) async {
      for (final entrada in copias.entries) {
        final id = entrada.key;
        final imagen = entrada.value;
        try {
          final esperada = versiones[id] ?? -1;
          if (esperada != version(id)) continue; // se borró mientras tanto
          // Primero se guarda el archivo (lo más importante)...
          if (carpeta != null)
            await _escribirPng(carpeta, id, imagen, esperada);
          // ...y después se actualiza la miniatura del menú.
          final mini = await Dibujante.copiaPlana(imagen, resolucionMiniatura);
          if (esperada == version(id)) {
            _ponerMiniatura(id, mini);
            cambios.value++;
          } else {
            mini.dispose();
          }
        } catch (_) {
          // Si no se pudo guardar, se sigue pintando igual.
        } finally {
          imagen.dispose();
        }
      }
    });
  }

  static void borrar(Dibujo dibujo) => borrarId(dibujo.id);

  /// Deja TODOS estos dibujos en blanco.
  static void borrarTodos(List<Dibujo> dibujos) {
    for (final d in dibujos) {
      borrarId(d.id);
    }
  }

  /// Deja el dibujo en blanco, borra lo guardado en el celular y deja su
  /// paleta completa otra vez.
  static void borrarId(String id) {
    _versiones[id] = version(id) + 1;
    _completas.remove(id)?.dispose();
    _miniaturas.remove(id)?.dispose();
    _sucios.remove(id);
    _pintables.remove(id);
    _mascaras.removeWhere((clave, _) => clave.startsWith('$id|'));
    _mapas.remove(id);
    PaletaDibujo.olvidar(id);
    cambios.value++;
    _enCola((carpeta) async {
      if (carpeta == null) return;
      for (final extension in const <String>['png', 'json']) {
        final archivo = File(_ruta(carpeta, id, extension));
        if (await archivo.exists()) await archivo.delete();
      }
    });
  }

  // ------------------------------------------------ cuánto pinta cada color

  /// Para medir, el dibujo se mira en chiquito (200 x 200 puntos): alcanza
  /// para saber cuánto cubre cada color y es muy rápido.
  static const int _ladoMedida = 200;

  /// Cuántos puntos (de 200 x 200) se pueden pintar en cada dibujo.
  static final Map<String, int> _pintables = <String, int>{};

  /// Parte del cuadrado del dibujo que se puede pintar (0 a 1).
  /// Mientras no se haya medido, 1.
  static double fraccionPintable(String id) {
    final n = _pintables[id];
    if (n == null) return 1.0;
    return n / (_ladoMedida * _ladoMedida);
  }

  /// Qué puntos (de 200 x 200) son del personaje de cada dibujo.
  static final Map<String, _Mascara> _mascaras = <String, _Mascara>{};

  /// Mide qué parte de lo que se puede pintar del dibujo cubre cada uno de
  /// [colores], y cuánto está pintado en total (con cualquier color).
  /// Si se le dan las zonas del [personaje], mide también cuánto del
  /// personaje está pintado y qué colores hay dentro y fuera de él.
  /// Cuenta lo ya pintado y también las manchas [activos] que se están
  /// pintando (como si ya hubieran terminado de derramarse).
  /// Devuelve null si no se pudo medir. Nunca lanza errores.
  static Future<Medida?> medirColores(
    Dibujo d,
    List<Trazo> activos,
    List<Color> colores, {
    Set<int> personaje = const <int>{},
  }) async {
    try {
      final total = await _contarPintables(d);
      final mascara =
          personaje.isEmpty ? null : await _mascaraPersonaje(d, personaje);
      final mapa = await _mapaDe(d);
      final base = _completas[d.id];
      if (base == null && activos.isEmpty) {
        final ceros = List<double>.filled(colores.length, 0.0);
        return Medida(ceros, 0, enPersonaje: ceros, fueraDelPersonaje: ceros);
      }
      // Lo pintado (en chiquito) y encima las manchas que se están pintando.
      const lado = _ladoMedida;
      final grabadora = PictureRecorder();
      final canvas = Canvas(grabadora);
      if (base != null) {
        canvas.drawImageRect(
          base,
          Dibujante._rect(base),
          Dibujante._cuadro(lado),
          Dibujante._suave,
        );
      }
      canvas.scale(lado / d.lado, lado / d.lado);
      for (final t in activos) {
        Dibujante.trazo(canvas, d, t, 1.0);
      }
      final pixeles = await _leerPixeles(grabadora.endRecording(), lado);
      if (pixeles == null) return null;
      return _contarColores(pixeles, colores, total, mascara, mapa);
    } catch (_) {
      return null;
    }
  }

  /// Cuenta los puntos de cada color. Solo cuentan los puntos bien pintados
  /// (los bordes, mezclados con otro color, no cuentan). Para el total
  /// pintado cuenta cualquier punto con pintura (también los bordes).
  static Medida _contarColores(
    Uint8List pixeles,
    List<Color> colores,
    int total,
    _Mascara? mascara,
    _Mapa? mapa,
  ) {
    final n = colores.length;
    final rojos = List<int>.filled(n, 0);
    final verdes = List<int>.filled(n, 0);
    final azules = List<int>.filled(n, 0);
    for (var k = 0; k < n; k++) {
      final argb = colores[k].toARGB32();
      rojos[k] = (argb >> 16) & 0xFF;
      verdes[k] = (argb >> 8) & 0xFF;
      azules[k] = argb & 0xFF;
    }
    final cuentas = List<int>.filled(n, 0);
    final adentro = List<int>.filled(n, 0);
    final puntos = mascara?.puntos;
    var pintados = 0;
    var pintadosPersonaje = 0;
    final zonas = mapa?.zonas;
    final pintadosZona = List<int>.filled(mapa?.cuantos.length ?? 0, 0);
    for (var i = 0; i + 3 < pixeles.length; i += 4) {
      final alfa = pixeles[i + 3];
      final delPersonaje = puntos != null && puntos[i >> 2] != 0;
      if (alfa >= 128) {
        pintados++;
        if (delPersonaje) pintadosPersonaje++;
        if (zonas != null) {
          final z = zonas[i >> 2];
          if (z >= 0) pintadosZona[z]++;
        }
      }
      if (alfa < 250) continue; // sin pintar (o un borde)
      final r = pixeles[i];
      final g = pixeles[i + 1];
      final b = pixeles[i + 2];
      var mejor = -1;
      var mejorDistancia = 40; // qué tan parecido tiene que ser el color
      for (var k = 0; k < n; k++) {
        final distancia = (r - rojos[k]).abs() +
            (g - verdes[k]).abs() +
            (b - azules[k]).abs();
        if (distancia < mejorDistancia) {
          mejorDistancia = distancia;
          mejor = k;
        }
      }
      if (mejor >= 0) {
        cuentas[mejor]++;
        if (delPersonaje) adentro[mejor]++;
      }
    }
    final divisor = total > 0 ? total : _ladoMedida * _ladoMedida;
    final enPersonaje = mascara?.cantidad ?? 0;
    return Medida(
      <double>[for (final c in cuentas) c / divisor],
      math.min(1.0, pintados / divisor),
      personaje:
          enPersonaje > 0 ? math.min(1.0, pintadosPersonaje / enPersonaje) : 0,
      enPersonaje: <double>[
        for (final c in adentro) enPersonaje > 0 ? c / enPersonaje : 0.0,
      ],
      fueraDelPersonaje: <double>[
        for (var k = 0; k < n; k++) (cuentas[k] - adentro[k]) / divisor,
      ],
      completo: mapa != null && _estaCompleto(mapa, pintadosZona),
    );
  }

  /// ¿Está pintado entero? (ver [Medida.completo])
  ///  - En total pueden quedar sin pintar como mucho unos puntitos sueltos
  ///    (el 0,1% de lo que se ve, que en el celular es casi nada).
  ///  - Y ninguna parte puede quedar en blanco: cada zona que se ve tiene
  ///    que estar pintada casi entera (aunque sea chiquita, como un ojo).
  static bool _estaCompleto(_Mapa mapa, List<int> pintadosZona) {
    var visibles = 0;
    var faltan = 0;
    for (var z = 0; z < mapa.cuantos.length; z++) {
      final cuantos = mapa.cuantos[z];
      final falta = math.max(0, cuantos - pintadosZona[z]);
      visibles += cuantos;
      faltan += falta;
      // Una zona tan chiquita que casi no se ve (menos de 8 puntos) no cuenta.
      if (cuantos >= 8 && falta > cuantos * 0.2) return false;
    }
    if (visibles == 0) return false;
    return faltan <= visibles * 0.001 + 3;
  }

  /// Qué zona se ve en cada punto del dibujo (en chiquito, 200 x 200) y
  /// cuántos puntos se ven de cada zona. Los puntos tapados por las líneas
  /// negras (y los ojos, sonrisas...) no cuentan: ahí no se ve la pintura.
  /// Se calcula una sola vez por dibujo.
  static final Map<String, _Mapa> _mapas = <String, _Mapa>{};

  static Future<_Mapa?> _mapaDe(Dibujo d) async {
    final hecho = _mapas[d.id];
    if (hecho != null) return hecho;
    const lado = _ladoMedida;
    final n = d.regiones.length;
    // 1) Cada zona se dibuja con un color que es su número (sin suavizar los
    //    bordes, así cada punto queda con el número exacto de una zona).
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    canvas.scale(lado / d.lado, lado / d.lado);
    for (var i = 0; i < n; i++) {
      canvas.drawPath(
        d.regiones[i].path,
        Paint()
          ..isAntiAlias = false
          ..color = Color(0xFF000000 | (i + 1)),
      );
    }
    final numeros = await _leerPixeles(grabadora.endRecording(), lado);
    if (numeros == null) return null;
    // 2) Las líneas negras, en el mismo tamaño.
    Image? lineas;
    if (d.lineasPng != null) {
      lineas = await lineasDeImagen(d, lado);
    } else {
      lineas = Dibujante.lineas(d, lado);
    }
    Uint8List? tapados;
    if (lineas != null) {
      final g = PictureRecorder();
      Canvas(g).drawImage(lineas, Offset.zero, Paint());
      lineas.dispose();
      tapados = await _leerPixeles(g.endRecording(), lado);
    }
    final zonas = Int16List(lado * lado);
    final cuantos = List<int>.filled(n, 0);
    for (var k = 0; k < zonas.length; k++) {
      final i = k * 4;
      var z = -1;
      if (numeros[i + 3] >= 250) {
        z = ((numeros[i] << 16) | (numeros[i + 1] << 8) | numeros[i + 2]) - 1;
        if (z >= n) z = -1;
      }
      if (z >= 0 && tapados != null && tapados[i + 3] >= 100) z = -1;
      zonas[k] = z;
      if (z >= 0) cuantos[z]++;
    }
    final mapa = _Mapa(zonas, cuantos);
    _mapas[d.id] = mapa;
    return mapa;
  }

  /// Rellena los puntitos que quedaron sin pintar (los que no cuentan para
  /// [Medida.completo]), cada uno con el color que más hay en su zona.
  /// Lo ya pintado no cambia. Se usa al celebrar, para que el dibujo quede
  /// pintado al 100%. Nunca lanza errores.
  static Future<void> rellenarPuntitos(Dibujo d) async {
    try {
      final versionInicial = version(d.id);
      final base = _completas[d.id];
      if (base == null) return;
      final mapa = await _mapaDe(d);
      if (mapa == null) return;
      // Lo pintado, en chiquito, para saber el color de cada zona.
      const lado = _ladoMedida;
      final grabadora = PictureRecorder();
      Canvas(grabadora).drawImageRect(
        base,
        Dibujante._rect(base),
        Dibujante._cuadro(lado),
        Dibujante._suave,
      );
      final pixeles = await _leerPixeles(grabadora.endRecording(), lado);
      if (pixeles == null) return;
      final cuentas = <int, Map<int, int>>{};
      for (var k = 0; k < mapa.zonas.length; k++) {
        final z = mapa.zonas[k];
        final i = k * 4;
        if (z < 0 || pixeles[i + 3] < 250) continue;
        final argb = 0xFF000000 |
            (pixeles[i] << 16) |
            (pixeles[i + 1] << 8) |
            pixeles[i + 2];
        final deZona = cuentas.putIfAbsent(z, () => <int, int>{});
        deZona[argb] = (deZona[argb] ?? 0) + 1;
      }
      final rellenos = <Trazo>[];
      for (final entrada in cuentas.entries) {
        var mejor = 0;
        var veces = -1;
        entrada.value.forEach((argb, n) {
          if (n > veces) {
            veces = n;
            mejor = argb;
          }
        });
        final caja = d.limites(entrada.key);
        rellenos.add(Trazo(
          region: entrada.key,
          color: Color(mejor),
          radio: caja.longestSide + 10,
          semilla: 0,
          inicio: caja.center,
        ));
      }
      if (rellenos.isEmpty) return;
      // Mientras tanto pudo seguir pintando: se rellena debajo de lo último.
      final actual = _completas[d.id];
      if (actual == null || version(d.id) != versionInicial) return;
      final nueva = Dibujante.rellenarDebajo(actual, d, rellenos, resolucion);
      _completas[d.id] = nueva;
      actual.dispose();
      _aplanar(d.id, nueva);
      _sucios.add(d.id);
      cambios.value++;
      _temporizador?.cancel();
      _temporizador = Timer(const Duration(seconds: 2), () {
        guardarPendientes();
      });
    } catch (_) {
      // Si no se pudo, quedan los puntitos (no se notan).
    }
  }

  /// Los puntos (en chiquito) que son del personaje: la parte que se ve de
  /// sus zonas (sin lo que tapan las zonas de encima). Se calcula una sola
  /// vez por dibujo.
  static Future<_Mascara?> _mascaraPersonaje(Dibujo d, Set<int> zonas) async {
    final clave = '${d.id}|${(zonas.toList()..sort()).join(',')}';
    final hecha = _mascaras[clave];
    if (hecha != null) return hecha;
    const lado = _ladoMedida;
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    canvas.saveLayer(Dibujante._cuadro(lado), Paint());
    canvas.scale(lado / d.lado, lado / d.lado);
    final suya = Paint()..color = const Color(0xFFFFFFFF);
    final otra = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < d.regiones.length; i++) {
      canvas.drawPath(d.regiones[i].path, zonas.contains(i) ? suya : otra);
    }
    canvas.restore();
    final pixeles = await _leerPixeles(grabadora.endRecording(), lado);
    if (pixeles == null) return null;
    final puntos = Uint8List(lado * lado);
    var cantidad = 0;
    for (var k = 0; k < puntos.length; k++) {
      if (pixeles[k * 4 + 3] >= 128) {
        puntos[k] = 1;
        cantidad++;
      }
    }
    final mascara = _Mascara(puntos, cantidad);
    _mascaras[clave] = mascara;
    return mascara;
  }

  /// Cuántos puntos del dibujo (en chiquito) se pueden pintar: los que están
  /// dentro de alguna zona. Se calcula una sola vez por dibujo.
  static Future<int> _contarPintables(Dibujo d) async {
    final hecho = _pintables[d.id];
    if (hecho != null) return hecho;
    const lado = _ladoMedida;
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    canvas.scale(lado / d.lado, lado / d.lado);
    final relleno = Paint()..color = const Color(0xFFFFFFFF);
    for (final region in d.regiones) {
      canvas.drawPath(region.path, relleno);
    }
    final pixeles = await _leerPixeles(grabadora.endRecording(), lado);
    if (pixeles == null) return lado * lado;
    var n = 0;
    for (var i = 3; i < pixeles.length; i += 4) {
      if (pixeles[i] >= 128) n++;
    }
    if (n == 0) n = lado * lado;
    _pintables[d.id] = n;
    return n;
  }

  /// Convierte el dibujo grabado en puntos (rojo, verde, azul y transparencia
  /// de cada punto).
  static Future<Uint8List?> _leerPixeles(Picture foto, int lado) async {
    final Image imagen;
    try {
      imagen = await foto.toImage(lado, lado);
    } finally {
      foto.dispose();
    }
    try {
      final datos = await imagen.toByteData(format: ImageByteFormat.rawRgba);
      if (datos == null) return null;
      return datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes);
    } finally {
      imagen.dispose();
    }
  }

  static void _ponerMiniatura(String id, Image imagen) {
    final vieja = _miniaturas[id];
    _miniaturas[id] = imagen;
    vieja?.dispose();
  }

  static Future<Image?> _decodificar(Uint8List bytes, int lado) async {
    final codec = await instantiateImageCodec(
      bytes,
      targetWidth: lado,
      targetHeight: lado,
    );
    try {
      final cuadro = await codec.getNextFrame();
      return cuadro.image;
    } finally {
      codec.dispose();
    }
  }

  /// Escribe la imagen como PNG. Si mientras tanto se borró lo pintado
  /// (cambió la versión), no la escribe.
  static Future<void> _escribirPng(
    Directory carpeta,
    String id,
    Image imagen,
    int versionEsperada,
  ) async {
    final datos = await imagen
        .toByteData(format: ImageByteFormat.png)
        .timeout(const Duration(seconds: 15));
    if (datos == null) return;
    final ruta = _ruta(carpeta, id, 'png');
    final temporal = File('$ruta.tmp');
    await temporal.writeAsBytes(
      datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
      flush: true,
    );
    if (version(id) != versionEsperada) {
      await temporal.delete();
      return;
    }
    await temporal.rename(ruta);
  }

  static Future<void> _enCola(Future<void> Function(Directory?) tarea) {
    _cola = _cola.then((_) async {
      try {
        // Nunca más de 30 segundos: la cola no se puede quedar trabada.
        await tarea(await _obtenerCarpeta())
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        // Si algo falla al guardar o borrar, la app sigue funcionando.
      }
    });
    return _cola;
  }

  static Future<Directory?> _obtenerCarpeta() async {
    final carpeta = await (_carpeta ??= () async {
      try {
        final base = await getApplicationSupportDirectory();
        final carpeta =
            Directory('${base.path}${Platform.pathSeparator}pintura');
        await carpeta.create(recursive: true);
        return carpeta;
      } catch (_) {
        return null;
      }
    }());
    if (carpeta == null) _carpeta = null; // se reintenta la próxima vez
    return carpeta;
  }

  static String _ruta(Directory carpeta, String id, String extension) {
    final limpio = id.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return '${carpeta.path}${Platform.pathSeparator}$limpio.$extension';
  }
}

/// Qué zona se ve en cada punto del dibujo (en chiquito; -1 = ninguna o
/// tapado por una línea) y cuántos puntos se ven de cada zona.
class _Mapa {
  const _Mapa(this.zonas, this.cuantos);

  final Int16List zonas;
  final List<int> cuantos;
}

/// Los puntos del personaje de un dibujo (1 = del personaje), en chiquito.
class _Mascara {
  const _Mascara(this.puntos, this.cantidad);

  final Uint8List puntos;
  final int cantidad;
}
