#!/usr/bin/env python3
"""Prepara las animaciones (Lottie, .json de lottiefiles.com) de las mascotas
de Burbujas y del fondo del mar, para ponerlas en assets/mascotas/ y
assets/fondos/.

Qué hace con cada una:
  - Las de dibujo (perrito, pollito, pez, fondo): recorta el espacio vacío
    alrededor del animalito, para que todas se vean del mismo tamaño.
  - El gatito (que viene como una película de 120 fotos con fondo blanco):
    le quita el fondo blanco y la sombra gris, lo recorta, lo achica y deja
    una foto de cada dos (así pesa poco y no gasta memoria del celular).

Uso:
  python3 tools/preparar_mascotas.py <carpeta con los originales> <carpeta del proyecto>

Los originales tienen que llamarse Dog.json, cat meow.json, Hatch.json,
Fish.json y "Animated Wallpaper - Under sea.json" (como se descargaron).
Necesita numpy, scipy y Pillow.
"""

import base64
import io
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def _guardar(datos, ruta):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with open(ruta, 'w', encoding='utf-8') as f:
        json.dump(datos, f, separators=(',', ':'), ensure_ascii=False)
    print(f'{ruta}: {os.path.getsize(ruta) // 1024} KB')


def recortar(entrada, salida, caja, margen=0.03):
    """Deja solo el rectángulo [caja] = (x0, y0, x1, y1) de la animación
    (más un margen). Mete todas las capas en una "precomposición" corrida
    hacia arriba y a la izquierda."""
    with open(entrada, encoding='utf-8') as f:
        d = json.load(f)
    x0, y0, x1, y1 = caja
    m = margen * max(x1 - x0, y1 - y0)
    x0, y0 = max(0, x0 - m), max(0, y0 - m)
    x1, y1 = min(d['w'], x1 + m), min(d['h'], y1 + m)
    ancho, alto = round(x1 - x0), round(y1 - y0)
    raiz = {'id': 'mascota_raiz', 'layers': d['layers']}
    if 'fr' in d:
        raiz['fr'] = d['fr']
    capa = {
        'ddd': 0, 'ind': 1, 'ty': 0, 'nm': 'mascota', 'refId': 'mascota_raiz',
        'sr': 1, 'ao': 0, 'w': d['w'], 'h': d['h'],
        'ip': d['ip'], 'op': d['op'], 'st': 0, 'bm': 0,
        'ks': {
            'o': {'a': 0, 'k': 100}, 'r': {'a': 0, 'k': 0},
            'p': {'a': 0, 'k': [-round(x0), -round(y0), 0]},
            'a': {'a': 0, 'k': [0, 0, 0]}, 's': {'a': 0, 'k': [100, 100, 100]},
        },
    }
    d['assets'] = list(d.get('assets', [])) + [raiz]
    d['layers'] = [capa]
    d['w'], d['h'] = ancho, alto
    _guardar(d, salida)


def _sin_fondo(rgb):
    """Una foto RGB con fondo blanco (y sombra gris clarita) -> RGBA con el
    fondo transparente. Lo que es fondo: lo blanco o gris clarito que toca
    el borde de la foto."""
    a = rgb.astype(np.float32)
    mn, mx = a.min(axis=2), a.max(axis=2)
    clarito = (mn > 236) | ((mx - mn < 28) & (mn > 190))
    etiquetas, _ = ndimage.label(clarito)
    bordes = np.unique(np.concatenate([
        etiquetas[0], etiquetas[-1], etiquetas[:, 0], etiquetas[:, -1]]))
    fondo = np.isin(etiquetas, bordes[bordes > 0])
    # Lo blanco encerrado (por ejemplo entre la cola enroscada y el cuerpo)
    # también es fondo, salvo puntitos muy chiquitos (brillos).
    blanco_puro = mn > 236
    trozos, cuantos = ndimage.label(blanco_puro)
    if cuantos:
        tamanos = ndimage.sum(np.ones_like(mn), trozos, range(1, cuantos + 1))
        grandes = np.flatnonzero(tamanos >= 40) + 1
        fondo |= np.isin(trozos, grandes)
    # El borde del gatito está mezclado con el blanco del fondo (unos 3
    # puntitos). Para cada puntito del borde se busca el color "de verdad"
    # (el del gatito más cerca, ya adentro) y se calcula cuánto de ese color
    # tiene: eso es lo transparente que queda.
    lejos = ndimage.distance_transform_edt(~fondo)
    adentro = lejos >= 3.5
    if not adentro.any():
        adentro = ~fondo
    _, (iy, ix) = ndimage.distance_transform_edt(~adentro, return_indices=True)
    verdad = a[iy, ix]
    blanco = np.float32(255)
    hacia = verdad - blanco
    largo = (hacia ** 2).sum(axis=2)
    parte = ((a - blanco) * hacia).sum(axis=2) / np.maximum(largo, 1)
    alfa = np.clip(parte, 0, 1)
    alfa = np.where(largo < 40 ** 2, 1.0, alfa)  # color casi blanco: entero
    alfa = np.where(adentro, 1.0, alfa)
    alfa = np.where(fondo, 0.0, alfa)
    seguro = np.maximum(alfa, 0.1)[..., None]
    color = np.clip(blanco + (a - blanco) / seguro, 0, 255)
    color = np.where(adentro[..., None], a, color)
    return np.dstack([color, alfa * 255]).astype(np.uint8)


def gatito(entrada, salida, alto_final=210, cada=2, calidad=88):
    with open(entrada, encoding='utf-8') as f:
        d = json.load(f)
    fotos = {a['id']: a for a in d['assets']}
    capas = sorted(d['layers'], key=lambda c: c['ip'])
    cuadros = []
    for c in capas[::cada]:
        datos = base64.b64decode(fotos[c['refId']]['p'].split(',', 1)[1])
        rgb = np.array(Image.open(io.BytesIO(datos)).convert('RGB'))
        cuadros.append(_sin_fondo(rgb))
    # El rectángulo donde está el gatito en alguna foto.
    hay = np.stack([c[..., 3] > 10 for c in cuadros]).any(axis=0)
    ys, xs = np.where(hay)
    m = 4
    x0, x1 = max(0, xs.min() - m), min(hay.shape[1], xs.max() + 1 + m)
    y0, y1 = max(0, ys.min() - m), min(hay.shape[0], ys.max() + 1 + m)
    escala = alto_final / (y1 - y0)
    ancho = round((x1 - x0) * escala)
    alto = alto_final
    nuevas = []
    capas_nuevas = []
    for i, c in enumerate(cuadros):
        foto = Image.fromarray(c[y0:y1, x0:x1], 'RGBA').resize(
            (ancho, alto), Image.LANCZOS)
        buf = io.BytesIO()
        foto.save(buf, 'WEBP', quality=calidad, method=6)
        ident = f'g{i}'
        nuevas.append({
            'id': ident, 'w': ancho, 'h': alto, 'u': '', 'e': 1,
            'p': 'data:image/webp;base64,' + base64.b64encode(
                buf.getvalue()).decode('ascii'),
        })
        capas_nuevas.append({
            'ddd': 0, 'ind': i + 1, 'ty': 2, 'refId': ident, 'sr': 1,
            'ks': {
                'o': {'a': 0, 'k': 100}, 'r': {'a': 0, 'k': 0},
                'p': {'a': 0, 'k': [0, 0, 0]}, 'a': {'a': 0, 'k': [0, 0, 0]},
                's': {'a': 0, 'k': [100, 100, 100]},
            },
            'ao': 0, 'ip': i, 'op': i + 1, 'st': 0, 'bm': 0,
        })
    nuevo = {
        'v': d.get('v', '5.5.2'), 'fr': d['fr'] / cada, 'ip': 0,
        'op': len(cuadros), 'w': ancho, 'h': alto, 'nm': 'gatito',
        'ddd': 0, 'assets': nuevas, 'layers': capas_nuevas, 'markers': [],
    }
    _guardar(nuevo, salida)


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    originales, proyecto = sys.argv[1], sys.argv[2]
    mascotas = os.path.join(proyecto, 'assets', 'mascotas')
    fondos = os.path.join(proyecto, 'assets', 'fondos')
    o = lambda n: os.path.join(originales, n)  # noqa: E731
    # Las cajas se midieron dibujando 48 cuadros de cada animación.
    recortar(o('Dog.json'), os.path.join(mascotas, 'perrito.json'),
             (489, 80, 1421, 900))
    recortar(o('Hatch.json'), os.path.join(mascotas, 'pollito.json'),
             (28, 18, 390, 484))
    recortar(o('Fish.json'), os.path.join(mascotas, 'pececito.json'),
             (2, 5, 85, 72), margen=0)
    gatito(o('cat meow.json'), os.path.join(mascotas, 'gatito.json'))
    with open(o('Animated Wallpaper - Under sea.json'), encoding='utf-8') as f:
        _guardar(json.load(f), os.path.join(fondos, 'mar.json'))


if __name__ == '__main__':
    main()
