import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';

/// Los sonidos de Pintar. Los archivos están en assets/sonidos/pintar/
/// (se crean con tools/generar_sonidos.py; se pueden cambiar por otros con
/// el mismo nombre):
///  - gota1..5: una gota de pintura que cae y salpica (al tocar el dibujo).
///    Cada una termina en una nota distinta, así tocar seguido suena como
///    una melodía.
///  - trazo1..4: el pincel que pasa sobre el papel (al arrastrar el dedo).
/// La fiesta al terminar un dibujo es la de todos los juegos
/// (lib/comun/sonidos.dart).
///
/// Para que no se trabe con el uso: los sonidos se cargan UNA sola vez al
/// entrar a pintar, se reutilizan siempre los mismos reproductores y se
/// ignoran los sonidos demasiado seguidos.
class SonidosPintar {
  SonidosPintar._();

  static const List<String> _gotas = <String>[
    'sonidos/pintar/gota1.wav',
    'sonidos/pintar/gota2.wav',
    'sonidos/pintar/gota3.wav',
    'sonidos/pintar/gota4.wav',
    'sonidos/pintar/gota5.wav',
  ];

  static const List<String> _trazos = <String>[
    'sonidos/pintar/trazo1.wav',
    'sonidos/pintar/trazo2.wav',
    'sonidos/pintar/trazo3.wav',
    'sonidos/pintar/trazo4.wav',
  ];

  static List<AudioPlayer>? _reproductoresGotas;
  static List<AudioPlayer>? _reproductoresTrazos;
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
          await crear(
              archivo, PlayerMode.lowLatency, AjustesPintar.volumenPintar),
      ];
      final trazos = <AudioPlayer>[
        for (final archivo in _trazos)
          await crear(
              archivo, PlayerMode.lowLatency, AjustesPintar.volumenTrazo),
      ];
      _reproductoresGotas = gotas;
      _reproductoresTrazos = trazos;
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
    if (!AjustesPintar.sonidoPintar) return;
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
    if (!AjustesPintar.sonidoPintar) return;
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
