# 🎨 Juego: Pintar

Elige un color abajo y pinta dibujos simples en blanco y negro tocando o arrastrando el dedo.

## Cómo se juega

- **El menú de dibujos** (`pintar_menu.dart`) muestra todos los dibujos con lo que ya se pintó, de dos en dos.
  Se desliza con el dedo. Arriba, la **casita** vuelve al menú de juegos y la **escoba** borra lo pintado de
  todos los dibujos (pregunta antes).
- **Al entrar a un dibujo** no hay ningún color elegido: la voz dice **"¡Elige un color!"** y los tarritos saltan
  hasta que ella elige uno. Al elegirlo, la voz dice su nombre ("¡Rojo!"). **Nunca se elige un color solo.**
- **Pintar con toques:** cada toque suena como una gota de pintura y deja una mancha que se derrama. Las zonas
  grandes necesitan varios toques; las pequeñas se llenan de un toque. Si arrastra el dedo, la pintura lo sigue
  con sonido de pincel. La pintura **nunca se sale de la zona** donde empezó el dedo.
- **Cada dibujo tiene sus colores** (como mucho 5) y los colores no se acaban.
- **Dos modos de pintar** (se eligen en el engranaje del menú de juegos):
  - **Modo 1 – Pintado total:** pinta libre. Si un mismo color cubre la mitad del dibujo, la voz dice
    "¡Usa otro color, para que se vea más bonito!" y el color se suelta para que elija otro.
  - **Modo 2 – Pintado por objeto:** el **personaje** del dibujo (el pez, el sol con sus rayos...) se pinta entero
    de un solo color, y ese color no sirve para el resto. Al terminar el personaje, la voz dice
    "¡Elige otro color para seguir pintando!".
- **Celebración:** cuando el dibujo está pintado **completo (100%)**, con cualquier color, sale el cartel
  **"¡FELICIDADES! LO PINTASTE MUY BIEN"** con estrellas, una fiesta y la voz. Sale una vez por dibujo (vuelve a salir
  si se borra y se pinta de nuevo). Los puntitos tan chiquitos que no se ven (en las esquinas, junto a las líneas
  negras) no cuentan, y al celebrar se rellenan solos con el color de su parte.
- Arriba, en la pantalla de pintar: **casita** (vuelve a los dibujos), **anterior**, **siguiente** y **borrar**
  (el rojo, deja el dibujo en blanco sin preguntar).
- Todo se **guarda solo** en el celular, aunque se cierre la app.

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `pintar_ajustes.dart` ⭐ | Todo lo que se puede afinar (tabla de abajo) |
| `pintar_menu.dart` | La cuadrícula de dibujos, la casita y la escoba |
| `pintar_pantalla.dart` | La pantalla de pintar: botones, dibujo, paleta, los dos modos y cuándo habla la voz |
| `pintar_papas.dart` | La parte de Pintar en Ajustes: el modo de pintar y agregar/borrar dibujos |
| `partes/lienzo.dart` | Cómo se pinta con el dedo (las manchas que se derraman) |
| `partes/paleta.dart` | Los tarritos de colores de abajo |
| `partes/pintura.dart` | Guardar lo pintado y medir cuánto se pintó de cada color |
| `partes/dibujo.dart` | El formato de los dibujos y cómo se leen |
| `partes/paleta_dibujo.dart` | Los colores de cada dibujo y lo que recuerda (color del personaje, celebración...) |
| `partes/personaje_dibujo.dart` | Cuál es el personaje de cada dibujo (Modo 2) |
| `partes/modo_pintado.dart` | El modo elegido (se guarda en el celular) |
| `partes/repositorio.dart` | De dónde se cargan los dibujos |
| `partes/sonidos_pintar.dart` | Las gotas y el pincel |

## Qué cambiar (todo en `pintar_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| El título de arriba ("COLOREA ARLETH") | `tituloMenu` |
| Que se necesiten más (o menos) toques | `toquesZonaChica` y `toquesZonaGrande` |
| Que más zonas se llenen de un toque | sube `areaUnToque` |
| Manchas más grandes o más chicas | `escalaMancha` (1.2 = 20% más grandes) |
| Derrame más lento o más rápido | `duracionDerrame` |
| Líneas negras más gruesas o más finas | `grosorContorno` |
| Quitar o bajar el sonido al pintar | `sonidoPintar`, `volumenPintar` (gota), `volumenTrazo` (pincel) |
| Que el pincel suene más o menos seguido | `distanciaEntreTrazos` |
| El modo que viene puesto (si nunca se eligió otro) | `modoPorDefecto` (1 o 2) |
| Cuándo se recomienda otro color en el Modo 1 | `parteParaRecomendar` (0.50 = la mitad del dibujo) |
| Que en el Modo 1 el color NO se suelte al recomendar otro | `soltarColorAlRecomendar = false` |
| Cuándo el personaje está terminado en el Modo 2 | `personajeTerminado` (0.97 = el 97% del personaje) |
| El personaje de cada dibujo (Modo 2) | `personajes` (sus partes son los `id` de las zonas) |
| Lo que dice la voz | `vozEligeUnColor`, `vozUsaOtroColor`, `vozEligeOtroParaSeguir`, `vozColorDelPersonaje`, `vozPintaPersonajeCon`, `vozOtroColorParaPersonaje` |
| Cuánto hay que pintar para la celebración | `porcentajeCelebracion` (1.0 = el 100%, todo; 0.95 = el 95%) |
| Lo que dice el cartel y la voz al terminar | `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |
| Los colores de cada dibujo | `paletasDibujos` |
| Los colores de los dibujos que no están en la lista | `paletaPorDefecto` |
| Cuántos colores como máximo por dibujo | `maxColoresPorDibujo` |

Lo que es igual para todos los juegos (la voz, la lista de colores con sus nombres, cuánto dura la celebración)
está en `lib/app/ajustes_app.dart`.

## Sonidos

En `assets/sonidos/pintar/`: `gota1.wav` a `gota5.wav` (al tocar) y `trazo1.wav` a `trazo4.wav` (al arrastrar).
La fiesta es `assets/sonidos/comunes/felicidades.wav`. Para cambiar uno, pon otro archivo con el mismo nombre.

## Agregar dibujos nuevos

### Forma 1 — tus propias imágenes (carpeta `mis_dibujos`)

1. Copia imágenes de **líneas negras sobre fondo blanco** (láminas para colorear, PNG o JPG) en la carpeta `mis_dibujos/`.
2. `git add .`, `git commit -m "Nuevos dibujos"`, `git push`.
3. Al compilar, GitHub convierte cada imagen en un dibujo (cada zona blanca cerrada por líneas se vuelve una zona)
   y lo pone **al principio** de los dibujos. El nombre del archivo es el nombre del dibujo.

**Sus colores:** junto a la imagen pon un archivo de texto con el mismo nombre (por ejemplo `gato feliz.txt` al lado
de `gato feliz.png`) con hasta 5 colores separados por comas: `Naranja, Rosado, Verde, Celeste, Amarillo`. Los
nombres posibles son los de la lista `colores` de `lib/app/ajustes_app.dart`. Sin archivo de texto, el dibujo usa
`paletaPorDefecto`.

**En el Modo 2:** el personaje de tus imágenes se busca solo: es lo que no toca los bordes de la imagen, menos los
detalles que quedan adentro de una zona más grande (los ojos, las manchas). Funciona mejor con un solo personaje
por imagen.

Consejos: figuras cerradas (sin huecos en las líneas), líneas gruesas y pocas zonas pequeñas.

### Forma 2 — desde el celular (uno por uno, sin compilar)

1. Copia el texto del dibujo (JSON) en el celular.
2. En la app toca el engranaje del menú de juegos.
3. En la parte de Pintar toca **Pegar** y luego **Guardar**. El dibujo aparece al final.

Los dibujos agregados así quedan guardados en el celular y se pueden borrar desde la misma pantalla.

### Forma 3 — "de fábrica" (muchos de una vez)

1. Copia el archivo `.json` del dibujo a `assets/drawings/`.
2. Abre `assets/drawings/indice.json` y agrega el nombre del archivo en la lista, entre comillas y separado por
   comas. El orden de la lista es el orden de los dibujos.
3. Sube los cambios (`git add .`, `git commit`, `git push`).

### Formato de un dibujo

```json
{
  "id": "sol",
  "nombre": "Sol",
  "lado": 1000,
  "regiones": [
    {"id": "cielo", "path": "M 10 70 L 990 70 ... Z"},
    {"id": "cara",  "path": "M 690 500 C ... Z"}
  ],
  "detalles": [
    {"path": "M ... Z", "relleno": "#000000"},
    {"path": "M 415 545 C 455 625 545 625 585 545", "grosor": 12}
  ],
  "colores": ["Amarillo", "Naranja", "Celeste", "Rojo", "Rosado"],
  "personaje": {"nombre": "el sol", "partes": ["cara", "rayo1", "rayo2"]}
}
```

- El dibujo es un cuadrado de `lado` x `lado` (1000 por defecto).
- `regiones` son las zonas que se pintan. Se dibujan en orden: las últimas quedan **encima** de las primeras.
  Cada región es un trazo SVG cerrado y tiene un `id` distinto.
- `detalles` son adornos que no se pintan: `relleno` (color `#RRGGBB`) para puntos como los ojos, `grosor` para
  líneas como las sonrisas. Es opcional.
- Un dibujo agregado no puede usar el mismo `id` que uno de fábrica.
- `colores` es opcional (hasta 5 nombres de la lista de colores). Si el `id` está en `paletasDibujos`, manda eso.
- `personaje` es opcional (Modo 2). También vale solo la lista: `"personaje": ["cara", "rayo1"]`. Si el `id` está
  en `personajes`, manda eso; si no hay ninguno, se busca solo.
