"""Las 5 casas: casa del árbol, iglú, castillo, casa hongo y casita del perro.

A diferencia de los otros dibujos, cada casa trae en su JSON su paleta
("colores") y su personaje para el Modo 2 ("personaje"), así no hace falta
agregarlas en pintar_ajustes.dart.
"""
import math

import numpy as np

from formas import (Forma, circulo, contorno, curva, elipse, en_circulo,
                    en_elipse, en_rect, fondo, interseccion, linea, nube, ondas,
                    poligono, punto, rect, relleno_negro, resta, segmentos, suelo,
                    union)


def arco(x, y, w, h):
    """Puerta o ventana con la parte de arriba redonda."""
    r = w / 2.0
    return rect(x, y, w, h, r, r, 0, 0)


def en_arco(x, y, w, h):
    r = w / 2.0
    return union(en_circulo(x + r, y + r, r), en_rect(x, y + r, x + w, y + h))


def domo(cx, base, rx, ry):
    """Media elipse apoyada en el suelo (el iglú)."""
    k = 0.5522847498307936
    f = Forma()
    f.M(cx - rx, base)
    f.C(cx - rx, base - k * ry, cx - k * rx, base - ry, cx, base - ry)
    f.C(cx + k * rx, base - ry, cx + rx, base - k * ry, cx + rx, base)
    return f.Z()


def rayas(dentro, lineas, minimo=14):
    """Rayitas recortadas para que queden solo dentro de la figura (sin pedacitos)."""
    f = Forma()
    for x0, y0, x1, y1 in lineas:
        largo = math.hypot(x1 - x0, y1 - y0)
        n = max(2, int(largo / 0.5))
        t = np.linspace(0, 1, n)
        xs, ys = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        m = dentro(xs, ys)
        i = 0
        while i < n:
            if m[i]:
                j = i
                while j + 1 < n and m[j + 1]:
                    j += 1
                if math.hypot(xs[j] - xs[i], ys[j] - ys[i]) >= minimo:
                    f.M(xs[i], ys[i]).L(xs[j], ys[j])
                i = j + 1
            else:
                i += 1
    return f


def cruz(x, y, w, h):
    """La cruz de una ventana cuadrada."""
    return segmentos((x + w / 2, y, x + w / 2, y + h), (x, y + h / 2, x + w, y + h / 2))


def cruz_redonda(cx, cy, r):
    return segmentos((cx, cy - r, cx, cy + r), (cx - r, cy, cx + r, cy))


# ------------------------------------------------------------------ 1. casa del árbol

def casa_arbol():
    copa = union(en_circulo(500, 320, 255), en_circulo(275, 430, 180),
                 en_circulo(725, 430, 180), en_circulo(500, 470, 170))
    tronco = (Forma().M(440, 560).L(560, 560).L(562, 800)
              .C(566, 840, 600, 862, 640, 872).L(360, 872)
              .C(400, 862, 434, 840, 438, 800).Z())
    r = [
        ("cielo", fondo()),
        ("sol", circulo(862, 130, 68)),
        ("nube", nube(165, 140, 220)),
        ("pasto", suelo(840)),
        ("copa", contorno(copa, 500, 400, rmax=500)),
        ("manzana1", circulo(300, 262, 42)),
        ("manzana2", circulo(700, 262, 42)),
        ("manzana3", circulo(150, 470, 42)),
        ("manzana4", circulo(850, 470, 42)),
        ("tronco", tronco),
        ("pared", rect(315, 385, 370, 175)),
        ("techo", poligono([(280, 400), (500, 225), (720, 400)])),
        ("puerta", arco(455, 440, 90, 120)),
        ("ventana_izq", rect(345, 425, 75, 75)),
        ("ventana_der", rect(580, 425, 75, 75)),
        ("plataforma", rect(245, 555, 510, 44, 16, 16, 16, 16)),
    ]
    escalera = segmentos((325, 599, 325, 880), (385, 599, 385, 880),
                         *[(325, y, 385, y) for y in (645, 695, 745, 795, 845)])
    d = [
        linea(escalera, 9),
        linea(cruz(345, 425, 75, 75), 7),
        linea(cruz(580, 425, 75, 75), 7),
        punto(528, 508, 8),
    ]
    return {
        "id": "casa_arbol", "nombre": "Casa del árbol", "regiones": r, "detalles": d,
        "colores": ["Verde", "Marrón", "Rojo", "Celeste", "Amarillo"],
        "personaje": {"nombre": "la casita", "partes": ["pared", "techo"]},
    }


# ------------------------------------------------------------------ 2. iglú

def iglu():
    cx, base, rx, ry = 410, 800, 290, 330
    tx, ty, tw, th = 305, 615, 210, 190      # túnel
    px, py, pw, ph = 357, 678, 106, 127      # entrada
    r = [
        ("cielo", fondo()),
        ("sol", circulo(840, 150, 78)),
        ("nube", nube(250, 165, 260)),
        ("nieve", ondas(770, 18, 4)),
        ("cupula", domo(cx, base, rx, ry)),
        ("tunel", arco(tx, ty, tw, th)),
        ("entrada", arco(px, py, pw, ph)),
        ("ala_izq", elipse(752, 745, 26, 68, 0.35)),
        ("ala_der", elipse(918, 745, 26, 68, -0.35)),
        ("pinguino", elipse(835, 735, 88, 130)),
        ("panza", elipse(835, 772, 58, 88)),
        ("pata_izq", elipse(800, 868, 38, 17)),
        ("pata_der", elipse(870, 868, 38, 17)),
        ("pico", poligono([(800, 668), (870, 668), (835, 722)])),
    ]
    en_domo = interseccion(en_elipse(cx, base, rx, ry), en_rect(0, 0, 1000, base))
    en_tunel = en_arco(tx, ty, tw, th)
    en_entrada = en_arco(px, py, pw, ph)
    filas = [550, 633, 716]
    juntas = [(550, 633, x) for x in (270, 370, 450, 550)] + \
             [(633, 716, x) for x in (210, 600)] + \
             [(716, 800, x) for x in (170, 260, 560, 650)] + \
             [(470, 550, x) for x in (360, 460)]
    bloques = [(0, y, 1000, y) for y in filas] + [(x, y0, x, y1) for y0, y1, x in juntas]
    d = [
        linea(rayas(resta(en_domo, en_tunel), bloques), 7),
        linea(rayas(resta(en_tunel, en_entrada),
                    [(tx, 720, px, 720), (px + pw, 720, tx + tw, 720),
                     (tx + tw / 2, ty, tx + tw / 2, py)]), 7),
        punto(808, 642, 11),
        punto(862, 642, 11),
    ]
    return {
        "id": "iglu", "nombre": "Iglú", "regiones": r, "detalles": d,
        "colores": ["Celeste", "Azul", "Amarillo", "Naranja", "Negro"],
        "personaje": {"nombre": "el iglú", "partes": ["cupula", "tunel"]},
    }


# ------------------------------------------------------------------ 3. castillo

def castillo():
    # muro con almenas (de x=300 a 700; las torres tapan las orillas)
    almenas = [(300, 366), (418, 474), (526, 582), (634, 700)]
    pts = [(300, 860), (300, 395)]
    for i, (a, b) in enumerate(almenas):
        if i > 0:
            pts.append((a, 440))
            pts.append((a, 395))
        pts.append((b, 395))
        if i < len(almenas) - 1:
            pts.append((b, 440))
    pts.append((700, 860))
    r = [
        ("cielo", fondo()),
        ("nube", nube(500, 165, 240)),
        ("pasto", suelo(840)),
        ("camino", poligono([(440, 860), (560, 860), (615, 985), (385, 985)])),
        ("muro", poligono(pts)),
        ("torre_izq", rect(140, 330, 170, 530)),
        ("torre_der", rect(690, 330, 170, 530)),
        ("techo_izq", poligono([(115, 340), (225, 120), (335, 340)])),
        ("techo_der", poligono([(665, 340), (775, 120), (885, 340)])),
        ("bandera_izq", poligono([(225, 35), (315, 65), (225, 95)])),
        ("bandera_der", poligono([(775, 35), (865, 65), (775, 95)])),
        ("puerta", arco(425, 650, 150, 210)),
        ("ventana", circulo(500, 545, 48)),
        ("ventana_izq", arco(195, 430, 60, 95)),
        ("ventana_der", arco(745, 430, 60, 95)),
    ]
    en_puerta = en_arco(425, 650, 150, 210)
    d = [
        linea(segmentos((225, 120, 225, 33), (775, 120, 775, 33)), 9),
        linea(rayas(en_puerta, [(475, 640, 475, 860), (525, 640, 525, 860)]), 7),
        punto(545, 770, 9),
    ]
    return {
        "id": "castillo", "nombre": "Castillo", "regiones": r, "detalles": d,
        "colores": ["Rosado", "Morado", "Celeste", "Amarillo", "Verde"],
        "personaje": {"nombre": "el castillo", "partes": ["muro", "torre_izq", "torre_der"]},
    }


# ------------------------------------------------------------------ 4. casa hongo

def flor(cx, cy, rp=32, dist=38):
    petalos = union(*[en_circulo(cx + dist * math.cos(math.radians(-90 + 72 * i)),
                                 cy + dist * math.sin(math.radians(-90 + 72 * i)), rp)
                      for i in range(5)], en_circulo(cx, cy, dist))
    return contorno(petalos, cx, cy, rmax=150), circulo(cx, cy, 27)


def casa_hongo():
    tallo = (Forma().M(340, 480).L(660, 480).C(672, 600, 690, 760, 712, 850)
             .L(288, 850).C(310, 760, 328, 600, 340, 480).Z())
    gorro = (Forma().M(120, 520).C(100, 290, 300, 130, 500, 130)
             .C(700, 130, 900, 290, 880, 520).C(760, 575, 240, 575, 120, 520).Z())
    petalos_izq, centro_izq = flor(165, 895)
    petalos_der, centro_der = flor(835, 895)
    r = [
        ("cielo", fondo()),
        ("sol", circulo(880, 120, 62)),
        ("pasto", suelo(820)),
        ("tallo", tallo),
        ("gorro", gorro),
        ("mancha1", circulo(290, 390, 58)),
        ("mancha2", circulo(480, 250, 64)),
        ("mancha3", circulo(690, 370, 62)),
        ("mancha4", circulo(520, 455, 46)),
        ("puerta", arco(450, 660, 100, 190)),
        ("ventana_izq", circulo(392, 615, 40)),
        ("ventana_der", circulo(608, 615, 40)),
        ("flor_izq", petalos_izq),
        ("centro_izq", centro_izq),
        ("flor_der", petalos_der),
        ("centro_der", centro_der),
    ]
    d = [
        linea(cruz_redonda(392, 615, 40), 7),
        linea(cruz_redonda(608, 615, 40), 7),
        punto(530, 765, 9),
    ]
    return {
        "id": "casa_hongo", "nombre": "Casa hongo", "regiones": r, "detalles": d,
        "colores": ["Rojo", "Amarillo", "Verde", "Celeste", "Marrón"],
        "personaje": {"nombre": "el techo", "partes": ["gorro"]},
    }


# ------------------------------------------------------------------ 5. casita del perro

def casa_perro():
    hueso = union(en_rect(440, 395, 560, 425),
                  en_circulo(440, 392, 21), en_circulo(440, 428, 21),
                  en_circulo(560, 392, 21), en_circulo(560, 428, 21))
    plato = (Forma().M(660, 850).L(840, 850).C(835, 885, 815, 905, 790, 910)
             .L(710, 910).C(685, 905, 665, 885, 660, 850).Z())
    r = [
        ("cielo", fondo()),
        ("sol", circulo(150, 150, 75)),
        ("nube", nube(780, 165, 250)),
        ("pasto", suelo(780)),
        ("pared", rect(250, 470, 500, 350)),
        ("techo", poligono([(190, 500), (500, 235), (810, 500)])),
        ("hueso", contorno(hueso, 500, 410, rmax=200)),
        ("puerta", arco(370, 560, 260, 260)),
        ("oreja_izq", elipse(420, 705, 32, 74, 0.22)),
        ("oreja_der", elipse(580, 705, 32, 74, -0.22)),
        ("cabeza", circulo(500, 685, 88)),
        ("hocico", elipse(500, 730, 48, 34)),
        ("plato", plato),
        ("pelota", circulo(215, 885, 52)),
    ]
    en_pared = en_rect(250, 470, 750, 820)
    tablas = rayas(resta(en_pared, en_arco(370, 560, 260, 260)),
                   [(250, y, 750, y) for y in (545, 620, 695, 770)])
    d = [
        linea(tablas, 6),
        punto(466, 662, 12),
        punto(534, 662, 12),
        relleno_negro(elipse(500, 712, 17, 12)),
        linea(segmentos((500, 722, 500, 738)), 6),
        linea(curva(474, 736, 480, 750, 494, 752, 500, 738), 6),
        linea(curva(500, 738, 506, 752, 520, 750, 526, 736), 6),
        linea(curva(170, 860, 200, 880, 230, 880, 260, 860), 7),
    ]
    return {
        "id": "casa_perro", "nombre": "Casita del perro", "regiones": r, "detalles": d,
        "colores": ["Rojo", "Marrón", "Amarillo", "Celeste", "Verde"],
        "personaje": {"nombre": "el perrito", "partes": ["cabeza", "oreja_izq", "oreja_der"]},
    }
