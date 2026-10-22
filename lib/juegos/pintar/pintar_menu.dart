import 'package:flutter/material.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/comun/botones.dart';
import 'package:colorear_ninos/comun/titulo_colores.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/lienzo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:colorear_ninos/juegos/pintar/partes/repositorio.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_pantalla.dart';

/// El juego Pintar empieza aquí: una cuadrícula con todos los dibujos.
/// Tocar uno lo abre para pintar (pintar_pantalla.dart).
/// Arriba: la casita (vuelve al menú de juegos) y la escoba (borra lo
/// pintado de todos los dibujos, preguntando antes).
class PintarMenu extends StatefulWidget {
  const PintarMenu({super.key});

  @override
  State<PintarMenu> createState() => _EstadoPintarMenu();
}

class _EstadoPintarMenu extends State<PintarMenu> {
  static const List<Color> _bordes = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF7CB342),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  final ScrollController _scroll = ScrollController();
  List<Dibujo> _dibujos = <Dibujo>[];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final lista = await Repositorio.cargarTodos();
      // Lo que se pintó antes (aunque la app se haya cerrado) y la paleta
      // de cada dibujo.
      await Pintura.cargar(lista);
      await PaletaDibujo.cargarVarias(lista.map((d) => d.id));
      await ModoPintado.cargar();
      if (!mounted) return;
      setState(() {
        _dibujos = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No pude cargar los dibujos: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirDibujo(int indice) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PintarPantalla(dibujos: _dibujos, indice: indice),
      ),
    );
    // Al volver, se refrescan las miniaturas para mostrar lo pintado.
    if (mounted) setState(() {});
  }

  /// Deja en blanco todos los dibujos y sus paletas completas (pregunta antes).
  Future<void> _borrarTodo() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar lo pintado de TODOS los dibujos?'),
        content: const Text('Todos los dibujos quedarán en blanco otra vez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Sí, borrar todo'),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;
    Pintura.borrarTodos(_dibujos);
    setState(() {});
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error, textAlign: TextAlign.center),
        ),
      );
    }
    // Con muchos dibujos el menú se desliza hacia arriba/abajo con el dedo.
    // La barra de la derecha le muestra a quien mira en qué parte de la lista va.
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(8),
      child: GridView.builder(
        controller: _scroll,
        cacheExtent: 800,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: _dibujos.length,
        itemBuilder: (context, i) => _Tarjeta(
          dibujo: _dibujos[i],
          borde: _bordes[i % _bordes.length],
          alTocar: () => _abrirDibujo(i),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AjustesApp.fondoApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Casita: vuelve al menú de juegos.
                  BotonGrande(
                    icono: Icons.home_rounded,
                    color: const Color(0xFF1E88E5),
                    tamano: 54,
                    alTocar: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TituloColores(AjustesPintar.tituloMenu),
                  ),
                  const SizedBox(width: 12),
                  // Escoba: borra lo pintado de todos los dibujos.
                  BotonGrande(
                    icono: Icons.cleaning_services_rounded,
                    color: const Color(0xFFFB8C00),
                    tamano: 54,
                    alTocar: _borrarTodo,
                  ),
                ],
              ),
            ),
            Expanded(child: _contenido()),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.dibujo,
    required this.borde,
    required this.alTocar,
  });

  final Dibujo dibujo;
  final Color borde;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    // Las líneas de la miniatura se preparan una sola vez (quedan guardadas).
    Pintura.lineasMiniatura(dibujo);
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: alTocar,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borde, width: 6),
          ),
          padding: const EdgeInsets.all(10),
          child: CustomPaint(
            painter: MiniaturaPainter(dibujo),
          ),
        ),
      ),
    );
  }
}
