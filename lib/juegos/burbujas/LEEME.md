# 🫧 Juego: Burbujas (revienta las burbujas)

Motricidad fina y puntería: hay que **reventar todas las burbujas** que flotan por la pantalla.

## Cómo se juega

1. Al entrar, el juego **sigue en el nivel donde quedó** (queda guardado en el celular). Sale el cartel
   **"NIVEL 3"** (un segundo) y la voz dice qué hacer.
2. Cada nivel pasa en un **mundo distinto**, elegido al azar (nunca el mismo dos veces seguidas): el mundo nuevo
   aparece en un círculo que se abre desde abajo. Abajo, en el medio, está la **mascota** de ese mundo.
3. Las burbujas van saliendo **de a poco**: unas las **sopla la mascota** (salen chiquitas de su boca y crecen) y
   otras entran **por los lados**. Flotan por todas partes, cada una a **su propia velocidad**, cambiando de
   dirección de a poquito y **rebotando** en los bordes y entre ellas.
4. Las burbujas tienen **carita**: miran hacia donde van, **parpadean**, y **se ríen** cuando revienta una que está
   al lado o cuando las tocas sin reventarlas (súper, mega y jefes).
5. **Un toque y revientan** diciendo **"¡ay!"**: la carita pone ojitos "> <", sale un destello, gotitas, papelitos,
   estrellitas y la palabra **"¡AY!"**. Cada burbuja reventada da una **estrella**.
6. Arriba se ve cuántas lleva y cuántas faltan (una burbujita por cada burbuja del nivel; si son muchas, una barra).
7. Cuando revienta **todas**: la **mascota aplaude** 👏, un **festejo corto** (fuegos artificiales de burbujas,
   "¡MUY BIEN!") y el nivel siguiente empieza enseguida. **Cada 5 niveles**, la **celebración grande**
   "¡MUY BIEN! REVENTASTE TODAS".
8. Si toca a la **mascota** (donde no hay burbujas), **salta y se ríe**.

## Los mundos y sus mascotas

| Mundo | Cómo es | Mascota |
|---|---|---|
| ☀️ **Cielo** | Sol con carita, nubes que pasan, lomas con flores | 🐥 pollito o 🐶 perrito |
| 🌊 **Fondo del mar** | Peces que nadan, rayos de luz, algas, arena, cangrejo y burbujitas | 🐳 ballenita |
| 🌅 **Atardecer** | Sol grande que se esconde, nubes rosadas, pajaritos y lomas moradas | 🐱 gatito o 🐶 perrito |
| 🌙 **Noche** | Luna dormida, estrellas que brillan, luciérnagas y casitas | 🐱 gatito |
| 🚀 **Espacio** | Planetas, estrellas fugaces, un cohete y suelo de luna | 🐶 perrito astronauta (con casco) |

Al empezar cada nivel la voz dice a dónde van: "¡Nivel 4! ¡Al fondo del mar con la ballenita!" (si el nivel trae
una burbuja nueva o un jefe, dice eso en vez del mundo).

## Los niveles no se acaban

Cada nivel tiene un poquito más de burbujas, que van un poco más rápido y cambian más de dirección. Además:

- **Cada pocos niveles aparece un tipo de burbuja nuevo** (la voz lo presenta la primera vez), y desde que
  aparece, **cada 5 niveles** hay una más de ese tipo.
- **Niveles tranquilos al azar:** más o menos 3 de cada 10 niveles son como uno de 1 a 3 niveles antes. Así la
  dificultad sube "en escalera": siente que mejora, sin frustrarse.
- **Una sorpresa en cada nivel:** un tipo de burbuja (al azar) viene con más, para que ningún nivel sea igual.
- Nunca hay más de **24** burbujas para reventar en un nivel. Cuando ya se llega a ese número, los niveles
  siguientes cambian burbujas normales por especiales.

| Desde el nivel | Burbuja nueva | Cómo es |
|---|---|---|
| 1 | Normal | Un toque y revienta |
| 3 | ⭐ **Súper burbuja** | Grande y dorada, con una estrella en la frente. Hay que tocarla **3 veces** (con cada toque se achica y se ríe; los puntitos dicen cuántos faltan) |
| 5 | 🐥 **Animalito** | Una burbuja con un animalito adentro. Al reventarla, **el animalito sale volando** |
| 7 | 🟣 **Mega burbuja** | Enorme, con burbujitas que le dan vueltas. Con **2 toques explota** y salen **4 burbujitas** que también hay que reventar |
| 9 | ⚡ **Burbujitas rápidas** | Chiquitas, brillantes y muy rápidas, con una estela. Se atrapan aunque el dedo no caiga justo encima |

## Los niveles de jefe 👑

Desde el **nivel 4** (y después más o menos **1 de cada 4 niveles**, nunca dos seguidos) llega un **jefe**: una
burbuja **gigante** que hay que tocar **muchas veces** (6 al principio, y más en los niveles altos, hasta 9). Con
cada toque **se achica, se ríe y suelta una burbujita**; con el último **explota en 6 burbujitas** y la mascota
aplaude. Vienen 3 burbujas normales con él. Todas las burbujitas también hay que reventarlas. Cuando llega, suena
una fanfarria y la voz lo presenta.

| Jefe | Cómo es |
|---|---|
| 👑 **Rey Burbuja** | Dorado, con corona. Es el primero (nivel 4). Se va achicando con cada toque |
| 🐰 **Burbuja Saltarina** | Rosada, con orejas de conejo. Con cada toque **salta a otro lado** de la pantalla |
| 😴 **Burbuja Dormilona** | Con gorro de dormir y "Zzz". Duerme y va lentito; al tocarla **se despierta riéndose y corre** un ratito, y se vuelve a dormir |
| 🪅 **Burbuja Piñata** | De rayas de colores. Con cada toque **le caen burbujitas de dulce** |

Arriba: la **casita** vuelve al menú, en el medio están las **estrellas** ganadas y la **orejita** repite qué hacer.

**Volver al nivel 1:** en Ajustes (el engranaje, zona de papás), en la parte de Burbujas dice en qué nivel va y
tiene el botón **"Volver al nivel 1"**.

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `burbujas_ajustes.dart` ⭐ | Todo lo que se puede cambiar: niveles, tipos de burbuja, jefes, mundos, mascotas, caritas, tamaños, colores, voz y sonidos |
| `niveles.dart` | Arma cada nivel con los números de los ajustes (cuántas de cada tipo, velocidad, niveles tranquilos, sorpresa, jefes) |
| `burbujas_juego.dart` | El juego, en cuatro partes: **1. cada nivel** (mundo y mascota), **2. salen y flotan** (cómo se mueven), **3. cuando toca** (revientan, jefes, mega, la mascota) y **4. cómo se ve** |
| `burbuja.dart` | Cómo se dibuja cada burbuja, las explosiones, los animalitos que salen volando y el dibujo de la tarjeta del menú |
| `carita.dart` | Las caritas (contenta, riéndose, dormida, "¡ay!") y lo que lleva cada jefe (corona, orejas, gorro, rayas de piñata) |
| `mundos.dart` | Los cinco mundos (el fondo que se mueve) y cómo cambia de uno a otro |
| `mascota.dart` | La mascota: cómo respira, sopla, salta, aplaude, y el casco de astronauta |
| `dibujos.dart` | Letras y emojis ya preparados, para que vaya fluido |
| `burbujas_papas.dart` | Dónde se guarda el nivel, y la parte de Burbujas en Ajustes ("Volver al nivel 1") |

## Qué cambiar (todo en `burbujas_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Más o menos burbujas | `burbujasAlEmpezar`, `burbujasMasPorNivel`, `burbujasMaximo`, `totalMaximo` |
| Cuántas hay en la pantalla al mismo tiempo | `aLaVezAlEmpezar`, `aLaVezMaximo`, `nivelesParaUnaMasALaVez` |
| Que vayan más lento o más rápido | `velocidadAlEmpezar`, `velocidadMasPorNivel`, `velocidadMaxima` (10 = cruza la pantalla en unos 10 segundos) |
| Que cambien más o menos de dirección | `girosAlEmpezar`, `girosMasPorNivel`, `girosMaximo` |
| Más o menos niveles tranquilos | `probabilidadNivelTranquilo` (0 = nunca) y `nivelesMasFacil` |
| Quitar la sorpresa de cada nivel | `extraSorpresa = 0` |
| Que un tipo salga antes, después o nunca | `superDesdeNivel`, `animalitoDesdeNivel`, `megaDesdeNivel`, `rapidaDesdeNivel` (0 = nunca) |
| Cada cuántos niveles hay una más de cada tipo | `nivelesParaUnaMas` |
| Cuántas de cada tipo como máximo | `superMaximo`, `animalitoMaximo`, `megaMaximo`, `rapidaMaximo` |
| Cuántos toques necesitan | `toquesSuper`, `toquesMega` |
| Cuántas burbujitas salen de la mega | `hijasMega` |
| Qué tan rápidas son las rápidas | `velocidadRapidas` (2.2 = el doble y un poco más) |
| Qué animalitos salen | `animalitos` |
| Desde qué nivel salen jefes, o que no salgan | `jefeDesdeNivel` (0 = nunca) |
| Que salgan jefes más o menos seguido | `probabilidadJefe` (0.25 = 1 de cada 4) y `nivelesSinJefeMaximo` |
| Qué jefes salen | `jefes` (borra uno de la lista para que no salga; el primero sale en `jefeDesdeNivel`) |
| Cuántos toques necesita un jefe | `toquesJefeAlEmpezar`, `nivelesParaUnToqueMas`, `toquesJefeMaximo` |
| Cuántas burbujitas suelta un jefe | `burbujitasPorToqueJefe`, `burbujitasAlReventarJefe` |
| Cuántas normales vienen con el jefe | `normalesConJefe` |
| Qué tan grande es el jefe, y cuánto se achica | `tamanoJefe`, `jefeAchicaHasta` |
| Qué mundos salen | `mundos` (borra uno de la lista para que no salga) |
| Qué mascota sale en cada mundo | `mascotas` (y su nombre para la voz en `nombresMascotas`) |
| Cuántas burbujas sopla la mascota | `parteQueSoplaLaMascota` (0 = ninguna, todas por los lados) |
| Quitar la mascota | `conMascota = false` |
| Quitar las caritas | `caritas = false` (vuelven el "¡POP!" y el "blup") |
| La palabra al reventar | `palabraAlReventar` (`'¡AY!'`) |
| El tamaño de cada burbuja | `tamanoMinimo`, `tamanoMaximo`, `tamanoSuper`, `tamanoAnimalito`, `tamanoMega`, `tamanoChica` |
| Que salgan más seguido o más espaciadas | `segundosEntreBurbujasMinimo`, `segundosEntreBurbujasMaximo` |
| Cuánto se ve el cartel "NIVEL 3" | `segundosCartelNivel` |
| Cuánto dura el festejo corto | `segundosFestejoCorto` |
| Cada cuántos niveles la celebración grande, y cuánto dura | `celebracionGrandeCada`, `segundosCelebracionGrande` |
| Los colores de las burbujas | `colores` (con los nombres de la lista de colores de `lib/app/ajustes_app.dart`) |
| Quitar la palabra "¡AY!" / "¡POP!" | `mostrarPop = false` |
| Lo que dice la voz | `vozInicio`, `vozNivel` (`{nivel}` = el número), `vozSuper`, `vozAnimalito`, `vozMega`, `vozRapida`, `vozJefes`, `vozMundos` (`{mascota}` = el nombre de la mascota), `vozMuyBien` |
| Los textos de los festejos | `festejoCorto`, `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |

Cosas que están en otro archivo:
- **Cómo se ve cada burbuja o la explosión:** `burbuja.dart`; las caritas y los jefes: `carita.dart`.
- **Cómo se ve cada mundo:** `mundos.dart` (busca `CIELO`, `EL FONDO DEL MAR`, `EL ATARDECER`, `LA NOCHE`,
  `EL ESPACIO`).
- **El volumen y apagar sonidos o voz:** `lib/app/ajustes_app.dart`.

## Sonidos

- `assets/sonidos/burbujas/ay1.wav` ... `ay4.wav`: la burbuja con carita que revienta ("¡ay!", van turnándose).
- `assets/sonidos/burbujas/pop1.wav` ... `pop4.wav`: la burbuja sin carita que revienta (si `caritas = false`).
- `assets/sonidos/burbujas/jiji.wav`: la risita (las burbujas que tocas sin reventar, y la mascota).
- `assets/sonidos/burbujas/super_toque.wav`: cada toque a la súper burbuja, la mega o un jefe.
- `assets/sonidos/burbujas/super_pop.wav`: la súper, la mega o un jefe que revientan.
- `assets/sonidos/burbujas/soplo.wav`: la mascota que sopla una burbuja.
- `assets/sonidos/burbujas/aplausos.wav`: la mascota que aplaude.
- `assets/sonidos/burbujas/jefe.wav`: la fanfarria cuando llega un jefe.
- `assets/sonidos/comunes/boing.wav`: la Burbuja Saltarina cuando salta.
- `assets/sonidos/comunes/acierto.wav`: el animalito que sale volando y el festejo corto.
- `assets/sonidos/comunes/felicidades.wav`: la fiesta de la celebración grande.

Para cambiar uno, pon otro archivo con el **mismo nombre** en la misma carpeta.

## Para que vaya fluido

Todas las burbujas, explosiones, animalitos y la mascota se dibujan juntos en **un solo dibujo** que se repinta en
cada cuadro (sin rehacer la pantalla); el mundo de atrás es otro dibujo igual. Las letras y los emojis se preparan
una sola vez, y los brillos se hacen con degradados en vez de desenfoques (que son lentos en los celulares).
