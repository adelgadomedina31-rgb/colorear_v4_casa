import 'package:flutter/material.dart';

import 'package:colorear_ninos/app/lista_juegos.dart';
import 'package:colorear_ninos/app/menu_juegos.dart';

/// La pantalla de Ajustes (zona de papás), con el engranaje del menú:
///  1. "Juegos del menú": un interruptor por juego para mostrarlo u
///     ocultarlo del menú.
///  2. Después, la parte de cada juego que tenga algo para papás (por
///     ejemplo Pintar: el modo de pintar y agregar dibujos). Cada juego la
///     define en su carpeta y se conecta en lista_juegos.dart ("papas:").
class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _EstadoAjustes();
}

class _EstadoAjustes extends State<PantallaAjustes> {
  Set<String> _ocultos = <String>{};

  @override
  void initState() {
    super.initState();
    JuegosOcultos.cargar().then((ocultos) {
      if (mounted) setState(() => _ocultos = ocultos);
    });
  }

  Future<void> _mostrar(Juego juego, bool mostrar) async {
    setState(() {
      if (mostrar) {
        _ocultos.remove(juego.id);
      } else {
        _ocultos.add(juego.id);
      }
    });
    await JuegosOcultos.cambiar(juego.id, oculto: !mostrar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Juegos del menú',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Apaga los juegos que no quieras que aparezcan.'),
          const SizedBox(height: 6),
          for (final juego in listaJuegos)
            SwitchListTile(
              key: ValueKey<String>('mostrar_${juego.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${juego.dibujo}  ${juego.nombre}',
                style: const TextStyle(fontSize: 18),
              ),
              value: !_ocultos.contains(juego.id),
              onChanged: (mostrar) => _mostrar(juego, mostrar),
            ),
          for (final juego in listaJuegos)
            if (juego.papas != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '${juego.dibujo}  ${juego.nombre}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              juego.papas!(),
            ],
        ],
      ),
    );
  }
}
