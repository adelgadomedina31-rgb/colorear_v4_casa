import 'package:flutter/material.dart';

// =============================================================================
//  AJUSTES DE TODA LA APP
// =============================================================================
//
//  Lo que vale para TODOS los juegos: la presentación, el menú, la voz, el
//  volumen de la fiesta y la lista de colores con sus nombres.
//
//  Lo de cada juego está en su propia carpeta:
//    - Pintar ............ lib/juegos/pintar/pintar_ajustes.dart
//    - Colores ........... lib/juegos/colores/colores_ajustes.dart
//    - Animales .......... lib/juegos/animales/animales_ajustes.dart
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Por ejemplo, para que la presentación diga otra cosa:
//      static const String presentacionLinea1 = 'JUGUEMOS';
// =============================================================================

/// Un color y el nombre que dice la voz ("Rojo", "Azul"...).
class ColorConNombre {
  const ColorConNombre(this.color, this.nombre);

  final Color color;
  final String nombre;
}

class AjustesApp {
  AjustesApp._();

  // ------------------------------------------------------------ pantallas

  /// Color de fondo de las pantallas (crema clarito).
  static const Color fondoApp = Color(0xFFFFF4D6);

  // --------------------------------------------------------- presentación

  /// true = al abrir la app se muestra la presentación con estrellas.
  static const bool mostrarPresentacion = true;

  /// Lo que se ve en grande en la presentación (dos líneas).
  static const String presentacionLinea1 = 'JUGUEMOS';
  static const String presentacionLinea2 = 'ARLETH';

  // ----------------------------------------------------------------- menú

  /// El título de colores del menú de juegos.
  static const String tituloMenu = 'JUEGOS DE ARLETH';

  /// true = al tocar un juego del menú, la voz dice su nombre ("¡Pintar!").
  static const bool decirNombreDelJuego = true;

  // ------------------------------------------------------------------ voz

  /// true = la voz habla (nombres de colores, instrucciones, felicitaciones).
  static const bool vozActiva = true;

  /// Tono de la voz: 1.0 es normal. Subirlo mucho la hace sonar a robot;
  /// 1.1 la deja un poquito más dulce pero natural (máximo 2.0).
  static const double vozTono = 1.1;

  /// Velocidad de la voz: 0.5 es normal; más bajo = más lento y claro.
  static const double vozVelocidad = 0.45;

  /// true = si el celular tiene voces "de internet" (suenan más naturales),
  /// se usan. Solo conviene si el celular SIEMPRE tiene internet: sin
  /// internet esas voces pueden quedarse calladas.
  static const bool vozPermitirInternet = false;

  /// true = si en assets/voces/ hay grabaciones (por ejemplo "rojo.m4a"),
  /// se usan en vez de la voz del celular. Ver assets/voces/LEEME.txt.
  static const bool usarVocesGrabadas = true;

  // -------------------------------------------------------------- sonidos

  /// true = suenan los efectos de los juegos (globos, aciertos...).
  static const bool sonidosJuegos = true;

  /// Volumen de los efectos de los juegos (0 a 1).
  static const double volumenJuegos = 0.9;

  /// true = suena una fiesta (campanitas y aplausos) en las celebraciones.
  static const bool sonidoCelebracion = true;

  /// Volumen de la fiesta (0 a 1).
  static const double volumenCelebracion = 0.9;

  // ---------------------------------------------------------- celebración

  /// Cuántos segundos se queda el cartel grande de "¡FELICIDADES!" con
  /// estrellas (también se quita tocándolo).
  static const int segundosCelebracion = 7;

  // -------------------------------------------------------------- colores

  /// Todos los colores que conoce la app, con el nombre que dice la voz.
  /// Los usan Pintar (cada dibujo elige algunos) y Colores (los globos).
  /// Si cambias un nombre aquí, cámbialo también donde se use por nombre
  /// (por ejemplo en las paletas de pintar_ajustes.dart).
  static const List<ColorConNombre> colores = <ColorConNombre>[
    ColorConNombre(Color(0xFFE53935), 'Rojo'),
    ColorConNombre(Color(0xFFFB8C00), 'Naranja'),
    ColorConNombre(Color(0xFFFDD835), 'Amarillo'),
    ColorConNombre(Color(0xFF7CB342), 'Verde'),
    ColorConNombre(Color(0xFF00ACC1), 'Celeste'),
    ColorConNombre(Color(0xFF1E88E5), 'Azul'),
    ColorConNombre(Color(0xFF8E24AA), 'Morado'),
    ColorConNombre(Color(0xFFEC407A), 'Rosado'),
    ColorConNombre(Color(0xFF8D6E63), 'Marrón'),
    ColorConNombre(Color(0xFF90A4AE), 'Gris'),
    ColorConNombre(Color(0xFF424242), 'Negro'),
  ];

  /// Busca un color de la lista [colores] por su nombre ("Rojo").
  /// Devuelve null si no existe.
  static ColorConNombre? colorLlamado(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    for (final c in colores) {
      if (c.nombre.toLowerCase() == buscado) return c;
    }
    return null;
  }
}
