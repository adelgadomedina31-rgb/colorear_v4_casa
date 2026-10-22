# 🍎 Juego: ¿Cuántos hay? (contar)

Aprende a **contar** (del 1 al 5) tocando cada cosa mientras la voz cuenta.

## Cómo se juega

1. Aparecen unas cosas (manzanas, pollitos, estrellas, peces...) y la voz dice **"¡Cuenta las manzanas! Toca cada
   una."**.
2. **Al tocar cada una:** salta, suena una notita que va **subiendo** (do, re, mi...), la voz dice el número
   ("uno", "dos", "tres"), le queda puesto su número en un circulito de color y arriba se ve el número grande.
   Tocar otra vez una que ya contó no hace nada.
3. Cuando contó todas, la voz pregunta **"¿Cuántas manzanas hay?"** y abajo salen **3 botones** con números. Cada
   botón tiene también **puntitos** (el 3 tiene tres puntitos), para que pueda responder aunque todavía no conozca
   los números.
4. **Si acierta:** el botón se pinta, salen estrellitas, gana una **estrella** y la voz la felicita ("¡Sí! ¡Hay tres
   manzanas!"). Después viene otra ronda con otra cosa.
5. **Si toca otro número:** el botón se mueve, suena un "boing" suave y la voz dice **"Ese es el dos. ¡Contemos otra
   vez!"**. Entonces la voz **cuenta con ella** cada cosa (una por una, con su notita) y vuelve a preguntar. Si se
   equivoca 2 veces en la misma ronda, el botón correcto **brilla**.
6. **Dificultad sola:** empieza con hasta 3 cosas. Si acierta 3 rondas seguidas sin equivocarse, puede haber una
   más (hasta 5). Si en una ronda se equivoca 2 veces, vuelve a haber una menos.
7. Cada **5 aciertos** sale la celebración grande: **"¡MUY BIEN! SABES CONTAR"**.

Arriba: la **casita** vuelve al menú, en el medio están las **estrellas** ganadas y la **orejita** repite qué hacer
(mientras cuenta: "¡Cuenta las manzanas!"; mientras responde: "¿Cuántas manzanas hay?").

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `contar_ajustes.dart` ⭐ | Todo lo que se puede cambiar (tabla de abajo) |
| `contar_juego.dart` | El juego, en cuatro partes: **1. cada ronda** (qué cosa y cuántas), **2. contar**, **3. responder** (acierto, error, contar juntas, celebración) y **4. cómo se ve** |

## Qué cambiar (todo en `contar_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Agregar o quitar cosas para contar | `cosas` (cada una con su emoji, cómo se dice una y varias, y si es femenino: "las manzanas") |
| Hasta cuántas cosas al empezar y como máximo | `hastaAlEmpezar`, `hastaMaximo` (máximo 10) |
| Que suba de dificultad más rápido o más lento | `aciertosParaSubir` |
| Que baje de dificultad más fácil | `erroresParaBajar` |
| Cuántos botones con números | `botones` |
| Que la ayuda (el brillo) salga antes o después | `erroresParaAyuda` |
| Cómo dice los números al contar | `numeros` |
| Lo que dice la voz | `vozCuenta`, `vozPregunta`, `vozAcierto`, `vozError` (lo que va entre `{ }` se cambia solo: ver el comentario en el archivo) |
| Cada cuántos aciertos sale la celebración | `aciertosParaCelebrar` |
| El cartel y la voz de la celebración | `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |
| Más o menos tiempo entre una ronda y la otra | `pausaSiguienteRonda` (milisegundos: 1000 = 1 segundo) |

## Sonidos

- `assets/sonidos/contar/nota1.wav` ... `nota10.wav`: la notita al contar cada cosa (la 1, la 2...).
- `assets/sonidos/comunes/boing.wav`: cuando toca un número que no es.
- `assets/sonidos/comunes/acierto.wav` y `felicidades.wav`: el acierto y la celebración.

## Voces grabadas (opcional)

Si en `assets/voces/` pones `uno.m4a`, `dos.m4a`, `tres.m4a`... se escuchan tus grabaciones al contar, en vez de la
voz del celular. Ver `assets/voces/LEEME.txt`.
