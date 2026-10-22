import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/dibujo.dart';
import '../models/modo_pintado.dart';
import '../models/paleta_dibujo.dart';
import '../models/personaje_dibujo.dart';
import '../models/pintura.dart';
import '../servicios/sonidos.dart';
import '../servicios/voz.dart';
import '../widgets/botones.dart';
import '../widgets/celebracion.dart';
import '../widgets/lienzo.dart';
import '../widgets/paleta.dart';

/// Pantalla de pintar: arriba los botones grandes (inicio, anterior, siguiente,
/// borrar), en el medio el dibujo y abajo los colores de ESE dibujo.
///
/// - Al entrar a un dibujo no hay ningún color elegido: la voz dice
///   "¡Elige un color!" y los tarritos saltan hasta que ella elige uno.
/// - Modo 1 ("Pintado total"): se pinta libre. Cuando un color cubre la mitad
///   del dibujo, la voz recomienda usar otro y el color se suelta.
/// - Modo 2 ("Pintado por objeto"): todo el personaje (el pez, el sol...) se
///   pinta de un solo color, y ese color no pinta el resto. Cuando el
///   personaje está terminado, la voz pide otro color y el color se suelta.
/// - Nunca se elige otro color solo: siempre lo elige ella.
/// - Cuando el dibujo queda pintado casi entero (el 95%), sale la celebración.
class PantallaPintar extends StatefulWidget {
  const PantallaPintar({
    super.key,
    required this.dibujos,
    required this.indice,
  });

  final List<Dibujo> dibujos;
  final int indice;

  @override
  State<PantallaPintar> createState() => _EstadoPintar();
}

/// Lo que hay que hacer después de revisar una medición.
class _Resultado {
  bool soltarColor = false;
  bool celebrar = false;
  String? frase;
  List<String> grabaciones = const <String>[];

  bool get hayAlgo => soltarColor || celebrar || frase != null;
}

class _EstadoPintar extends State<PantallaPintar> {
  late int _indice;

  /// El modo de pintar (se elige con el engranaje del menú).
  final int _modo = ModoPintado.actual;

  /// Los colores del dibujo abierto (como mucho 5).
  List<ColorConNombre> _colores = const <ColorConNombre>[];

  /// Lo que se recuerda del dibujo abierto (null mientras se lee).
  PaletaDibujo? _paleta;

  /// Modo 2: el personaje del dibujo abierto (null en el Modo 1, o si el
  /// dibujo no tiene personaje).
  PersonajeDibujo? _personaje;

  /// El color elegido (null = ninguno: hay que elegir uno).
  ColorConNombre? _color;

  /// true mientras la voz dice el nombre del color (no se puede elegir otro).
  bool _hablando = false;

  /// Sube cada vez que se borra lo pintado (para empezar un lienzo nuevo).
  int _reinicios = 0;

  /// La primera medición al entrar a un dibujo no dice nada en voz alta:
  /// solo se pone al día con lo que ya estaba pintado.
  bool _primeraMedicion = true;

  /// Una medición que llegó antes de que la paleta estuviera lista.
  Medida? _medicionPendiente;

  /// true mientras se ve la celebración de "¡Felicidades!".
  bool _celebrando = false;

  /// Corre durante los 3 segundos después de un aviso, para no repetirlo
  /// a cada toque.
  Timer? _avisoReciente;

  @override
  void initState() {
    super.initState();
    _indice = widget.indice;
    _entrarAlDibujo(pedirColor: true);
    // La voz y los sonidos se preparan mientras tanto.
    Voz.preparar();
    Sonidos.preparar();
  }

  @override
  void dispose() {
    _avisoReciente?.cancel();
    PaletaDibujo.guardarPendientes();
    super.dispose();
  }

  Dibujo get _dibujo => widget.dibujos[_indice];

  /// Cada vez que se entra a un dibujo (o se pasa a otro, o se borra), se usa
  /// lo de ESE dibujo. Si [pedirColor], no queda ningún color elegido y la
  /// voz pide elegir uno.
  void _entrarAlDibujo({required bool pedirColor}) {
    final dibujo = _dibujo;
    _colores = PaletaDibujo.coloresDe(dibujo);
    final personaje =
        _modo == ModoPintado.porObjeto ? PersonajeDibujo.de(dibujo) : null;
    _personaje = (personaje != null && personaje.existe) ? personaje : null;
    _primeraMedicion = true;
    _medicionPendiente = null;
    _celebrando = false;
    if (pedirColor) {
      _color = null;
      _pedirColor(dibujo.id);
    }
    final lista = PaletaDibujo.enMemoria(dibujo.id);
    if (lista != null) {
      _usarPaleta(lista);
      return;
    }
    _paleta = null;
    PaletaDibujo.cargar(dibujo.id).then((paleta) {
      if (!mounted || _dibujo.id != dibujo.id) return;
      setState(() => _usarPaleta(paleta));
    });
  }

  void _usarPaleta(PaletaDibujo paleta) {
    _paleta = paleta;
    final pendiente = _medicionPendiente;
    _medicionPendiente = null;
    if (pendiente != null) {
      // Es la primera medición: se revisa en silencio.
      _primeraMedicion = false;
      _revisar(pendiente, enSilencio: true);
    }
  }

  /// Al entrar, la voz pide elegir un color (si todavía no eligió).
  void _pedirColor(String id) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _dibujo.id != id || _color != null) return;
      _avisar(Ajustes.vozEligeUnColor,
          siempre: true, grabaciones: const <String>['elige_un_color']);
    });
  }

  Future<void> _elegirColor(ColorConNombre opcion) async {
    if (_hablando || _paleta == null) return;
    setState(() => _color = opcion);
    await _hablar(opcion.nombre, grabaciones: <String>[opcion.nombre]);
  }

  /// Dice una frase. Mientras habla, la paleta queda bloqueada para que la
  /// frase se escuche completa. [grabaciones]: ver [Voz.decir].
  Future<void> _hablar(
    String texto, {
    List<String> grabaciones = const <String>[],
  }) async {
    if (_hablando) return;
    setState(() => _hablando = true);
    final inicio = DateTime.now();
    try {
      // Como mucho 5 segundos: la paleta nunca se queda bloqueada.
      await Voz.decir(texto, grabaciones: grabaciones)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Si la voz falla o tarda, igual se sigue.
    }
    // Pausa mínima, aunque la voz termine antes (o no haya voz).
    final pasado = DateTime.now().difference(inicio);
    const minimo = Duration(milliseconds: Ajustes.pausaMinimaColor);
    if (pasado < minimo) {
      await Future<void>.delayed(minimo - pasado);
    }
    if (!mounted) return;
    setState(() => _hablando = false);
  }

  /// Avisos mientras pinta: se dicen SIN bloquear la paleta (así puede
  /// elegir otro color mientras escucha). Si [siempre] es false, no se
  /// repiten más de una vez cada 3 segundos. [grabaciones]: ver [Voz.decir].
  void _avisar(
    String texto, {
    bool siempre = false,
    List<String> grabaciones = const <String>[],
  }) {
    if (!siempre && (_hablando || _avisoReciente != null)) return;
    _avisoReciente?.cancel();
    _avisoReciente = Timer(const Duration(seconds: 3), () {
      _avisoReciente = null;
    });
    Voz.decir(texto, grabaciones: grabaciones);
  }

  /// Pone el nombre del personaje y del color en una frase.
  String _frase(String plantilla, {String color = ''}) => plantilla
      .replaceAll('{objeto}', _personaje?.nombre ?? Ajustes.personajeSinNombre)
      .replaceAll('{color}', color.toLowerCase());

  /// El lienzo pregunta antes de pintar en la zona [zona]. false = no se
  /// pinta (y la voz dice por qué).
  bool _puedePintar(int zona) {
    final paleta = _paleta;
    if (paleta == null || _celebrando) return false;
    final color = _color;
    if (color == null) {
      _avisar(Ajustes.vozEligeUnColor,
          grabaciones: const <String>['elige_un_color']);
      return false;
    }
    final personaje = _personaje;
    if (personaje == null) return true; // Modo 1: se pinta libre.

    // Modo 2: el personaje, de un solo color; ese color, solo para él.
    final nombre = color.nombre;
    final suyo = paleta.colorPersonaje;
    if (personaje.contiene(zona)) {
      if (suyo == null) {
        if (paleta.usadoEnResto(nombre)) {
          // Ese color ya se usó en el fondo: el personaje necesita otro.
          _avisar(_frase(Ajustes.vozOtroColorParaPersonaje));
          return false;
        }
        paleta.fijarColorPersonaje(nombre);
        return true;
      }
      if (suyo != nombre) {
        _avisar(_frase(Ajustes.vozPintaPersonajeCon, color: suyo));
        return false;
      }
      return true;
    }
    if (nombre == suyo) {
      if (paleta.personajeTerminado) {
        _avisar(Ajustes.vozEligeOtroParaSeguir, grabaciones: const <String>[
          'elige_otro_color_para_seguir_pintando'
        ]);
      } else {
        _avisar(_frase(Ajustes.vozColorDelPersonaje));
      }
      return false;
    }
    paleta.usarEnResto(nombre);
    return true;
  }

  /// El lienzo midió lo pintado.
  void _alMedir(Medida medida) {
    if (_paleta == null) {
      _medicionPendiente = medida;
      return;
    }
    final enSilencio = _primeraMedicion;
    _primeraMedicion = false;
    final resultado = _revisar(medida, enSilencio: enSilencio);
    if (!resultado.hayAlgo) return;
    setState(() {
      if (resultado.soltarColor) _color = null;
      if (resultado.celebrar) _celebrando = true;
    });
    if (resultado.celebrar) {
      _celebrar();
    } else if (resultado.frase != null) {
      _avisar(resultado.frase!,
          siempre: true, grabaciones: resultado.grabaciones);
    }
  }

  /// Revisa una medición y anota lo que pasó. [enSilencio] = al entrar al
  /// dibujo: solo se pone al día (no dice nada, no suelta el color, no
  /// celebra lo que ya estaba terminado).
  _Resultado _revisar(Medida medida, {required bool enSilencio}) {
    final paleta = _paleta!;
    final resultado = _Resultado();
    final personaje = _personaje;
    if (personaje != null && enSilencio) _ponerAlDia(paleta, medida);

    // ¿Terminó todo el dibujo? (una sola vez por dibujo)
    if (!paleta.celebrado &&
        medida.pintado >= Ajustes.porcentajeCelebracion - 0.0005) {
      paleta.marcarCelebrado();
      resultado.celebrar = !enSilencio;
    }

    final elegido = _color;
    if (personaje != null) {
      // Modo 2: ¿terminó el personaje? Entonces hay que elegir otro color.
      if (!paleta.personajeTerminado &&
          medida.personaje >= Ajustes.personajeTerminado) {
        paleta.marcarPersonajeTerminado();
        if (!enSilencio && elegido?.nombre == paleta.colorPersonaje) {
          resultado.soltarColor = true;
          resultado.frase = Ajustes.vozEligeOtroParaSeguir;
          resultado.grabaciones = const <String>[
            'elige_otro_color_para_seguir_pintando',
          ];
        }
      }
    } else if (_modo == ModoPintado.total) {
      // Modo 1: si un color cubre la mitad del dibujo, se recomienda otro.
      for (var k = 0; k < _colores.length && k < medida.colores.length; k++) {
        final nombre = _colores[k].nombre;
        if (medida.colores[k] < Ajustes.parteParaRecomendar ||
            paleta.recomendado(nombre)) {
          continue;
        }
        paleta.marcarRecomendado(nombre);
        if (!enSilencio && elegido?.nombre == nombre) {
          resultado.soltarColor = Ajustes.soltarColorAlRecomendar;
          resultado.frase = Ajustes.vozUsaOtroColor;
          resultado.grabaciones = const <String>['usa_otro_color'];
        }
      }
    }
    return resultado;
  }

  /// Modo 2, al entrar: si el dibujo ya tenía pintura (por ejemplo, del
  /// Modo 1), se anota de qué color quedó el personaje (el que más hay en
  /// él) y qué colores hay en el resto.
  void _ponerAlDia(PaletaDibujo paleta, Medida medida) {
    if (medida.personaje > 0.02) {
      var mejor = -1;
      for (var k = 0;
          k < _colores.length && k < medida.enPersonaje.length;
          k++) {
        if (medida.enPersonaje[k] > 0.01 &&
            (mejor < 0 || medida.enPersonaje[k] > medida.enPersonaje[mejor])) {
          mejor = k;
        }
      }
      if (mejor >= 0) paleta.fijarColorPersonaje(_colores[mejor].nombre);
    }
    for (var k = 0;
        k < _colores.length && k < medida.fueraDelPersonaje.length;
        k++) {
      final nombre = _colores[k].nombre;
      if (medida.fueraDelPersonaje[k] > 0.005 &&
          nombre != paleta.colorPersonaje) {
        paleta.usarEnResto(nombre);
      }
    }
  }

  /// ¡Terminó el dibujo! Estrellas, la fiesta y la voz que la felicita.
  void _celebrar() {
    Sonidos.felicidades();
    final id = _dibujo.id;
    // La voz entra después de las primeras campanitas.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || !_celebrando || _dibujo.id != id) return;
      _avisar(Ajustes.vozCelebracion,
          siempre: true, grabaciones: const <String>['felicidades']);
    });
  }

  void _mover(int paso) {
    final cantidad = widget.dibujos.length;
    setState(() {
      _indice = (_indice + paso + cantidad) % cantidad;
      _entrarAlDibujo(pedirColor: true);
    });
  }

  /// Borra lo pintado del dibujo y lo deja como nuevo (sin preguntar).
  /// El color elegido se queda, para seguir pintando.
  void _borrar() {
    Pintura.borrar(_dibujo);
    setState(() {
      _reinicios++;
      _entrarAlDibujo(pedirColor: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clave = '${_dibujo.id}#$_reinicios';
    return Scaffold(
      backgroundColor: Ajustes.fondoApp,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BotonGrande(
                        icono: Icons.home_rounded,
                        color: const Color(0xFF1E88E5),
                        alTocar: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        children: [
                          BotonGrande(
                            icono: Icons.arrow_back_rounded,
                            color: const Color(0xFFFB8C00),
                            alTocar: () => _mover(-1),
                          ),
                          const SizedBox(width: 14),
                          BotonGrande(
                            icono: Icons.arrow_forward_rounded,
                            color: const Color(0xFFFB8C00),
                            alTocar: () => _mover(1),
                          ),
                        ],
                      ),
                      BotonGrande(
                        icono: Icons.refresh_rounded,
                        color: const Color(0xFFE53935),
                        alTocar: _borrar,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Lienzo(
                      key: ValueKey<String>(clave),
                      dibujo: _dibujo,
                      color: _color?.color ?? const Color(0x00000000),
                      colores: <Color>[for (final c in _colores) c.color],
                      puedePintar: _puedePintar,
                      personaje: _personaje?.zonas ?? const <int>{},
                      alMedir: _alMedir,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                  child: Paleta(
                    key: ValueKey<String>(clave),
                    colores: _colores,
                    seleccionado: _color,
                    bloqueada: _hablando,
                    cargando: _paleta == null,
                    alElegir: _elegirColor,
                  ),
                ),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                key: ValueKey<String>('fiesta_$clave'),
                alTerminar: () {
                  if (mounted) setState(() => _celebrando = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}
