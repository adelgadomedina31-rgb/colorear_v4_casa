import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/app/lista_juegos.dart';
import 'package:colorear_ninos/app/pantalla_ajustes.dart';
import 'package:colorear_ninos/comun/botones.dart';
import 'package:colorear_ninos/comun/titulo_colores.dart';
import 'package:colorear_ninos/comun/voz.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';

/// El menú principal: una tarjeta grande por juego (los de
/// lista_juegos.dart). Al tocar una, la tarjeta salta, la voz dice el nombre
/// del juego y el juego empieza.
///
/// Arriba: el botón rojo apaga la app y el engranaje abre los Ajustes
/// (zona de papás).
class MenuJuegos extends StatefulWidget {
  const MenuJuegos({super.key});

  @override
  State<MenuJuegos> createState() => _EstadoMenuJuegos();
}

class _EstadoMenuJuegos extends State<MenuJuegos> {
  Set<String> _ocultos = <String>{};
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    _cargarOcultos();
  }

  Future<void> _cargarOcultos() async {
    final ocultos = await JuegosOcultos.cargar();
    if (mounted) setState(() => _ocultos = ocultos);
  }

  List<Juego> get _visibles => <Juego>[
        for (final juego in listaJuegos)
          if (!_ocultos.contains(juego.id)) juego,
      ];

  Future<void> _abrir(Juego juego) async {
    if (_abriendo) return;
    _abriendo = true;
    // La voz dice el nombre del juego (sin esperar más de un momento).
    if (AjustesApp.decirNombreDelJuego) {
      await Future.wait(<Future<void>>[
        // Si en assets/voces/ está la grabación (por ejemplo "a_pintar.m4a"
        // para "¡A pintar!"), se escucha esa.
        Voz.decir(juego.voz, grabaciones: <String>[Voz.clave(juego.voz)])
            .timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () {},
        ),
        Future<void>.delayed(const Duration(milliseconds: 400)),
      ]);
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => juego.abrir()),
    );
    _abriendo = false;
  }

  Future<void> _abrirAjustes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PantallaAjustes()),
    );
    if (mounted) _cargarOcultos();
  }

  /// Cierra la app y vuelve a la pantalla principal del celular.
  Future<void> _salir() async {
    try {
      // Por si quedó algo sin guardar en Pintar (como mucho 2 segundos).
      await Future.wait(<Future<void>>[
        Pintura.guardarPendientes(),
        PaletaDibujo.guardarPendientes(),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {}
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final juegos = _visibles;
    return Scaffold(
      backgroundColor: AjustesApp.fondoApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
              child: Row(
                children: [
                  // Apagar: cierra la app (sin preguntar).
                  BotonGrande(
                    icono: Icons.power_settings_new_rounded,
                    color: const Color(0xFFE53935),
                    tamano: 50,
                    alTocar: _salir,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TituloColores(AjustesApp.tituloMenu, tamano: 36),
                  ),
                  // Ajustes (zona de papás).
                  GestureDetector(
                    key: const ValueKey<String>('engranaje'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _abrirAjustes,
                    onLongPress: _abrirAjustes,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        Icons.settings_rounded,
                        size: 30,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: juegos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay juegos a la vista.\n'
                          'Actívalos en el engranaje (Ajustes).',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: juegos.length,
                      itemBuilder: (context, i) => _TarjetaJuego(
                        juego: juegos[i],
                        alTocar: () => _abrir(juegos[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una tarjeta grande del menú: el dibujo del juego y su nombre.
/// Al tocarla da un saltito.
class _TarjetaJuego extends StatefulWidget {
  const _TarjetaJuego({required this.juego, required this.alTocar});

  final Juego juego;
  final VoidCallback alTocar;

  @override
  State<_TarjetaJuego> createState() => _EstadoTarjetaJuego();
}

class _EstadoTarjetaJuego extends State<_TarjetaJuego>
    with SingleTickerProviderStateMixin {
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _salto.dispose();
    super.dispose();
  }

  void _tocar() {
    _salto.forward(from: 0);
    widget.alTocar();
  }

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    return AnimatedBuilder(
      animation: _salto,
      builder: (context, hijo) {
        final t = _salto.value;
        final escala = 1 + 0.08 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Transform.scale(scale: escala, child: hijo);
      },
      child: Material(
        key: ValueKey<String>('juego_${juego.id}'),
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _tocar,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: juego.color, width: 7),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white,
                  juego.color.withValues(alpha: 0.18),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              children: [
                Expanded(
                  child: juego.dibujoPintado != null
                      ? Center(child: juego.dibujoPintado!())
                      : FittedBox(
                          child: Text(
                            juego.dibujo,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    juego.nombre.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: juego.color,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Los juegos que los papás ocultaron del menú (en Ajustes). Se guardan en
/// el celular, así que se recuerdan aunque se cierre la app.
class JuegosOcultos {
  JuegosOcultos._();

  static const String _clave = 'juegos_ocultos';

  static Future<Set<String>> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_clave) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> cambiar(String id, {required bool oculto}) async {
    final prefs = await SharedPreferences.getInstance();
    final ocultos = (prefs.getStringList(_clave) ?? const <String>[]).toSet();
    if (oculto) {
      ocultos.add(id);
    } else {
      ocultos.remove(id);
    }
    await prefs.setStringList(_clave, ocultos.toList()..sort());
  }
}
