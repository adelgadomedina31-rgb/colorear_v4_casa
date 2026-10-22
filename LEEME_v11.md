# ARVI v11: casas, celebración al 100% y 2 juegos nuevos

## Qué trae

- **Pintar: 5 casas nuevas** al final del menú de dibujos: casa del árbol, iglú, castillo, casa hongo y casita del
  perro (cada una con sus 5 colores y su personaje). Si ya las habías pegado desde el engranaje, no salen repetidas.
- **Pintar: la celebración sale al pintar el 100% del dibujo** (todas las partes). Los puntitos tan chiquitos que
  no se ven (en las esquinas, pegados a las líneas negras) no cuentan, y al celebrar se rellenan solos con el color
  de su parte. Así nunca se queda "trabado" sin celebrar.
- **Juego nuevo: 🫧 Burbujas.** Salen burbujas de a poco por los cuatro lados y flotan por toda la pantalla, cada una
  a su velocidad, cambiando de dirección y rebotando. Con un toque revientan con "¡POP!", gotitas, papelitos y
  estrellitas. Hay que reventarlas todas para pasar de nivel (6 niveles: más burbujas, más rápidas y que giran
  más). Desde el nivel 3 salen **súper burbujas** doradas que hay que tocar varias veces. Arriba se ve cuántas
  faltan.
- **Juego nuevo: 🍎 ¿Cuántos hay?** Aparecen cosas (manzanas, pollitos, peces...). Las toca una por una y la voz
  cuenta "uno, dos, tres". Después elige el número correcto (cada botón tiene puntitos para ayudarla). Si se
  equivoca, la voz cuenta con ella otra vez. Empieza hasta 3 y llega hasta 5.

## Cómo copiarla (esta vez es distinto: NO borres nada)

Este zip trae **solo los archivos nuevos y los que cambiaron**. Tus archivos de ajustes **no vienen**, para no
pisar tus cambios (tu frase "¡Arleth elije otro color...", el búho que quitaste, tus textos de celebración y de la
presentación):

- `lib/app/ajustes_app.dart`
- `lib/juegos/pintar/pintar_ajustes.dart`
- `lib/juegos/colores/colores_ajustes.dart`
- `lib/juegos/animales/animales_ajustes.dart`

Pasos:

1. **No borres ninguna carpeta.** Descomprime el zip y copia la carpeta `colorear_ninos` encima de tu proyecto.
   Cuando Windows pregunte, elige **Reemplazar**.
2. **Un cambio a mano** (para la celebración al 100%): abre `lib/juegos/pintar/pintar_ajustes.dart`, busca
   (Ctrl+F) `porcentajeCelebracion` y cambia `0.95` por `1.0`:

   ```dart
   static const double porcentajeCelebracion = 1.0;
   ```

   Guarda (Ctrl+S). Si no lo cambias, todo funciona igual pero la celebración sigue saliendo al 95%.
3. En la Terminal de VS Code:

   ```
   git add .
   git commit -m "Version 11: casas, celebracion al 100%, Burbujas y Cuantos hay"
   git push
   ```

4. En GitHub, pestaña **Actions**, espera el check verde y descarga el APK.

`lib/app/lista_juegos.dart` y `lib/app/menu_juegos.dart` vienen nuevos (traen las 2 tarjetas nuevas). Si les
habías cambiado algo (el orden o el color de una tarjeta), vuelve a hacerlo después de copiar.

Para cambiar cosas de los juegos nuevos: `lib/juegos/burbujas/burbujas_ajustes.dart` y
`lib/juegos/contar/contar_ajustes.dart` (cada uno con su `LEEME.md` en la misma carpeta).

## Para la próxima vez

Mándame la **carpeta del proyecto** comprimida (`colorear_ninos`, sin la carpeta `build`) en vez del APK. Del APK
no se puede sacar el código, así que esta vez tuve que deducir tus cambios y dejar tus archivos de ajustes fuera
del zip.

## Archivos del zip

Nuevos:
- `lib/juegos/burbujas/` (burbujas_ajustes.dart, burbujas_juego.dart, burbuja.dart, LEEME.md)
- `lib/juegos/contar/` (contar_ajustes.dart, contar_juego.dart, LEEME.md)
- `assets/drawings/`: casa_arbol.json, iglu.json, castillo.json, casa_hongo.json, casa_perro.json
- `assets/sonidos/burbujas/` y `assets/sonidos/contar/`
- `tools/dibujos_casas.py` y pruebas nuevas en `test/`

Cambiados:
- `pubspec.yaml` (versión 11 y las carpetas de sonidos nuevas)
- `assets/drawings/indice.json` (las 5 casas en el menú)
- `lib/app/lista_juegos.dart`, `lib/app/menu_juegos.dart` (las tarjetas nuevas)
- `lib/juegos/pintar/pintar_pantalla.dart`, `partes/pintura.dart`, `partes/paleta_dibujo.dart`,
  `partes/repositorio.dart`, `partes/lienzo.dart` (celebración al 100%, las casas, y un arreglo: si se borraba el
  dibujo justo al terminarlo, a veces la celebración quedaba marcada y no volvía a salir)
- `README.md`, `lib/LEEME.md`, `lib/juegos/pintar/LEEME.md`, `assets/sonidos/LEEME.txt`
- `tools/generar_dibujos.py`, `tools/generar_sonidos.py` y algunas pruebas de `test/`
