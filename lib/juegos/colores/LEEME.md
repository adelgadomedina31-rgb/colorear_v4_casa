# 🎈 Juego: Colores (encuentra el color)

Aprende los **nombres de los colores** reventando globos.

## Cómo se juega

1. Aparecen globos de colores que flotan (2 al empezar) y la voz pide uno: **"¡Toca el globo rojo!"**.
2. **Si toca el correcto:** el globo revienta con estrellitas, suena el "¡pop!" y una campanita, gana una
   **estrella** y la voz la felicita ("¡Muy bien! ¡Es el rojo!"). Después viene otra ronda con otro color.
3. **Si toca otro:** ese globo se mueve, suena un "boing" suave y la voz le dice qué color tocó:
   **"Ese es el azul. ¡Busca el rojo!"**. Si se equivoca **2 veces** en la misma ronda, el globo correcto **brilla**
   en amarillo para ayudarla.
4. **Dificultad sola:** si acierta 3 rondas seguidas sin equivocarse, aparece un globo más (hasta 4). Si en una
   ronda se equivoca 2 veces, hay un globo menos (nunca menos de 2).
5. Cada **5 globos** reventados sale la celebración grande: **"¡MUY BIEN! CONOCES LOS COLORES"**.

Arriba: la **casita** vuelve al menú, en el medio están las **estrellas** ganadas y la **orejita** repite qué
globo buscar.

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `colores_ajustes.dart` ⭐ | Todo lo que se puede cambiar (tabla de abajo) |
| `colores_juego.dart` | El juego, en tres partes: **1. cada ronda** (elige los globos y cuál pedir), **2. cuando toca** (acierto, error, celebración) y **3. cómo se ve** (el cielo, los globos y sus movimientos) |
| `globo.dart` | Cómo se dibuja un globo (cuerpo, brillo, nudito, hilo y el resplandor de ayuda) |

## Qué cambiar (todo en `colores_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Qué colores salen en los globos | `colores` (con los nombres de la lista de colores de `lib/app/ajustes_app.dart`) |
| Cuántos globos al empezar y como máximo | `globosAlEmpezar`, `globosMaximo` |
| Que suba de dificultad más rápido o más lento | `aciertosParaSubir` |
| Que baje de dificultad más fácil | `erroresParaBajar` |
| Que la ayuda (el brillo) salga antes o después | `erroresParaAyuda` |
| Lo que pide la voz | `vozBusca` (`{color}` se cambia por el color) |
| Lo que dice al acertar | `vozAcierto` (dice una al azar; puedes agregar más frases a la lista) |
| Lo que dice al equivocarse | `vozError` (`{otro}` = el que tocó, `{color}` = el que hay que buscar) |
| Cada cuántos globos sale la celebración | `aciertosParaCelebrar` |
| El cartel y la voz de la celebración | `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |
| Más o menos tiempo entre una ronda y la otra | `pausaSiguienteRonda` (milisegundos: 1000 = 1 segundo) |
| Usar otros sonidos | `sonidoReventar`, `sonidoError` |

Cosas que están en otro archivo:
- **Cómo se ve el globo** (forma, brillo, hilo): `globo.dart`.
- **El color de fondo (el cielo):** en `colores_juego.dart`, busca `// El cielo.`; los dos colores están en `colors:`.
- **Cuánto flotan los globos:** en `colores_juego.dart`, busca `// Sube y baja` (el `10` es cuánto suben y bajan).
- **El volumen y apagar los sonidos o la voz:** `lib/app/ajustes_app.dart`.

## Sonidos

- `assets/sonidos/colores/reventar.wav`: el globo que revienta.
- `assets/sonidos/comunes/boing.wav`: cuando toca el que no era.
- `assets/sonidos/comunes/acierto.wav`: la campanita del acierto.
- `assets/sonidos/comunes/felicidades.wav`: la fiesta de la celebración.

Para cambiar uno, pon otro archivo con el **mismo nombre** en la misma carpeta.

## Voces grabadas (opcional)

Si en `assets/voces/` pones `toca_el_globo.m4a` ("¡Toca el globo...!") **y** las grabaciones de los colores
(`rojo.m4a`, `azul.m4a`...), se escuchan tus grabaciones en vez de la voz del celular cuando pide un globo.
Ver `assets/voces/LEEME.txt`.
