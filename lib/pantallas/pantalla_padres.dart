import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositorio.dart';
import '../models/dibujo.dart';
import '../models/modo_pintado.dart';

/// Ajustes (zona de papás), con el engranaje del menú:
///  - el modo de pintar (Modo 1 "Pintado total" o Modo 2 "Pintado por
///    objeto"), que vale para todos los dibujos;
///  - agregar dibujos nuevos pegando su texto (JSON) y borrar los que ya no
///    se quieren.
class PantallaPadres extends StatefulWidget {
  const PantallaPadres({super.key});

  @override
  State<PantallaPadres> createState() => _EstadoPadres();
}

class _EstadoPadres extends State<PantallaPadres> {
  final TextEditingController _controlador = TextEditingController();
  List<Dibujo> _importados = <Dibujo>[];
  String? _mensaje;
  bool _esError = false;
  int _modo = ModoPintado.actual;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _elegirModo(int modo) async {
    setState(() => _modo = modo);
    await ModoPintado.cambiar(modo);
  }

  Future<void> _recargar() async {
    final lista = await Repositorio.cargarImportados();
    if (!mounted) return;
    setState(() => _importados = lista);
  }

  Future<void> _pegar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final texto = datos?.text;
    if (texto == null || texto.trim().isEmpty) {
      setState(() {
        _mensaje = 'No hay nada copiado todavía.';
        _esError = true;
      });
      return;
    }
    setState(() {
      _controlador.text = texto;
      _mensaje = null;
    });
  }

  Future<void> _guardar() async {
    final texto = _controlador.text;
    if (texto.trim().isEmpty) {
      setState(() {
        _mensaje = 'Primero pega el texto del dibujo.';
        _esError = true;
      });
      return;
    }
    try {
      final dibujo = await Repositorio.importar(texto);
      if (!mounted) return;
      _controlador.clear();
      setState(() {
        _mensaje = 'Listo: "${dibujo.nombre}" ya está en el menú.';
        _esError = false;
      });
      await _recargar();
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensaje = e.message;
        _esError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensaje = 'No pude guardar ese dibujo. Revisa que esté completo.';
        _esError = true;
      });
    }
  }

  Future<void> _borrar(Dibujo dibujo) async {
    await Repositorio.borrarImportado(dibujo.id);
    if (!mounted) return;
    setState(() {
      _mensaje = 'Se borró "${dibujo.nombre}".';
      _esError = false;
    });
    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final mensaje = _mensaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Modo de pintar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('Vale para todos los dibujos.'),
          const SizedBox(height: 10),
          _TarjetaModo(
            numero: ModoPintado.total,
            titulo: 'Modo 1 - Pintado total',
            explicacion: 'Pinta libre, con los colores que quiera: los colores '
                'no se acaban. Si usa un mismo color en la mitad del dibujo, '
                'la voz le recomienda usar otro para que se vea más bonito.',
            icono: Icons.brush_rounded,
            color: const Color(0xFFFB8C00),
            elegido: _modo == ModoPintado.total,
            alTocar: () => _elegirModo(ModoPintado.total),
          ),
          const SizedBox(height: 10),
          _TarjetaModo(
            numero: ModoPintado.porObjeto,
            titulo: 'Modo 2 - Pintado por objeto',
            explicacion: 'El personaje del dibujo (el pez, el sol...) se pinta '
                'entero de un solo color, y ese color no sirve para el fondo. '
                'Cuando termina el personaje, la voz le pide elegir otro color '
                'para el fondo y los detalles (ahí puede usar varios).',
            icono: Icons.category_rounded,
            color: const Color(0xFF8E24AA),
            elegido: _modo == ModoPintado.porObjeto,
            alTocar: () => _elegirModo(ModoPintado.porObjeto),
          ),
          const SizedBox(height: 28),
          const Text(
            'Agregar un dibujo nuevo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Copia el texto completo del dibujo, toca "Pegar" y luego "Guardar". '
            'El dibujo aparece al final del menú.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controlador,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"id": "gato", "nombre": "Gato", ...}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pegar,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Pegar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          if (mensaje != null) ...[
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: TextStyle(
                color: _esError ? Colors.red.shade700 : Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Dibujos que agregaste',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (_importados.isEmpty)
            const Text('Todavía no has agregado ninguno.')
          else
            for (final dibujo in _importados)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dibujo.nombre),
                subtitle: Text(dibujo.id),
                trailing: IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _borrar(dibujo),
                ),
              ),
        ],
      ),
    );
  }
}

/// Una tarjeta grande para elegir un modo de pintar.
class _TarjetaModo extends StatelessWidget {
  const _TarjetaModo({
    required this.numero,
    required this.titulo,
    required this.explicacion,
    required this.icono,
    required this.color,
    required this.elegido,
    required this.alTocar,
  });

  final int numero;
  final String titulo;
  final String explicacion;
  final IconData icono;
  final Color color;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('modo_$numero'),
      color: elegido ? color.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: elegido ? color : Colors.black12,
              width: elegido ? 3 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color,
                child: Icon(icono, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(explicacion),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                elegido
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: elegido ? color : Colors.black26,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
