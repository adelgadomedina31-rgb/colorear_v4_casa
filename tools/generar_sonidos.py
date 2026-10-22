#!/usr/bin/env python3
"""Genera los sonidos de la app en assets/sonidos/ (archivos .wav).

  comunes/ (los usan todos los juegos)
  - felicidades.wav: la fiesta de las celebraciones (campanitas que
    suben, destellos y aplausos).
  - acierto.wav: campanitas cortas cuando acierta.
  - boing.wav: un "boing" suave cuando toca el que no era.

  pintar/
  - gota1.wav ... gota5.wav: una gota de pintura que cae y salpica
    (al tocar el dibujo). Cada una termina en una nota distinta de una
    escala alegre, así al tocar seguido suena como una melodía.
  - trazo1.wav ... trazo4.wav: el pincel que pasa sobre el papel
    (al arrastrar el dedo), con un brillito suave.

  colores/
  - reventar.wav: el globo que revienta, con un destello.

  burbujas/
  - pop1.wav ... pop4.wav: una burbuja que revienta ("¡blup!"), cada una
    en una nota distinta.
  - super_toque.wav: un toque a la súper burbuja (se estira como goma).
  - super_pop.wav: la súper burbuja que revienta, con destellos.
  - ay1.wav ... ay4.wav: una burbuja con carita que revienta y dice
    "¡ay!" (voz chiquita y graciosa, cada una un poco más aguda).
  - jiji.wav: la risita de las burbujas y de la mascota.
  - soplo.wav: la mascota que sopla una burbuja (suavecito).
  - aplausos.wav: la mascota que aplaude al pasar de nivel.
  - jefe.wav: la fanfarria cuando llega un jefe ("¡ta-ta-ta-taaa!").

  contar/
  - nota1.wav ... nota10.wav: una notita que sube al contar cada cosa
    (1, 2, 3, 4, 5...).

Los sonidos de los animales NO se generan aquí: si quieres sonidos de
verdad, pon los archivos en assets/sonidos/animales/ (ver su LEEME.txt).

Todo se sintetiza con matemáticas (no se descarga nada).
Necesita numpy.  Uso:  python3 tools/generar_sonidos.py
"""
import os
import wave

import numpy as np

FS = 44100  # muestras por segundo


def guardar(ruta, senal):
    senal = np.clip(senal, -1.0, 1.0)
    datos = (senal * 32000).astype("<i2")
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())


def tiempo(dur):
    return np.arange(int(FS * dur)) / FS


def filtrar(x, bajo=None, alto=None, orden=2):
    """Filtro pasa-banda suave (hecho con la transformada de Fourier)."""
    n = len(x)
    largo = 1 << int(np.ceil(np.log2(n * 2)))
    espectro = np.fft.rfft(x, largo)
    f = np.fft.rfftfreq(largo, 1 / FS)
    f[0] = 1e-3
    ganancia = np.ones_like(f)
    if alto is not None:
        ganancia /= np.sqrt(1 + (f / alto) ** (2 * orden))
    if bajo is not None:
        ganancia /= np.sqrt(1 + (bajo / f) ** (2 * orden))
    return np.fft.irfft(espectro * ganancia, largo)[:n]


def normalizar(x, pico):
    return x * (pico / max(1e-9, np.max(np.abs(x))))


def suavizar_final(x, ms=15):
    cola = int(FS * ms / 1000)
    x[-cola:] *= np.linspace(1, 0, cola)
    return x


def nota(nombre):
    tabla = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    letra, octava = nombre[0], int(nombre[-1])
    semitonos = tabla[letra] + (octava - 4) * 12
    return 440.0 * 2 ** (semitonos / 12.0)


def poner(pista, inicio, senal):
    i = int(inicio * FS)
    fin = min(len(pista), i + len(senal))
    if fin > i:
        pista[i:fin] += senal[: fin - i]


def burbuja(frec, dur=0.16, subida=1.5, decaimiento=0.045):
    """Burbuja de líquido: un tono que sube rapidito y se apaga
    (así suena el aire que queda atrapado cuando cae una gota)."""
    t = tiempo(dur)
    f = frec / subida + (frec - frec / subida) * (1 - np.exp(-t / 0.018))
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = (1 - np.exp(-t / 0.002)) * np.exp(-t / decaimiento)
    return (np.sin(fase) + 0.18 * np.sin(2 * fase)) * env


def campanita(frec, dur, vol=1.0):
    """Nota tipo campanita / xilófono."""
    t = tiempo(dur)
    env = (1 - np.exp(-t / 0.002)) * np.exp(-t / (0.16 + 60.0 / frec))
    s = (np.sin(2 * np.pi * frec * t)
         + 0.4 * np.sin(2 * np.pi * 2.0 * frec * t) * np.exp(-t / 0.09)
         + 0.2 * np.sin(2 * np.pi * 3.01 * frec * t) * np.exp(-t / 0.05)
         + 0.08 * np.sin(2 * np.pi * 4.2 * frec * t) * np.exp(-t / 0.03))
    return vol * s * env


def gota(frec, semilla):
    """Una gota de pintura que cae: golpecito húmedo + salpicadura +
    burbuja que termina en la nota [frec] + gotitas más chiquitas."""
    azar = np.random.default_rng(semilla)
    dur = 0.32
    pista = np.zeros(int(FS * dur))
    t = tiempo(dur)

    # 1) El golpe: ruido grave y cortito ("plaf").
    golpe = filtrar(azar.standard_normal(len(t)), 120, 1800)
    golpe *= (1 - np.exp(-t / 0.0015)) * np.exp(-t / 0.012)
    pista += normalizar(golpe, 0.55)

    # 2) La salpicadura: ruido más agudo que se apaga enseguida.
    salpica = filtrar(azar.standard_normal(len(t)), 1500, 6000)
    salpica *= (1 - np.exp(-t / 0.003)) * np.exp(-t / 0.028)
    pista += normalizar(salpica, 0.22)

    # 3) La burbuja principal, afinada en una nota.
    poner(pista, 0.006, normalizar(burbuja(frec), 0.85))

    # 4) Gotitas que saltan y caen después.
    for _ in range(azar.integers(2, 4)):
        inicio = azar.uniform(0.05, 0.16)
        f = frec * azar.choice([1.5, 2.0, 2.5, 3.0])
        poner(pista, inicio,
              normalizar(burbuja(f, 0.07, 1.3, 0.016), azar.uniform(0.12, 0.25)))

    # 5) Un poquito de brillo musical (muy suave) en la misma nota.
    poner(pista, 0.012, campanita(frec * 2, 0.3, 0.08))

    return suavizar_final(normalizar(pista, 0.9), 30)


def trazo(frec, semilla, dur=0.34):
    """El pincel sobre el papel: un "shhh" con textura de cerdas,
    y un brillito suave para que suene bonito."""
    azar = np.random.default_rng(semilla)
    t = tiempo(dur)
    # Sube rápido, se mantiene y se va apagando (una pasada de pincel).
    env = np.minimum(1, t / 0.035) * np.exp(-np.maximum(0, t - 0.06) / 0.09)
    # Las cerdas: pequeños tironcitos irregulares.
    granos = filtrar(np.abs(azar.standard_normal(len(t))), None, 60)
    granos = 0.6 + 0.4 * normalizar(granos - granos.mean(), 1)
    shh = filtrar(azar.standard_normal(len(t)), 900, 5500)
    # Un tono de "silbido" del papel que cambia un poco durante la pasada.
    centro = filtrar(azar.standard_normal(len(t)), 2400, 3400, orden=3)
    pasada = normalizar(shh, 1) + 0.6 * normalizar(centro, 1)
    pasada = normalizar(pasada * env * granos, 0.55)

    pista = np.zeros(len(t))
    pista += pasada
    # Dos notitas brillantes de la escala (como polvo mágico).
    poner(pista, 0.02, campanita(frec * 2, 0.3, 0.13))
    poner(pista, 0.09, campanita(frec * 3, 0.25, 0.07))
    return suavizar_final(normalizar(pista, 0.75), 40)


def aplausos(dur, semilla):
    """Muchas palmaditas cortas al azar, cada vez más y luego menos."""
    azar = np.random.default_rng(semilla)
    pista = np.zeros(int(FS * dur))
    total = int(dur * 28)
    for _ in range(total):
        inicio = azar.beta(1.6, 2.6) * (dur - 0.05)
        largo = 0.03
        tt = tiempo(largo)
        palma = filtrar(azar.standard_normal(len(tt)),
                        azar.uniform(700, 1100), azar.uniform(2200, 3600))
        palma *= (1 - np.exp(-tt / 0.0008)) * np.exp(-tt / 0.006)
        poner(pista, inicio, normalizar(palma, azar.uniform(0.3, 1.0)))
    return pista


def felicidades():
    """Fanfarria de campanitas que suben, un acorde que brilla, destellos
    de estrellitas y aplausos."""
    total = 3.4
    pista = np.zeros(int(FS * total))
    # Arpegio que sube (Do mayor) y termina en un acorde.
    subida = [(0.00, "C5"), (0.11, "E5"), (0.22, "G5"), (0.33, "C6"),
              (0.44, "E6"), (0.55, "G6")]
    for inicio, n in subida:
        poner(pista, inicio, campanita(nota(n), 1.0, 0.45))
    for n in ("C5", "E5", "G5", "C6", "E6"):
        poner(pista, 0.78, campanita(nota(n), 1.8, 0.28))
    for inicio, n in [(0.0, "C3"), (0.78, "C3"), (0.78, "G3")]:
        poner(pista, inicio, campanita(nota(n), 1.4, 0.3))
    # Destellos (estrellitas) que caen.
    azar = np.random.default_rng(11)
    for _ in range(26):
        inicio = azar.uniform(0.7, 2.7)
        poner(pista, inicio, campanita(azar.uniform(2600, 5000), 0.3, 0.07))
    musica = normalizar(pista, 1)
    palmas = np.zeros_like(musica)
    poner(palmas, 0.65, aplausos(2.6, 5))
    final = musica + 0.32 * normalizar(palmas, 1)
    final = normalizar(final, 0.85)
    # Que termine suavecito.
    cola = int(0.6 * FS)
    final[-cola:] *= np.linspace(1, 0, cola) ** 1.5
    return final


def acierto():
    """Tres campanitas rápidas que suben (¡muy bien!)."""
    pista = np.zeros(int(FS * 0.9))
    for inicio, n in [(0.0, "G5"), (0.08, "C6"), (0.16, "E6")]:
        poner(pista, inicio, campanita(nota(n), 0.7, 0.5))
    poner(pista, 0.16, campanita(nota("C5"), 0.7, 0.25))
    return suavizar_final(normalizar(pista, 0.75), 60)


def boing():
    """Un "boing" de resorte, suave y gracioso (sin regañar)."""
    dur = 0.5
    t = tiempo(dur)
    f = 170 + 230 * np.exp(-t / 0.06)
    f = f * (1 + 0.1 * np.sin(2 * np.pi * 13 * t) * np.exp(-t / 0.25))
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = (1 - np.exp(-t / 0.004)) * np.exp(-t / 0.16)
    s = (np.sin(fase) + 0.25 * np.sin(2 * fase)) * env
    return suavizar_final(normalizar(s, 0.6), 40)


def reventar(semilla=7):
    """Un globo que revienta ("¡pop!") y un destello de estrellitas."""
    azar = np.random.default_rng(semilla)
    dur = 0.6
    t = tiempo(dur)
    pista = np.zeros(len(t))
    # El estallido: ruido de todas las frecuencias que se corta enseguida.
    pop = filtrar(azar.standard_normal(len(t)), 300, 9000)
    pop *= (1 - np.exp(-t / 0.0005)) * np.exp(-t / 0.018)
    pista += normalizar(pop, 0.9)
    # Un golpecito grave, para que suene "redondo".
    golpe = np.sin(2 * np.pi * 110 * t) * np.exp(-t / 0.03)
    pista += normalizar(golpe, 0.35)
    # El destello.
    for inicio, n in [(0.05, "E6"), (0.11, "G6"), (0.17, "C7")]:
        poner(pista, inicio, campanita(nota(n), 0.4, 0.12))
    return suavizar_final(normalizar(pista, 0.85), 40)


def pop(frec, semilla):
    """Una burbuja que revienta: un "clic" finito y un "blup" que sube."""
    azar = np.random.default_rng(semilla)
    dur = 0.3
    t = tiempo(dur)
    pista = np.zeros(len(t))
    # El clic de la pompa al romperse.
    clic = filtrar(azar.standard_normal(len(t)), 2500, 11000)
    clic *= (1 - np.exp(-t / 0.0003)) * np.exp(-t / 0.005)
    pista += normalizar(clic, 0.55)
    # El "blup": un tono que sube rapidito.
    f = frec * (0.55 + 0.9 * (1 - np.exp(-t / 0.03)))
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = (1 - np.exp(-t / 0.002)) * np.exp(-t / 0.05)
    poner(pista, 0.003, normalizar((np.sin(fase) + 0.2 * np.sin(2 * fase)) * env, 0.8))
    # Gotitas que salpican.
    for _ in range(2):
        poner(pista, azar.uniform(0.03, 0.09),
              normalizar(burbuja(frec * azar.choice([2.0, 2.5, 3.0]), 0.06, 1.3, 0.014),
                         azar.uniform(0.15, 0.25)))
    poner(pista, 0.02, campanita(frec * 3, 0.2, 0.06))
    return suavizar_final(normalizar(pista, 0.85), 30)


def super_toque():
    """La súper burbuja cuando la tocan: se estira como goma ("boing" corto
    y agudo, con temblorcito)."""
    dur = 0.35
    t = tiempo(dur)
    f = 330 + 260 * np.exp(-t / 0.035)
    f = f * (1 + 0.12 * np.sin(2 * np.pi * 19 * t) * np.exp(-t / 0.15))
    fase = 2 * np.pi * np.cumsum(f) / FS
    env = (1 - np.exp(-t / 0.003)) * np.exp(-t / 0.09)
    s = (np.sin(fase) + 0.3 * np.sin(2 * fase)) * env
    return suavizar_final(normalizar(s, 0.6), 30)


def super_pop(semilla=21):
    """La súper burbuja que revienta: un "¡PUM!" redondo, un blup grande y
    una lluvia de destellos que sube."""
    azar = np.random.default_rng(semilla)
    dur = 1.1
    t = tiempo(dur)
    pista = np.zeros(len(t))
    estallido = filtrar(azar.standard_normal(len(t)), 400, 10000)
    estallido *= (1 - np.exp(-t / 0.0005)) * np.exp(-t / 0.022)
    pista += normalizar(estallido, 0.8)
    golpe = np.sin(2 * np.pi * 85 * t) * np.exp(-t / 0.06)
    pista += normalizar(golpe, 0.45)
    poner(pista, 0.005, normalizar(pop(nota("C5"), semilla + 1), 0.6))
    for inicio, n in [(0.08, "C6"), (0.14, "E6"), (0.20, "G6"), (0.26, "C7")]:
        poner(pista, inicio, campanita(nota(n), 0.6, 0.18))
    for _ in range(10):
        poner(pista, azar.uniform(0.25, 0.8), campanita(azar.uniform(2600, 5200), 0.25, 0.05))
    return suavizar_final(normalizar(pista, 0.85), 80)


# ---------------------------------------------------------------------------
#  Voz chiquita (para el "¡ay!" y la risita): se suman los armónicos de la
#  voz, y cada uno suena más o menos fuerte según las "formantes" (las
#  resonancias de la boca que hacen que suene "a" o "i").
# ---------------------------------------------------------------------------

# Formantes (frecuencia, ancho) de una voz de niño.
VOCAL_A = [(1050, 130), (1650, 160), (3300, 250)]
VOCAL_I = [(400, 80), (3000, 200), (3900, 300)]


def _resonancia(f, centro, ancho):
    q = centro / ancho
    return 1.0 / np.sqrt((1 - (f / centro) ** 2) ** 2 + (f / (centro * q)) ** 2)


def voz(f0, formantes, dur, armonicos=24):
    """Una vocal cantada. [f0] = la altura en cada momento (un arreglo),
    [formantes] = una función que da las 3 formantes en cada momento."""
    t = tiempo(dur)
    salida = np.zeros(len(t))
    fs = formantes(t)
    for k in range(1, armonicos + 1):
        fk = k * f0
        activo = fk < FS / 2 - 500
        if not np.any(activo):
            break
        amp = np.zeros(len(t))
        for (centro, ancho), peso in zip(fs, (1.0, 0.6, 0.25)):
            amp += peso * _resonancia(fk, centro, ancho)
        amp *= (1.0 / k) * activo  # la voz es más suave en los agudos
        fase = 2 * np.pi * np.cumsum(fk) / FS
        salida += amp * np.sin(fase)
    return salida


def _entre(a, b, f):
    return a + (b - a) * f


def ay(f0, semilla):
    """Una burbuja que revienta y dice "¡ay!": un clic de pompa y una
    vocecita que va de la "a" a la "i" (y baja, como sorprendida)."""
    azar = np.random.default_rng(semilla)
    dur = 0.36
    pista = np.zeros(int(FS * dur))
    t = tiempo(dur)
    # El clic de la pompa.
    clic = filtrar(azar.standard_normal(len(t)), 2500, 11000)
    clic *= (1 - np.exp(-t / 0.0003)) * np.exp(-t / 0.004)
    pista += normalizar(clic, 0.35)
    # La vocecita.
    dv = 0.3
    tv = tiempo(dv)
    sube = np.minimum(1, tv / 0.04)
    baja = np.clip((tv - 0.04) / (dv - 0.04), 0, 1)
    altura = f0 * (_entre(1.05, 1.25, sube) * _entre(1.0, 0.72, baja ** 1.3))
    altura *= 1 + 0.02 * np.sin(2 * np.pi * 7 * tv)

    def formantes(tt):
        f = np.clip((tt - 0.09) / 0.12, 0, 1)
        f = f * f * (3 - 2 * f)  # suave
        return [(_entre(a[0], i[0], f), _entre(a[1], i[1], f))
                for a, i in zip(VOCAL_A, VOCAL_I)]

    vocal = voz(altura, formantes, dv)
    env = np.minimum(1, tv / 0.012) * np.clip((dv - tv) / 0.09, 0, 1) ** 1.5
    vocal *= env
    # Un poquito de aire al empezar (la "h").
    aire = filtrar(azar.standard_normal(len(tv)), 1500, 7000)
    aire *= np.exp(-tv / 0.02)
    vocal = normalizar(vocal, 1) + 0.12 * normalizar(aire, 1)
    poner(pista, 0.012, normalizar(vocal, 0.85))
    return suavizar_final(normalizar(pista, 0.85), 25)


def jiji(semilla=41):
    """La risita: "¡ji-ji-ji-ji!", cada "ji" un poquito más bajo."""
    azar = np.random.default_rng(semilla)
    dur = 0.62
    pista = np.zeros(int(FS * dur))
    for i, f0 in enumerate((640, 610, 585, 560)):
        inicio = i * 0.125
        # La "j": un soplidito.
        dj = 0.03
        tj = tiempo(dj)
        jota = filtrar(azar.standard_normal(len(tj)), 2000, 7000)
        jota *= np.minimum(1, tj / 0.005) * np.exp(-tj / 0.012)
        poner(pista, inicio, normalizar(jota, 0.25))
        # La "i".
        dv = 0.075
        tv = tiempo(dv)
        altura = f0 * _entre(1.08, 0.92, tv / dv)
        vocal = voz(altura, lambda tt: VOCAL_I, dv)
        vocal *= np.minimum(1, tv / 0.008) * np.clip((dv - tv) / 0.03, 0, 1)
        poner(pista, inicio + 0.018, normalizar(vocal, 0.8))
    return suavizar_final(normalizar(pista, 0.8), 30)


def soplo(semilla=43):
    """La mascota que sopla una burbuja: "fuuu" suavecito y un blup."""
    azar = np.random.default_rng(semilla)
    dur = 0.4
    t = tiempo(dur)
    pista = np.zeros(len(t))
    aire = filtrar(azar.standard_normal(len(t)), 250, 2200)
    aire *= np.minimum(1, t / 0.06) * np.exp(-np.maximum(0, t - 0.08) / 0.07)
    pista += normalizar(aire, 0.6)
    poner(pista, 0.16, normalizar(burbuja(nota("E5"), 0.14, 1.4, 0.04), 0.45))
    return suavizar_final(normalizar(pista, 0.4), 40)


def aplausos_cortos():
    """Aplausos cortitos (la mascota que aplaude)."""
    pista = aplausos(1.5, 9)
    poner(pista, 0.0, campanita(nota("G5"), 0.6, 0.08))
    poner(pista, 0.08, campanita(nota("C6"), 0.6, 0.08))
    return suavizar_final(normalizar(pista, 0.65), 200)


def trompeta(frec, dur, vol=1.0):
    """Una nota de trompeta (de juguete): brillante y con vibrato."""
    t = tiempo(dur)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.15)
    f = frec * vib
    fase = 2 * np.pi * np.cumsum(f) / FS
    brillo = 0.45 + 0.55 * np.minimum(1, t / 0.03)
    s = np.zeros(len(t))
    for k in range(1, 12):
        if k * frec > FS / 2 - 500:
            break
        s += (brillo ** (k * 0.5)) / k * np.sin(k * fase)
    env = np.minimum(1, t / 0.015) * np.clip((dur - t) / 0.05, 0, 1)
    return vol * s * env


def jefe():
    """Llega el jefe: "¡ta-ta-ta-taaa!" con tambor y destellos."""
    total = 1.5
    pista = np.zeros(int(FS * total))
    for inicio, n, d in [(0.0, "G4", 0.12), (0.15, "G4", 0.12),
                         (0.30, "G4", 0.12), (0.45, "C5", 0.75)]:
        poner(pista, inicio, trompeta(nota(n), d, 0.6))
        poner(pista, inicio, trompeta(nota(n) * 1.26, d, 0.25))  # una tercera
    # El tambor.
    azar = np.random.default_rng(47)
    for inicio in (0.0, 0.15, 0.30, 0.45):
        tt = tiempo(0.25)
        golpe = np.sin(2 * np.pi * 90 * tt) * np.exp(-tt / 0.06)
        ruido = filtrar(azar.standard_normal(len(tt)), 200, 3000) * np.exp(-tt / 0.02)
        poner(pista, inicio, normalizar(golpe, 0.5) + normalizar(ruido, 0.2))
    for _ in range(8):
        poner(pista, azar.uniform(0.5, 1.2), campanita(azar.uniform(2600, 5000), 0.3, 0.06))
    return suavizar_final(normalizar(pista, 0.8), 150)


def guardar_burbujas_nuevos(guardar_en):
    """Los sonidos de las burbujas con carita, la mascota y los jefes."""
    for i, f0 in enumerate((430, 480, 530, 590)):
        guardar_en("burbujas", f"ay{i + 1}.wav", ay(f0, 500 + i))
    guardar_en("burbujas", "jiji.wav", jiji())
    guardar_en("burbujas", "soplo.wav", soplo())
    guardar_en("burbujas", "aplausos.wav", aplausos_cortos())
    guardar_en("burbujas", "jefe.wav", jefe())


def main():
    import sys
    carpeta = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            "..", "assets", "sonidos"))
    if len(sys.argv) > 1:  # para probar: guardarlos en otra carpeta
        carpeta = os.path.abspath(sys.argv[1])
    for grupo in ("comunes", "pintar", "colores", "animales", "burbujas", "contar"):
        os.makedirs(os.path.join(carpeta, grupo), exist_ok=True)
    # Quita los sonidos de versiones anteriores (antes estaban sueltos).
    for viejo in os.listdir(carpeta):
        ruta = os.path.join(carpeta, viejo)
        if viejo.endswith(".wav") and os.path.isfile(ruta):
            os.remove(ruta)

    def guardar_en(grupo, nombre, senal):
        guardar(os.path.join(carpeta, grupo, nombre), senal)

    guardar_en("comunes", "felicidades.wav", felicidades())
    guardar_en("comunes", "acierto.wav", acierto())
    guardar_en("comunes", "boing.wav", boing())
    # Escala pentatónica de Do (suena bien en cualquier orden).
    escala = ["C5", "D5", "E5", "G5", "A5"]
    for i, n in enumerate(escala):
        guardar_en("pintar", f"gota{i + 1}.wav", gota(nota(n), 100 + i))
    for i, n in enumerate(["C5", "E5", "G5", "A5"]):
        guardar_en("pintar", f"trazo{i + 1}.wav", trazo(nota(n), 200 + i))
    guardar_en("colores", "reventar.wav", reventar())
    for i, n in enumerate(["G5", "A5", "C6", "D6"]):
        guardar_en("burbujas", f"pop{i + 1}.wav", pop(nota(n), 300 + i))
    guardar_en("burbujas", "super_toque.wav", super_toque())
    guardar_en("burbujas", "super_pop.wav", super_pop())
    guardar_burbujas_nuevos(guardar_en)
    for i, n in enumerate(["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6", "G6", "A6"]):
        guardar_en("contar", f"nota{i + 1}.wav", campanita(nota(n), 0.6, 0.8) * np.linspace(1, 0.9, int(FS * 0.6)))
    for grupo in sorted(os.listdir(carpeta)):
        ruta_grupo = os.path.join(carpeta, grupo)
        if not os.path.isdir(ruta_grupo):
            continue
        for f in sorted(os.listdir(ruta_grupo)):
            print(f"{grupo}/{f}", os.path.getsize(os.path.join(ruta_grupo, f)), "bytes")


if __name__ == "__main__":
    main()
