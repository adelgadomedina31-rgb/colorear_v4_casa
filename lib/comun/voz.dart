import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';

/// La voz que dice el nombre de los colores y los avisos.
///
/// Hay dos formas de hablar:
///  1. Voces GRABADAS (las más naturales): si en assets/voces/ hay un
///     archivo para lo que hay que decir (por ejemplo "rojo.m4a"), se
///     escucha esa grabación. Ver assets/voces/LEEME.txt.
///  2. Si no hay grabación, se usa el "texto a voz" del propio celular
///     (funciona sin internet si el celular tiene descargada la voz en
///     español). Se busca la voz femenina en español de mejor calidad, con
///     un tono casi normal: subirle mucho el tono la hacía sonar a robot.
///
/// Para que nunca se trabe: cada paso tiene un tiempo máximo de espera, y el
/// fin de cada frase se detecta con los avisos del motor de voz (si el aviso
/// no llega, igual se sigue después de un momento).
class Voz {
  Voz._();

  static final FlutterTts _tts = FlutterTts();
  static Future<bool>? _preparada;
  static Completer<void>? _frase;
  static final Stopwatch _reloj = Stopwatch()..start();
  static int _inicioFrase = 0;

  /// Sube con cada frase nueva (para cortar una grabación que quedó a medias).
  static int _turno = 0;

  /// Las grabaciones que hay en assets/voces/ (nombre sin tilde -> archivo).
  static Future<Map<String, String>>? _grabaciones;
  static AudioPlayer? _reproductor;

  static const String _carpetaVoces = 'assets/voces/';
  static const Set<String> _formatos = <String>{
    'mp3',
    'm4a',
    'wav',
    'ogg',
    'aac'
  };

  /// Deja la voz lista. Se puede llamar varias veces; solo prepara una vez
  /// (si falla, se reintenta la próxima vez).
  static Future<bool> preparar() {
    _grabaciones ??= _buscarGrabaciones();
    final existente = _preparada;
    if (existente != null) return existente;
    final nueva = _configurar().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    _preparada = nueva;
    nueva.then((bien) {
      if (!bien) _preparada = null;
    });
    return nueva;
  }

  static Future<bool> _configurar() async {
    try {
      // speak() no espera a que termine; el final llega por estos avisos.
      await _tts.awaitSpeakCompletion(false);
      _tts.setCompletionHandler(_terminoFrase);
      _tts.setCancelHandler(_terminoFrase);
      // Un error termina la frase enseguida (sin esperar).
      _tts.setErrorHandler((_) => _cortarFrase());

      // Primero español latino; si no hay, cualquier español.
      for (final idioma in const <String>[
        'es-US',
        'es-PE',
        'es-MX',
        'es-419',
        'es-ES',
        'es'
      ]) {
        final disponible = await _tts.isLanguageAvailable(idioma);
        if (disponible == true) {
          await _tts.setLanguage(idioma);
          break;
        }
      }
      await _elegirMejorVoz();
      await _tts.setPitch(AjustesApp.vozTono);
      await _tts.setSpeechRate(AjustesApp.vozVelocidad);
      await _tts.setVolume(1.0);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _terminoFrase() {
    // Un aviso que llega enseguida de empezar es de la frase anterior.
    if (_reloj.elapsedMilliseconds - _inicioFrase < 150) return;
    _cortarFrase();
  }

  static void _cortarFrase() {
    final frase = _frase;
    if (frase != null && !frase.isCompleted) frase.complete();
  }

  /// Elige la voz en español que suene más natural: femenina, de la mejor
  /// calidad que tenga el celular y, si se puede, que funcione sin internet.
  /// Si el celular no da esos datos, se deja la voz por defecto (en Android
  /// suele ser femenina).
  static Future<void> _elegirMejorVoz() async {
    try {
      final voces = await _tts.getVoices;
      if (voces is! List) return;
      Map<String, String>? mejor;
      var mejorPuntaje = 0;
      for (final v in voces) {
        if (v is! Map) continue;
        final nombre = '${v['name'] ?? ''}';
        final idioma = '${v['locale'] ?? ''}';
        final n = nombre.toLowerCase();
        final l = idioma.toLowerCase();
        final genero = '${v['gender'] ?? ''}'.toLowerCase();
        final extras = '${v['features'] ?? ''}'.toLowerCase();
        if (!l.startsWith('es')) continue;
        if (extras.contains('notinstalled')) continue;
        final porInternet =
            '${v['network_required']}' == '1' || n.contains('network');
        if (porInternet && !AjustesApp.vozPermitirInternet) continue;
        final esFemenina =
            genero == 'female' || n.contains('female') || n.contains('femenin');
        if (!esFemenina) continue;
        var puntaje = 10;
        // Calidad que informa Android: 500 muy alta, 400 alta, 300 normal.
        final calidad = int.tryParse('${v['quality'] ?? ''}') ?? 0;
        if (calidad >= 500) {
          puntaje += 4;
        } else if (calidad >= 400) {
          puntaje += 2;
        }
        // En iPhone: "enhanced" / "premium" son las voces naturales.
        if (n.contains('premium') || '${v['quality']}'.contains('premium')) {
          puntaje += 5;
        } else if (n.contains('enhanced') ||
            '${v['quality']}'.contains('enhanced')) {
          puntaje += 4;
        }
        if (n.contains('local')) puntaje += 1; // funciona sin internet
        if (porInternet) puntaje += 2; // suenan más naturales (si se permiten)
        if (l.contains('us') || l.contains('419') || l.contains('mx')) {
          puntaje += 1;
        }
        if (puntaje > mejorPuntaje) {
          mejorPuntaje = puntaje;
          mejor = <String, String>{'name': nombre, 'locale': idioma};
        }
      }
      if (mejor != null) await _tts.setVoice(mejor);
    } catch (_) {
      // Si falla, se queda la voz por defecto.
    }
  }

  // ------------------------------------------------------- voces grabadas

  /// "Elige un color" -> "elige_un_color"; "Marrón" -> "marron".
  static String clave(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final salida = StringBuffer();
    var guion = false;
    for (final letra in texto.trim().toLowerCase().split('')) {
      final i = conTilde.indexOf(letra);
      final c = i >= 0 ? sinTilde[i] : letra;
      final esLetra = RegExp(r'[a-z0-9]').hasMatch(c);
      if (esLetra) {
        if (guion && salida.isNotEmpty) salida.write('_');
        salida.write(c);
        guion = false;
      } else {
        guion = true;
      }
    }
    return salida.toString();
  }

  static Future<Map<String, String>> _buscarGrabaciones() async {
    final encontradas = <String, String>{};
    if (!AjustesApp.usarVocesGrabadas) return encontradas;
    try {
      final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle)
          .timeout(const Duration(seconds: 3));
      for (final ruta in manifiesto.listAssets()) {
        if (!ruta.startsWith(_carpetaVoces)) continue;
        final archivo =
            Uri.decodeComponent(ruta.substring(_carpetaVoces.length));
        final punto = archivo.lastIndexOf('.');
        if (punto <= 0 || archivo.contains('/')) continue;
        final formato = archivo.substring(punto + 1).toLowerCase();
        if (!_formatos.contains(formato)) continue;
        // audioplayers busca los archivos dentro de "assets/".
        encontradas[clave(archivo.substring(0, punto))] =
            ruta.substring('assets/'.length);
      }
    } catch (_) {
      // Sin lista de archivos: se usa la voz del celular.
    }
    return encontradas;
  }

  static Future<AudioPlayer> _reproductorVoz() async {
    final hay = _reproductor;
    if (hay != null) return hay;
    final nuevo = AudioPlayer();
    const espera = Duration(seconds: 3);
    await nuevo.setReleaseMode(ReleaseMode.stop).timeout(espera);
    await nuevo.setVolume(1.0).timeout(espera);
    nuevo.onPlayerComplete.listen((_) => _cortarFrase());
    _reproductor = nuevo;
    return nuevo;
  }

  /// Dice la frase con grabaciones, si están TODAS. Devuelve false si no
  /// hay grabaciones (entonces se usa la voz del celular).
  static Future<bool> _decirGrabado(List<String> partes, int turno) async {
    if (partes.isEmpty) return false;
    final lista = _grabaciones ??= _buscarGrabaciones();
    final grabaciones = await lista;
    final archivos = <String>[];
    for (final parte in partes) {
      final archivo = grabaciones[clave(parte)];
      if (archivo == null) return false;
      archivos.add(archivo);
    }
    var empezo = false;
    try {
      final reproductor = await _reproductorVoz();
      for (final archivo in archivos) {
        if (turno != _turno) break; // empezó otra frase
        final frase = Completer<void>();
        _frase = frase;
        await reproductor.stop().timeout(const Duration(seconds: 1));
        await reproductor
            .play(AssetSource(archivo))
            .timeout(const Duration(seconds: 2));
        empezo = true;
        await frase.future.timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Si una grabación falla al empezar, se usa la voz del celular.
    }
    return empezo;
  }

  /// Dice [texto] y espera a que termine (como mucho unos segundos).
  /// Nunca se queda esperando para siempre.
  ///
  /// [grabaciones] son los nombres de las grabaciones que dicen lo mismo,
  /// en orden (por ejemplo `['usa_otro_color']`). Si están
  /// todas en assets/voces/, se escuchan esas en vez de la voz del celular.
  static Future<void> decir(
    String texto, {
    List<String> grabaciones = const <String>[],
  }) async {
    if (!AjustesApp.vozActiva) return;
    final turno = ++_turno;
    _cortarFrase(); // por si quedó una frase sin terminar
    try {
      await _reproductor?.stop().timeout(const Duration(seconds: 1));
    } catch (_) {}
    if (await _decirGrabado(grabaciones, turno)) return;
    if (turno != _turno) return;
    final lista = await preparar();
    if (!lista || turno != _turno) return;
    final frase = Completer<void>();
    _frase = frase;
    _inicioFrase = _reloj.elapsedMilliseconds;
    try {
      await _tts.speak(texto).timeout(const Duration(seconds: 2));
      await frase.future.timeout(const Duration(milliseconds: 3500));
    } catch (_) {
      // Sin voz no pasa nada: la app sigue funcionando.
    } finally {
      if (identical(_frase, frase)) _frase = null;
    }
  }
}
