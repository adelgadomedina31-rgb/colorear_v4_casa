import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'package:colorear_ninos/app/ajustes_app.dart';

/// Los sonidos de los juegos. Todos los archivos están en assets/sonidos/,
/// cada grupo en su carpeta (la lista completa está en
/// assets/sonidos/LEEME.txt):
///  - comunes/felicidades.wav: la fiesta de las celebraciones.
///  - comunes/acierto.wav: la campanita cuando acierta en un juego.
///  - colores/, animales/, pintar/: los de cada juego.
///
/// Para cambiar un sonido basta con poner otro archivo con el MISMO nombre
/// en la misma carpeta.
///
/// Si un sonido falla o no existe, no pasa nada: el juego sigue sin él.
class Sonidos {
  Sonidos._();

  static const String felicidadesArchivo = 'comunes/felicidades.wav';
  static const String aciertoArchivo = 'comunes/acierto.wav';

  static const String _carpeta = 'assets/sonidos/';
  static const Set<String> _formatos = <String>{
    'mp3',
    'm4a',
    'wav',
    'ogg',
    'aac',
  };

  /// Un reproductor por archivo (se crean una sola vez y se reutilizan).
  static final Map<String, Future<AudioPlayer?>> _reproductores =
      <String, Future<AudioPlayer?>>{};

  /// Los archivos que hay en assets/sonidos/ (sin "assets/sonidos/").
  static Future<Set<String>>? _archivos;

  /// La fiesta de las celebraciones (campanitas y aplausos).
  static void felicidades() {
    if (!AjustesApp.sonidoCelebracion) return;
    tocar(felicidadesArchivo, volumen: AjustesApp.volumenCelebracion);
  }

  /// La campanita cuando acierta.
  static void acierto() => tocar(aciertoArchivo);

  /// Deja listos estos sonidos para que suenen sin demora la primera vez
  /// (por ejemplo, al entrar a un juego).
  static Future<void> preparar(List<String> archivos) async {
    await Future.wait(<Future<void>>[
      for (final archivo in archivos)
        _reproductor(archivo, AjustesApp.volumenJuegos),
    ]);
  }

  /// Toca el sonido [archivo] de assets/sonidos/ (por ejemplo
  /// 'colores/reventar.wav'). No espera a que termine.
  static void tocar(String archivo, {double? volumen}) {
    if (!AjustesApp.sonidosJuegos && archivo != felicidadesArchivo) return;
    unawaited(_tocar(archivo, volumen ?? AjustesApp.volumenJuegos));
  }

  /// Toca el sonido y espera a que termine (como mucho [maximo]).
  /// Devuelve false si no pudo sonar.
  static Future<bool> tocarYEsperar(
    String archivo, {
    double? volumen,
    Duration maximo = const Duration(seconds: 4),
  }) async {
    if (!AjustesApp.sonidosJuegos) return false;
    final reproductor =
        await _reproductor(archivo, volumen ?? AjustesApp.volumenJuegos);
    if (reproductor == null) return false;
    try {
      final termino = reproductor.onPlayerComplete.first;
      await reproductor.stop().timeout(const Duration(milliseconds: 500));
      await reproductor.resume().timeout(const Duration(milliseconds: 500));
      await termino.timeout(maximo);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Busca un sonido por su nombre, sin importar el formato:
  /// buscar('animales/perro') encuentra 'animales/perro.mp3',
  /// 'animales/perro.wav'... Devuelve null si no hay ninguno.
  static Future<String?> buscar(String sinFormato) async {
    final archivos = await (_archivos ??= _listarArchivos());
    final buscado = sinFormato.toLowerCase();
    for (final archivo in archivos) {
      final punto = archivo.lastIndexOf('.');
      if (punto <= 0) continue;
      if (archivo.substring(0, punto).toLowerCase() == buscado) return archivo;
    }
    return null;
  }

  static Future<Set<String>> _listarArchivos() async {
    final encontrados = <String>{};
    try {
      final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle)
          .timeout(const Duration(seconds: 3));
      for (final ruta in manifiesto.listAssets()) {
        if (!ruta.startsWith(_carpeta)) continue;
        final archivo = Uri.decodeComponent(ruta.substring(_carpeta.length));
        final formato = archivo.split('.').last.toLowerCase();
        if (_formatos.contains(formato)) encontrados.add(archivo);
      }
    } catch (_) {
      // Sin lista de archivos: no se encuentra ninguno opcional.
    }
    return encontrados;
  }

  static Future<void> _tocar(String archivo, double volumen) async {
    final reproductor = await _reproductor(archivo, volumen);
    if (reproductor == null) return;
    try {
      await reproductor.setVolume(volumen).timeout(_espera);
      await reproductor.stop().timeout(_espera);
      await reproductor.resume().timeout(_espera);
    } catch (_) {
      // Sin sonido no pasa nada: el juego sigue.
    }
  }

  static const Duration _espera = Duration(seconds: 3);

  static Future<AudioPlayer?> _reproductor(String archivo, double volumen) {
    final existente = _reproductores[archivo];
    if (existente != null) return existente;
    final nuevo = _crear(archivo, volumen);
    _reproductores[archivo] = nuevo;
    nuevo.then((r) {
      // Si falló, se reintenta la próxima vez.
      if (r == null) _reproductores.remove(archivo);
    });
    return nuevo;
  }

  static Future<AudioPlayer?> _crear(String archivo, double volumen) async {
    final reproductor = AudioPlayer();
    try {
      // Que los sonidos no le quiten el sonido a la voz ni a otras apps.
      await reproductor
          .setAudioContext(AudioContext(
            android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          ))
          .timeout(_espera);
      await reproductor.setReleaseMode(ReleaseMode.stop).timeout(_espera);
      await reproductor.setVolume(volumen).timeout(_espera);
      // audioplayers busca los archivos dentro de "assets/".
      await reproductor
          .setSource(AssetSource('sonidos/$archivo'))
          .timeout(_espera);
      return reproductor;
    } catch (_) {
      unawaited(reproductor.dispose().catchError((Object _) {}));
      return null;
    }
  }
}
