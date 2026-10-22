import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import '../config.dart';

/// Los sonidos de la app. Los archivos están en assets/sonidos/
/// (se crean con tools/generar_sonidos.py):
///  - gota1..5: una gota de pintura que cae y salpica (al tocar el dibujo).
///    Cada una termina en una nota distinta, así tocar seguido suena como
///    una melodía.
///  - trazo1..4: el pincel que pasa sobre el papel (al arrastrar el dedo).
///  - felicidades: la fiesta al terminar un dibujo.
///
/// Para que no se trabe con el uso: los sonidos se cargan UNA sola vez al
/// entrar a pintar, se reutilizan siempre los mismos reproductores y se
/// ignoran los sonidos demasiado seguidos.
class Sonidos {
  Sonidos._();

  static const List<String> _gotas = <String>[
    'sonidos/gota1.wav',
    'sonidos/gota2.wav',
    'sonidos/gota3.wav',
    'sonidos/gota4.wav',
    'sonidos/gota5.wav',
  ];

  static const List<String> _trazos = <String>[
    'sonidos/trazo1.wav',
    'sonidos/trazo2.wav',
    'sonidos/trazo3.wav',
    'sonidos/trazo4.wav',
  ];

  static const String _felicidades = 'sonidos/felicidades.wav';

  static List<AudioPlayer>? _reproductoresGotas;
  static List<AudioPlayer>? _reproductoresTrazos;
  static AudioPlayer? _reproductorFiesta;
  static Future<bool>? _preparado;
  static final math.Random _azar = math.Random();
  static final Stopwatch _reloj = Stopwatch()..start();
  static int _ultimaGota = -1;
  static int _ultimoTrazo = -1;
  static int _horaGota = -1000;
  static int _horaTrazo = -1000;
  static int _noAntesDe = 0; // si falló la carga, no reintentar enseguida

  /// Carga los sonidos (una sola vez). Si falla, se reintenta más tarde.
  static Future<bool> preparar() {
    final existente = _preparado;
    if (existente != null) return existente;
    if (_reloj.elapsedMilliseconds < _noAntesDe)
      return Future<bool>.value(false);
    final nuevo = _cargar();
    _preparado = nuevo;
    nuevo.then((bien) {
      if (!bien) {
        _preparado = null;
        _noAntesDe = _reloj.elapsedMilliseconds + 30000;
      }
    });
    return nuevo;
  }

  static Future<bool> _cargar() async {
    final creados = <AudioPlayer>[];
    const espera = Duration(seconds: 3);
    // Que los sonidos no le quiten el sonido a la voz ni a otras apps.
    final contexto = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    );

    Future<AudioPlayer> crear(
        String archivo, PlayerMode modo, double volumen) async {
      final reproductor = AudioPlayer();
      creados.add(reproductor);
      await reproductor.setAudioContext(contexto).timeout(espera);
      await reproductor.setPlayerMode(modo).timeout(espera);
      await reproductor.setReleaseMode(ReleaseMode.stop).timeout(espera);
      await reproductor.setVolume(volumen).timeout(espera);
      await reproductor.setSource(AssetSource(archivo)).timeout(espera);
      return reproductor;
    }

    try {
      final gotas = <AudioPlayer>[
        for (final archivo in _gotas)
          await crear(archivo, PlayerMode.lowLatency, Ajustes.volumenPintar),
      ];
      final trazos = <AudioPlayer>[
        for (final archivo in _trazos)
          await crear(archivo, PlayerMode.lowLatency, Ajustes.volumenTrazo),
      ];
      // La fiesta es más larga: va con el reproductor normal.
      final fiesta = await crear(
          _felicidades, PlayerMode.mediaPlayer, Ajustes.volumenCelebracion);
      _reproductoresGotas = gotas;
      _reproductoresTrazos = trazos;
      _reproductorFiesta = fiesta;
      return true;
    } catch (_) {
      for (final reproductor in creados) {
        unawaited(reproductor.dispose().catchError((Object _) {}));
      }
      return false;
    }
  }

  /// Una gota de pintura que cae (al tocar el dibujo). No espera a nada:
  /// si el sonido no está listo o hay demasiados seguidos, simplemente no suena.
  static void gota() {
    if (!Ajustes.sonidoPintar) return;
    final ahora = _reloj.elapsedMilliseconds;
    if (ahora - _horaGota < 70) return;
    _horaGota = ahora;
    final reproductores = _reproductoresGotas;
    if (reproductores == null) {
      preparar();
      return;
    }
    _ultimaGota = _otroAlAzar(reproductores.length, _ultimaGota);
    unawaited(_sonar(reproductores[_ultimaGota]));
  }

  /// El pincel que pasa sobre el papel (mientras se arrastra el dedo).
  static void trazo() {
    if (!Ajustes.sonidoPintar) return;
    final ahora = _reloj.elapsedMilliseconds;
    if (ahora - _horaTrazo < 120) return;
    _horaTrazo = ahora;
    final reproductores = _reproductoresTrazos;
    if (reproductores == null) {
      preparar();
      return;
    }
    _ultimoTrazo = _otroAlAzar(reproductores.length, _ultimoTrazo);
    unawaited(_sonar(reproductores[_ultimoTrazo]));
  }

  /// La fiesta al terminar un dibujo (campanitas y aplausos).
  static void felicidades() {
    if (!Ajustes.sonidoCelebracion) return;
    final reproductor = _reproductorFiesta;
    if (reproductor == null) {
      // Si todavía no estaba listo, suena apenas se cargue.
      preparar().then((bien) {
        final listo = _reproductorFiesta;
        if (bien && listo != null) unawaited(_sonar(listo));
      });
      return;
    }
    unawaited(_sonar(reproductor));
  }

  /// Un número al azar de 0 a [cantidad]-1 que no sea [anterior]
  /// (así no suena dos veces seguidas el mismo).
  static int _otroAlAzar(int cantidad, int anterior) {
    if (cantidad <= 1) return 0;
    var n = _azar.nextInt(cantidad - 1);
    if (n >= anterior && anterior >= 0) n++;
    return n;
  }

  static Future<void> _sonar(AudioPlayer reproductor) async {
    try {
      await reproductor.stop().timeout(const Duration(milliseconds: 500));
      await reproductor.resume().timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Sin sonido no pasa nada: se sigue pintando.
    }
  }
}
