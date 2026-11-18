# 🫧 Juego: Burbujas (revienta las burbujas)

Motricidad fina y puntería: hay que **reventar todas las burbujas** que flotan por la pantalla.

## Cómo se juega

1. Al entrar, el juego **sigue en el nivel donde quedó** (queda guardado en el celular). Sale el cartel
   **"NIVEL 3"** (un segundo) y la voz dice qué hacer.
2. Cada nivel pasa en un **mundo distinto**, elegido al azar (nunca el mismo dos veces seguidas): el mundo nuevo
   aparece en un círculo que se abre desde abajo. Abajo está la **mascota** de ese mundo, un animalito animado
   que **camina y a veces corre** de un lado a otro (se da vuelta, se queda quieta un ratito y vuelve a pasear).
3. Las burbujas van saliendo **de a poco**: unas las **sopla la mascota** (salen chiquitas de su boca y crecen) y
   otras entran **por los lados**. Flotan por todas partes, cada una a **su propia velocidad**, cambiando de
   dirección de a poquito y **rebotando** en los bordes y entre ellas.
4. Las burbujas tienen **carita**: miran hacia donde van, **parpadean**, y **se ríen** cuando revienta una que está
   al lado o cuando las tocas sin reventarlas (súper, mega y jefes).
5. **Un toque y revientan** con un **"plip" delicado y una notita de cajita de música** (cada una en una nota
   distinta, subiendo y bajando: al reventar varias seguidas suena como una melodía): la carita pone ojitos "> <",
   sale un destello, gotitas, papelitos, estrellitas y la palabra **"¡POP!"**. Cada burbuja reventada da una
   **estrella**.
6. Arriba se ve cuántas lleva y cuántas faltan (una burbujita por cada burbuja del nivel; si son muchas, una barra).
7. Cuando revienta **todas**: la **mascota aplaude** 👏, un **festejo corto** (fuegos artificiales de burbujas,
   "¡MUY BIEN!") y el nivel siguiente empieza enseguida. **Cada 5 niveles**, la **celebración grande**
   "¡MUY BIEN! REVENTASTE TODAS".
8. Si toca a la **mascota** (donde no hay burbujas), **salta y habla**: el gatito dice **"miau"** (suave y
   delicado), el perrito **"guau"** y el pollito **"pío"** (el pececito se ríe).
9. En **cada nivel** llega un **jefe** gigante (ver más abajo).

## Los mundos y sus mascotas

| Mundo | Cómo es | Mascota |
|---|---|---|
| ☀️ **Cielo** | Sol con carita, nubes que pasan, lomas con flores | 🐥 pollito (en su cascarón, va dando saltitos) o 🐶 perrito |
| 🌊 **Fondo del mar** | Fondo animado: corales, algas, arena y un cardumen de peces que pasa | 🐟 pececito (nada subiendo y bajando) |
| 🌅 **Atardecer** | Sol grande que se esconde, nubes rosadas, pajaritos y lomas moradas | 🐱 gatito o 🐶 perrito |
| 🌙 **Noche** | Luna dormida, estrellas que brillan, luciérnagas y casitas | 🐱 gatito |
| 🚀 **Espacio** | Planetas, estrellas fugaces, un cohete y suelo de luna | 🐶 perrito astronauta (con casco) |

Al empezar cada nivel la voz dice a dónde van: "¡Nivel 4! ¡Al fondo del mar con el pececito!" (si el nivel trae
una burbuja nueva o un jefe, dice eso en vez del mundo).

## Las mascotas animadas y el fondo del mar

Son animaciones **Lottie** bajadas de lottiefiles.com (como "Lottie JSON"):

| Archivo | Qué es |
|---|---|
| `assets/mascotas/perrito.json` | Un corgi caminando |
| `assets/mascotas/gatito.json` | Un gatito caminando que maúlla (era una película con fondo blanco: se le quitó el fondo) |
| `assets/mascotas/pollito.json` | Un pollito en su cascarón que mira y pía |
| `assets/mascotas/pececito.json` | Un pez de rayas nadando con burbujitas |
| `assets/fondos/mar.json` | El fondo del mar (en vez del dibujado) |

- Los originales están en la carpeta del proyecto de Claude (`arvi_mascotas/originales`). `tools/preparar_mascotas.py`
  los recorta (para que todos se vean del mismo tamaño) y le quita el fondo blanco al gatito.
- Cómo camina cada una (si camina con patitas, da saltitos o nada, qué tan rápido, dónde tiene la boca para soplar y
  la cabeza para el casco) está en `ComoEsLaMascota.deCadaAnimacion`, en `mascota.dart`.
- Para **agregar otra mascota**: bájala de lottiefiles.com como "Lottie JSON" (de lado, caminando sin avanzar y sin
  fondo) y mándasela a Claude. Mientras no tenga animación, se ve su emoji (como la 🐳 ballenita).
- Si un archivo falta o no se puede abrir, se ve el emoji (o el fondo del mar dibujado): el juego no se rompe.

## Los niveles no se acaban

Cada nivel tiene un poquito más de burbujas, que van un poco más rápido y cambian más de dirección. Además:

- **Cada pocos niveles aparece un tipo de burbuja nuevo** (la voz lo presenta la primera vez), y desde que
  aparece, **cada 5 niveles** hay una más de ese tipo.
- **Niveles tranquilos al azar:** más o menos 3 de cada 10 niveles son como uno de 1 a 3 niveles antes. Así la
  dificultad sube "en escalera": siente que mejora, sin frustrarse.
- **Una sorpresa en cada nivel:** un tipo de burbuja (al azar) viene con más, para que ningún nivel sea igual.
- Nunca hay más de **32** burbujas para reventar en un nivel (contando al jefe y sus burbujitas). Cuando ya se
  llega a ese número, los niveles siguientes cambian burbujas normales por especiales.

| Desde el nivel | Burbuja nueva | Cómo es |
|---|---|---|
| 1 | Normal | Un toque y revienta |
| 3 | ⭐ **Súper burbuja** | Grande y dorada, con una estrella en la frente. Hay que tocarla **3 veces** (con cada toque se achica y se ríe; los puntitos dicen cuántos faltan) |
| 5 | 🐥 **Animalito** | Una burbuja con un animalito adentro. Al reventarla, **el animalito sale volando** |
| 7 | 🟣 **Mega burbuja** | Enorme, con burbujitas que le dan vueltas. Con **2 toques explota** y salen **4 burbujitas** que también hay que reventar |
| 9 | ⚡ **Burbujitas rápidas** | Chiquitas, brillantes y muy rápidas, con una estela. Se atrapan aunque el dedo no caiga justo encima |

## Los jefes 👑

En **todos los niveles** llega un **jefe**: una burbuja **gigante** (tres cuartos del ancho de la pantalla), con
**rayos de luz** que giran alrededor. Baja desde arriba con una **fanfarria**, y al llegar **hace temblar la
pantalla**. Hay que tocarlo **muchas veces** (5 al principio, y uno más cada 4 niveles, hasta 9). Con cada toque
hace un **"¡bwoing!"**, **se achica, se ríe, suelta una burbujita** y hace lo suyo (ver la tabla); con el último
**explota en 6 burbujitas, con fuegos artificiales**, tiembla todo y la mascota aplaude. Con él vienen las burbujas
de siempre de ese nivel. Todas las burbujitas también hay que reventarlas. La voz lo presenta (si en ese nivel
aparece una burbuja nueva, presenta la burbuja nueva). El primero es el Rey Burbuja (nivel 1); después sale cada
vez uno distinto, al azar, y nunca uno de los últimos 4 que salieron.

| Jefe | Cómo es |
|---|---|
| 👑 **Rey Burbuja** | Dorado, con corona. Con cada toque **sale corriendo** para otro lado |
| 🐰 **Burbuja Saltarina** | Rosada, con orejas de conejo. Da **saltitos sola**, y con cada toque **salta lejos** |
| 😴 **Burbuja Dormilona** | Con gorro de dormir y "Zzz". Duerme y va lentito; al tocarla **se despierta riéndose y corre** un ratito, y se vuelve a dormir |
| 🪅 **Burbuja Piñata** | De rayas de colores, colgada de una cuerda: **se hamaca**. Con cada toque **le caen burbujitas de dulce** |
| 👻 **Burbuja Fantasma** (nueva) | Lila, medio transparente, con sábana. Flota **en zigzag**; con cada toque dice **"¡buu!"**, **desaparece y aparece en otro lado** (mientras no se ve, no se puede tocar) |
| 🐙 **Pulpo Burbuja** (nuevo) | Morado, con seis tentáculos que se mueven. Nada **a empujoncitos**; con cada toque **sale disparado** para el otro lado soltando burbujitas para atrás |
| 🐉 **Dragón Burbuja** (nuevo) | Verde, con cuernitos, alas que aletean y colita. Vuela **haciendo olas**; con cada toque **estornuda chispitas de colores** y le salen burbujitas de la boca |
| 🏐 **Burbuja Pelota** (nueva) | Una pelota de playa de colores. **Rebota y rebota** en el piso, rodando; con cada toque **pega un salto altísimo** |
| 🌀 **Remolino Burbuja** (nuevo) | Celeste, con una espiral y viento alrededor. **Da vueltas y vueltas**; con cada toque **gira rapidísimo** y tira burbujitas en espiral |

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
| `carita.dart` | Las caritas (contenta, riéndose, dormida, "¡ay!") y lo que lleva cada jefe (corona, orejas, gorro, rayas de piñata, sábana, tentáculos, alas y cuernitos, gajos de pelota, espiral y los rayos de luz) |
| `mundos.dart` | Los cinco mundos (el fondo que se mueve) y cómo cambia de uno a otro |
| `mascota.dart` | La mascota: cómo camina y corre de un lado a otro, respira, sopla, salta, aplaude, y el casco de astronauta |
| `animaciones.dart` | Carga una sola vez las animaciones Lottie (mascotas y fondo del mar) |
| `dibujos.dart` | Letras y emojis ya preparados, para que vaya fluido |
| `burbujas_papas.dart` | Dónde se guarda el nivel, y la parte de Burbujas en Ajustes ("Volver al nivel 1") |

## Qué cambiar (todo en `burbujas_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Más o menos burbujas | `burbujasAlEmpezar`, `burbujasMasPorNivel`, `burbujasMaximo`, `totalMaximo` |
| Cuántas hay en la pantalla al mismo tiempo | `aLaVezAlEmpezar`, `aLaVezMaximo`, `nivelesParaUnaMasALaVez` |
| Cuánto de la pantalla pueden tapar a la vez (si está más llena, la siguiente espera) | `espacioMaximoTapado` (0.55 = un poco más de la mitad; 1.0 = sin límite) |
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
| Que salgan jefes en todos los niveles o de vez en cuando | `probabilidadJefe` (1.0 = en todos; 0.25 = 1 de cada 4) y `nivelesSinJefeMaximo` |
| Qué jefes salen | `jefes` (borra uno de la lista para que no salga; el primero sale en `jefeDesdeNivel`) |
| Cuántos toques necesita un jefe | `toquesJefeAlEmpezar`, `nivelesParaUnToqueMas`, `toquesJefeMaximo` |
| Cuántas burbujitas suelta un jefe | `burbujitasPorToqueJefe`, `burbujitasAlReventarJefe` |
| Qué tan grande es el jefe, y cuánto se achica | `tamanoJefe` (0.75 = tres cuartos del ancho), `tamanoJefeAcostada` (con la pantalla acostada: 0.6 del alto), `jefeAchicaHasta` |
| Qué tan rápido va el jefe | `rapidezJefe` (0.55 = un poco más de la mitad que las normales) |
| Que la pantalla no tiemble con los jefes | `temblorConJefes = false` |
| Qué mundos salen | `mundos` (borra uno de la lista para que no salga) |
| Qué mascota sale en cada mundo | `mascotas` (y su nombre para la voz en `nombresMascotas`) |
| Cuántas burbujas sopla la mascota | `parteQueSoplaLaMascota` (0 = ninguna, todas por los lados) |
| Quitar la mascota | `conMascota = false` |
| La animación de cada mascota | `animacionesMascotas` (bórrala de la lista para que se vea el emoji) |
| El tamaño de la mascota | `tamanoMascota` (0.22 = el 22% del lado más corto de la pantalla) |
| Que la mascota no camine | `mascotaCamina = false` (se queda en el medio) |
| Hasta dónde camina | `zonaDeLaMascota` (0.7 = el 70% del medio de la pantalla) |
| Cada cuánto corre y qué tan rápido | `parteQueCorre`, `rapidezCorriendo` |
| Cuánto se queda quieta entre paseos | `segundosQuietaMinimo`, `segundosQuietaMaximo` |
| Fondo del mar animado o dibujado | `fondosAnimados` (bórralo para volver al dibujado) |
| Quitar las caritas | `caritas = false` |
| La palabra al reventar | `palabraAlReventar` (`'¡POP!'`; antes era `'¡AY!'`) |
| Los sonidos al reventar | `sonidosPop` (las 8 pompas, subiendo y bajando; se pueden volver a poner las 6 explosiones de antes) |
| Lo que dice cada mascota al tocarla | `sonidosMascotas` (la que no está ahí se ríe con `sonidoRisa`) |
| Los sonidos de los jefes | `sonidoToqueJefe`, `sonidoJefePop`, `sonidosJefes` (el "¡buu!" del fantasma, etc.) |
| Volver a poner el "¡ay!" | `sonidosAy` (escribe dentro `'burbujas/ay1.wav'` ... `'burbujas/ay4.wav'`) |
| El tamaño de cada burbuja (en la tablet salen un poco más chicas; el jefe no) | `tamanoMinimo`, `tamanoMaximo`, `tamanoSuper`, `tamanoAnimalito`, `tamanoMega`, `tamanoChica` |
| Que salgan más seguido o más espaciadas | `segundosEntreBurbujasMinimo`, `segundosEntreBurbujasMaximo` |
| Cuánto se ve el cartel "NIVEL 3" | `segundosCartelNivel` |
| Cuánto dura el festejo corto | `segundosFestejoCorto` |
| Cada cuántos niveles la celebración grande, y cuánto dura | `celebracionGrandeCada`, `segundosCelebracionGrande` |
| Los colores de las burbujas | `colores` (con los nombres de la lista de colores de `lib/app/ajustes_app.dart`) |
| Quitar la palabra "¡POP!" | `mostrarPop = false` |
| Lo que dice la voz | `vozInicio`, `vozNivel` (`{nivel}` = el número), `vozSuper`, `vozAnimalito`, `vozMega`, `vozRapida`, `vozJefes`, `vozMundos` (`{mascota}` = el nombre de la mascota), `vozMuyBien` |
| Los textos de los festejos | `festejoCorto`, `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |

Cosas que están en otro archivo:
- **Cómo se ve cada burbuja o la explosión:** `burbuja.dart`; las caritas y los jefes: `carita.dart`.
- **Cómo se ve cada mundo:** `mundos.dart` (busca `CIELO`, `EL FONDO DEL MAR`, `EL ATARDECER`, `LA NOCHE`,
  `EL ESPACIO`).
- **El volumen y apagar sonidos o voz:** `lib/app/ajustes_app.dart`.

## Sonidos

- `assets/sonidos/burbujas/pompa1.wav` ... `pompa8.wav`: la burbuja que revienta: un "plip" delicado y una
  notita de cajita de música, cada una en una nota distinta (van turnándose, subiendo y bajando).
- `assets/sonidos/burbujas/pompa_grande.wav`: la súper o la mega que revientan.
- `assets/sonidos/burbujas/toque_jefe.wav`: cada toque a un jefe ("¡bwoing!" grave), y cuando llega.
- `assets/sonidos/burbujas/pompa_jefe.wav`: un jefe que revienta (bum suave y cascada de notitas).
- `assets/sonidos/burbujas/buu.wav`: el "¡buu!" del fantasma.
- `assets/sonidos/burbujas/zumm.wav`: el remolino y el pulpo cuando salen disparados.
- `assets/sonidos/burbujas/explosion3.wav`: las chispitas del dragón.
- `assets/sonidos/comunes/boing.wav`: la Burbuja Saltarina y la Pelota cuando las tocas.
- `assets/sonidos/burbujas/miau.wav`, `guau.wav`, `pio.wav`: el gatito, el perrito y el pollito cuando los tocas.
- `assets/sonidos/burbujas/jiji.wav`: la risita (las burbujas que tocas sin reventar, y el pececito).
- `assets/sonidos/burbujas/super_toque.wav`: cada toque a la súper burbuja o a la mega.
- `assets/sonidos/burbujas/soplo.wav`: la mascota que sopla una burbuja.
- `assets/sonidos/burbujas/aplausos.wav`: la mascota que aplaude.
- `assets/sonidos/burbujas/jefe.wav`: la fanfarria cuando llega un jefe.
- `assets/sonidos/comunes/acierto.wav`: el animalito que sale volando y el festejo corto.
- `assets/sonidos/comunes/felicidades.wav`: la fiesta de la celebración grande.
- Los de antes (ya no se usan, pero se pueden volver a poner en los ajustes): `explosion1.wav` ...
  `explosion6.wav` (brillitos, campanitas, fuegos, arpa, gotitas y confeti), `super_pop.wav`, `ay1.wav` ...
  `ay4.wav` (el "¡ay!") y `pop1.wav` ... `pop4.wav`.

Para cambiar uno, pon otro archivo con el **mismo nombre** en la misma carpeta.

## Para que vaya fluido

Todas las burbujas, explosiones, animalitos y la mascota se dibujan juntos en **un solo dibujo** que se repinta en
cada cuadro (sin rehacer la pantalla); el mundo de atrás es otro dibujo igual. Las animaciones Lottie se cargan una
sola vez (en segundo plano) y quedan guardadas mientras la app esté abierta. Las letras y los emojis se preparan
una sola vez, y los brillos se hacen con degradados en vez de desenfoques (que son lentos en los celulares).
