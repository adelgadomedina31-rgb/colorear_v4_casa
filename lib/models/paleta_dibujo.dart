import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'dibujo.dart';

/// La paleta de UN dibujo: qué colores tiene y lo que hay que recordar de
/// cómo se fue pintando. Los colores no se acaban en ningún modo.
///
/// - Cada dibujo tiene sus propios colores (como mucho 5, ver config.dart).
/// - Modo 1 ("Pintado total"): recuerda a qué colores ya se les recomendó
///   cambiar (cuando cubrieron la mitad del dibujo), para no repetirlo.
/// - Modo 2 ("Pintado por objeto"): recuerda el color del personaje y los
///   colores que se usaron en el resto del dibujo.
/// - También recuerda si ya salió la celebración (sale una sola vez).
/// - Cada dibujo guarda lo suyo aparte, en el celular. Borrar lo pintado lo
///   deja todo como nuevo.
class PaletaDibujo {
  PaletaDibujo._(this.id);

  final String id;

  /// Modo 1: colores a los que ya se les recomendó cambiar.
  final Set<String> _recomendados = <String>{};

  /// Modo 2: el color del personaje (null si todavía no se pintó).
  String? _colorPersonaje;

  /// Modo 2: colores que se usaron fuera del personaje.
  final Set<String> _coloresResto = <String>{};

  /// Modo 2: true si ya se avisó que el personaje está terminado.
  bool _personajeTerminado = false;

  bool _celebrado = false;

  static final Map<String, PaletaDibujo> _memoria = <String, PaletaDibujo>{};
  static final Set<PaletaDibujo> _sinGuardar = <PaletaDibujo>{};
  static Timer? _temporizador;
  static const String _prefijo = 'paleta_';

  // ------------------------------------------------------- colores del dibujo

  /// Los colores de [d], en orden. Se buscan en config.dart
  /// ([Ajustes.paletasDibujos]), después en el propio dibujo (campo
  /// "colores" del JSON) y si no, se usan los de [Ajustes.paletaPorDefecto].
  /// Siempre hay al menos 2 (para poder cambiar de color): si el dibujo
  /// trae uno solo, se completa con los de por defecto.
  static List<ColorConNombre> coloresDe(Dibujo d) {
    for (final nombres in <List<String>>[
      Ajustes.paletasDibujos[d.id] ?? const <String>[],
      d.colores,
      Ajustes.paletaPorDefecto,
    ]) {
      final lista = _buscar(nombres);
      if (lista.isEmpty) continue;
      for (final otro in _buscar(Ajustes.paletaPorDefecto)) {
        if (lista.length >= 2) break;
        if (!lista.contains(otro)) lista.add(otro);
      }
      return lista;
    }
    return Ajustes.colores.take(Ajustes.maxColoresPorDibujo).toList();
  }

  static List<ColorConNombre> _buscar(List<String> nombres) {
    final lista = <ColorConNombre>[];
    for (final nombre in nombres) {
      final buscado = _normalizar(nombre);
      for (final c in Ajustes.colores) {
        if (_normalizar(c.nombre) == buscado && !lista.contains(c)) {
          lista.add(c);
          break;
        }
      }
      if (lista.length >= Ajustes.maxColoresPorDibujo) break;
    }
    return lista;
  }

  /// "Marrón" = "marron" = "MARRON".
  static String _normalizar(String texto) {
    const conTilde = 'áéíóúü';
    const sinTilde = 'aeiouu';
    final minusculas = texto.trim().toLowerCase();
    final salida = StringBuffer();
    for (final letra in minusculas.split('')) {
      final i = conTilde.indexOf(letra);
      salida.write(i >= 0 ? sinTilde[i] : letra);
    }
    return salida.toString();
  }

  // ------------------------------------------------------------ modo 1

  /// true si a [nombre] ya se le recomendó cambiar en este dibujo.
  bool recomendado(String nombre) => _recomendados.contains(nombre);

  void marcarRecomendado(String nombre) {
    if (_recomendados.add(nombre)) _marcarCambio();
  }

  // ------------------------------------------------------------ modo 2

  /// El color del personaje (null si todavía no se pintó).
  String? get colorPersonaje => _colorPersonaje;

  void fijarColorPersonaje(String nombre) {
    if (_colorPersonaje == nombre) return;
    _colorPersonaje = nombre;
    _marcarCambio();
  }

  /// true si [nombre] se usó fuera del personaje.
  bool usadoEnResto(String nombre) => _coloresResto.contains(nombre);

  void usarEnResto(String nombre) {
    if (_coloresResto.add(nombre)) _marcarCambio();
  }

  /// true si ya se avisó que el personaje está terminado.
  bool get personajeTerminado => _personajeTerminado;

  void marcarPersonajeTerminado() {
    if (_personajeTerminado) return;
    _personajeTerminado = true;
    _marcarCambio();
  }

  // ------------------------------------------------------------ celebración

  /// true si ya salió la celebración de este dibujo.
  bool get celebrado => _celebrado;

  /// Anota que ya salió la celebración (para que no se repita).
  void marcarCelebrado() {
    if (_celebrado) return;
    _celebrado = true;
    _marcarCambio();
  }

  // ------------------------------------------------- memoria y guardado

  /// La paleta de [id] si ya se leyó (si no, null).
  static PaletaDibujo? enMemoria(String id) => _memoria[id];

  /// Lee la paleta guardada de [id] (como nueva si nunca se pintó).
  static Future<PaletaDibujo> cargar(String id) async {
    final hay = _memoria[id];
    if (hay != null) return hay;
    final nueva = PaletaDibujo._(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString('$_prefijo$id');
      if (texto != null) nueva._leer(texto);
    } catch (_) {
      // Si no se pudo leer, se empieza como nueva.
    }
    // Mientras se leía pudo leerse o borrarse otra vez: gana la que ya está.
    return _memoria.putIfAbsent(id, () => nueva);
  }

  /// Lee de una vez las paletas de todos estos dibujos (al abrir la app),
  /// así al entrar a un dibujo la paleta ya está lista.
  static Future<void> cargarVarias(Iterable<String> ids) async {
    try {
      await Future.wait(ids.map(cargar));
    } catch (_) {}
  }

  /// Deja la paleta de [id] como nueva y borra lo guardado
  /// (se llama al borrar lo pintado).
  static void olvidar(String id) {
    final vieja = _memoria[id];
    if (vieja != null) _sinGuardar.remove(vieja);
    _memoria[id] = PaletaDibujo._(id);
    _quitarGuardada(id);
  }

  static Future<void> _quitarGuardada(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefijo$id');
    } catch (_) {}
  }

  void _marcarCambio() {
    _sinGuardar.add(this);
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 2), guardarPendientes);
  }

  /// Guarda ya mismo las paletas que cambiaron.
  static Future<void> guardarPendientes() async {
    _temporizador?.cancel();
    _temporizador = null;
    if (_sinGuardar.isEmpty) return;
    final lista = _sinGuardar.toList();
    _sinGuardar.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final paleta in lista) {
        // Si se borró lo pintado mientras tanto, ya no se guarda.
        if (!identical(_memoria[paleta.id], paleta)) continue;
        await prefs.setString('$_prefijo${paleta.id}', paleta._aTexto());
      }
    } catch (_) {
      // Si no se pudo guardar, se reintenta con el próximo cambio.
    }
  }

  String _aTexto() => jsonEncode(<String, Object>{
        'recomendados': _recomendados.toList(),
        if (_colorPersonaje != null) 'colorPersonaje': _colorPersonaje!,
        'coloresResto': _coloresResto.toList(),
        if (_personajeTerminado) 'personajeTerminado': true,
        if (_celebrado) 'celebrado': true,
      });

  /// Lee lo guardado. Lo de versiones anteriores (cuánto se gastó cada color)
  /// ya no se usa: los colores ya no se acaban.
  void _leer(String texto) {
    try {
      final datos = jsonDecode(texto);
      if (datos is! Map) return;
      _leerLista(datos['recomendados'], _recomendados);
      final personaje = datos['colorPersonaje'];
      if (personaje is String) _colorPersonaje = personaje;
      _leerLista(datos['coloresResto'], _coloresResto);
      _personajeTerminado = datos['personajeTerminado'] == true;
      _celebrado = datos['celebrado'] == true;
    } catch (_) {
      // Datos dañados: se empieza como nueva.
      _recomendados.clear();
      _colorPersonaje = null;
      _coloresResto.clear();
      _personajeTerminado = false;
      _celebrado = false;
    }
  }

  static void _leerLista(Object? lista, Set<String> destino) {
    if (lista is! List) return;
    for (final nombre in lista) {
      if (nombre is String) destino.add(nombre);
    }
  }
}
