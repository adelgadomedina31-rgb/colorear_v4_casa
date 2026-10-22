# 🐶 Juego: Animales (sonidos de animales)

Aprende los **animales y cómo hacen**.

## Cómo se juega

1. Aparecen animales en tarjetas grandes (2 al empezar) y la voz pregunta: **"¿Quién hace guau guau?"**.
   Si pusiste el sonido de verdad del perro (ver "Sonidos de verdad"), la voz dice **"¿Quién hace así?"** y
   después suena el perro.
2. **Si toca el correcto:** la tarjeta salta y se pone verde, salen estrellitas, gana una **estrella** y la voz la
   felicita: **"¡Muy bien! ¡Es el perro! ¡guau guau!"**. Después viene otra pregunta, por otro animal.
3. **Si toca otro:** la tarjeta se mueve, suena un "boing" suave y la voz le dice cuál es y cómo hace:
   **"¡Ese es el gato! ¡miau miau!"**. Así también aprende. Si se equivoca **2 veces** en la misma ronda, el
   correcto **brilla** en amarillo.
4. **Dificultad sola:** si acierta 3 seguidas sin equivocarse, aparece un animal más (hasta 4). Si en una ronda se
   equivoca 2 veces, hay uno menos (nunca menos de 2).
5. Cada **5 aciertos** sale la celebración grande: **"¡MUY BIEN! CONOCES LOS ANIMALES"**.

Arriba: la **casita** vuelve al menú, en el medio están las **estrellas** y la **orejita** repite la pregunta.

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `animales_ajustes.dart` ⭐ | La **lista de animales** y todo lo que se puede cambiar (tabla de abajo) |
| `animales_juego.dart` | El juego, en tres partes: **1. cada ronda** (elige los animales y por cuál preguntar), **2. cuando toca** (acierto, error, celebración) y **3. cómo se ve** (el pasto, las tarjetas y sus movimientos) |

## La lista de animales

Está en `animales_ajustes.dart`, en `animales`. Cada línea es un animal:

```dart
Animal('perro', 'el perro', '🐶', 'guau guau'),
```

En orden:
1. `'perro'`: nombre corto, sin tildes ni espacios. Es el nombre de su archivo de sonido.
2. `'el perro'`: cómo lo nombra la voz, con su artículo.
3. `'🐶'`: su dibujo (un emoji). Para cambiarlo, copia otro emoji y pégalo entre las comillas.
4. `'guau guau'`: cómo hace, dicho por la voz.

- **Quitar un animal:** borra su línea.
- **Agregar uno:** copia una línea, pégala debajo y cambia sus cuatro datos. Por ejemplo:
  `Animal('leon', 'el león', '🦁', 'grrr'),` (no olvides la coma del final).

Vienen: perro, gato, vaca, cerdito, pollito, pato, oveja, gallo, rana y búho.

## Qué más cambiar (en `animales_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Cuántos animales al empezar y como máximo | `animalesAlEmpezar`, `animalesMaximo` |
| Que suba de dificultad más rápido o más lento | `aciertosParaSubir` |
| Que baje de dificultad más fácil | `erroresParaBajar` |
| Que la ayuda (el brillo) salga antes o después | `erroresParaAyuda` |
| La pregunta | `vozPregunta` (`{sonido}` se cambia por "guau guau") |
| La pregunta cuando hay sonido de verdad | `vozPreguntaConSonido` |
| Lo que dice al acertar | `vozAcierto` (dice una al azar; `{animal}` = "el perro") |
| Lo que dice al equivocarse | `vozError` |
| Cada cuántos aciertos sale la celebración | `aciertosParaCelebrar` |
| El cartel y la voz de la celebración | `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |
| Más o menos tiempo entre una pregunta y la otra | `pausaSiguienteRonda` (milisegundos) |

Cosas que están en otro archivo:
- **El color de fondo (el pasto):** en `animales_juego.dart`, busca `// El pasto.`.
- **Los colores de los bordes de las tarjetas:** en `animales_juego.dart`, busca `_bordes`.
- **El volumen y apagar los sonidos o la voz:** `lib/app/ajustes_app.dart`.

## Sonidos de verdad (opcional)

Ahora la voz **dice** cómo hace cada animal ("guau guau"). Si quieres que se escuche el **sonido de verdad**:

1. Consigue el sonido (por ejemplo, de una página de sonidos gratis, o grábalo).
2. Ponle el **nombre corto** del animal: `perro.mp3`, `gato.wav`, `vaca.m4a`... (sirven .mp3, .m4a, .wav, .ogg).
3. Ponlo en la carpeta `assets/sonidos/animales/`.
4. `git add .`, `git commit`, `git push`.

Los animales que tengan archivo usan el sonido de verdad; los demás siguen con la voz. Conviene que el sonido
dure poco (1 a 3 segundos).
