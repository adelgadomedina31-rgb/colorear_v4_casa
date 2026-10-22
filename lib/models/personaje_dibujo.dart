import 'dart:ui';

import '../config.dart';
import 'dibujo.dart';

/// El personaje de un dibujo (para el "Modo 2 - Pintado por objeto"): cómo
/// se llama y cuáles de sus zonas son suyas. Todo el personaje se pinta de un
/// solo color; el resto (fondo y detalles) se pinta con otros.
///
/// De dónde sale, en este orden:
///  1. [Ajustes.personajes] en config.dart (los dibujos de la app).
///  2. El campo "personaje" del JSON del dibujo.
///  3. Si no hay, se busca solo: el personaje es lo que no toca los bordes
///     del dibujo (lo que toca los bordes es el fondo: el cielo, el pasto, el
///     blanco de alrededor de una imagen...), sin los detalles que quedan
///     adentro de una zona más grande (un ojo, una mancha, una ventana).
class PersonajeDibujo {
  const PersonajeDibujo(this.nombre, this.zonas);

  /// Cómo lo nombra la voz: "el pez".
  final String nombre;

  /// Las zonas del personaje (su número en la lista de zonas del dibujo).
  final Set<int> zonas;

  /// false si el dibujo no tiene un personaje (por ejemplo, una sola zona):
  /// entonces se pinta libre.
  bool get existe => zonas.isNotEmpty;

  bool contiene(int zona) => zonas.contains(zona);

  static final Expando<PersonajeDibujo> _hechos = Expando<PersonajeDibujo>();

  /// El personaje de [d] (se calcula una sola vez por dibujo).
  static PersonajeDibujo de(Dibujo d) => _hechos[d] ??= _buscar(d);

  static PersonajeDibujo _buscar(Dibujo d) {
    for (final definido in <Personaje?>[
      Ajustes.personajes[d.id],
      d.personaje
    ]) {
      if (definido == null) continue;
      final zonas = <int>{
        for (var i = 0; i < d.regiones.length; i++)
          if (definido.partes.contains(d.regiones[i].id)) i,
      };
      if (zonas.isNotEmpty) return PersonajeDibujo(definido.nombre, zonas);
    }
    return PersonajeDibujo(Ajustes.personajeSinNombre, _adivinar(d));
  }

  /// Sin personaje definido, se busca solo:
  ///  - lo que toca los bordes del dibujo es el fondo (si todo los toca, o
  ///    nada, el fondo es la zona más grande);
  ///  - lo que queda adentro de otra zona más grande (un ojo, una mancha,
  ///    una ventana) es un detalle, y se pinta como el fondo;
  ///  - lo demás es el personaje.
  static Set<int> _adivinar(Dibujo d) {
    final n = d.regiones.length;
    if (n < 2) return <int>{};
    final margen = d.lado * 0.02;
    final cuadro =
        Rect.fromLTWH(margen, margen, d.lado - 2 * margen, d.lado - 2 * margen);
    final cajas = <Rect>[for (var i = 0; i < n; i++) d.limites(i)];
    var fondo = <int>{
      for (var i = 0; i < n; i++)
        if (!_dentro(cajas[i], cuadro)) i,
    };
    if (fondo.isEmpty || fondo.length == n) {
      var mayor = 0;
      for (var i = 1; i < n; i++) {
        if (d.areaVisible(i) > d.areaVisible(mayor)) mayor = i;
      }
      fondo = <int>{mayor};
    }
    final resto = <int>[
      for (var i = 0; i < n; i++)
        if (!fondo.contains(i)) i,
    ];
    return <int>{
      for (final i in resto)
        if (!resto.any((j) => _encierra(cajas[j], cajas[i]))) i,
    };
  }

  /// true si la caja [grande] es más grande que [chica] y la tiene adentro.
  static bool _encierra(Rect grande, Rect chica) =>
      grande.width * grande.height > chica.width * chica.height &&
      grande.left <= chica.left &&
      grande.top <= chica.top &&
      grande.right >= chica.right &&
      grande.bottom >= chica.bottom;

  static bool _dentro(Rect caja, Rect cuadro) =>
      caja.left > cuadro.left &&
      caja.top > cuadro.top &&
      caja.right < cuadro.right &&
      caja.bottom < cuadro.bottom;
}
