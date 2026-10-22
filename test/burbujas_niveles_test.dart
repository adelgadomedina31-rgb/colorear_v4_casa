import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los niveles de Burbujas: no se acaban, suben de a poco (con niveles
/// tranquilos al azar) y cada pocos niveles aparece algo nuevo.
void main() {
  /// Los planes de los niveles 1 a [hasta], jugados con la semilla
  /// [semilla] (como en el juego: recordando cuándo salió el último jefe).
  List<PlanNivel> jugar(int semilla, int hasta) {
    final azar = math.Random(semilla);
    var sinJefe = 1;
    TipoJefe? ultimo;
    final planes = <PlanNivel>[];
    for (var n = 1; n <= hasta; n++) {
      final p = PlanNivel.para(n, azar,
          nivelesSinJefe: sinJefe, jefeAnterior: ultimo);
      if (p.jefe != null) {
        sinJefe = 0;
        ultimo = p.jefe;
      } else {
        sinJefe++;
      }
      planes.add(p);
    }
    return planes;
  }

  test('El nivel 1 es fácil: pocas burbujas normales, lentas', () {
    for (var semilla = 0; semilla < 20; semilla++) {
      final p = PlanNivel.para(1, math.Random(semilla));
      expect(p.numero, 1);
      expect(p.tranquilo, isFalse);
      expect(p.total, AjustesBurbujas.burbujasAlEmpezar);
      expect(p.cuantas(TipoBurbuja.normal), AjustesBurbujas.burbujasAlEmpezar);
      expect(p.aLaVez, AjustesBurbujas.aLaVezAlEmpezar);
      expect(p.velocidad, AjustesBurbujas.velocidadAlEmpezar / 100);
      expect(p.nuevos, isEmpty);
    }
  });

  test('Los niveles no se acaban y nunca pasan de los máximos', () {
    for (var semilla = 0; semilla < 30; semilla++) {
      for (final p in jugar(semilla, 300)) {
        expect(p.total, lessThanOrEqualTo(AjustesBurbujas.totalMaximo),
            reason: 'nivel ${p.numero}');
        expect(p.aLaVez, lessThanOrEqualTo(AjustesBurbujas.aLaVezMaximo));
        expect(p.velocidad,
            lessThanOrEqualTo(AjustesBurbujas.velocidadMaxima / 100));
        expect(p.giros, lessThanOrEqualTo(AjustesBurbujas.girosMaximo));
        expect(p.cuantas(TipoBurbuja.superBurbuja),
            lessThanOrEqualTo(AjustesBurbujas.superMaximo + 1));
        expect(p.cuantas(TipoBurbuja.mega),
            lessThanOrEqualTo(AjustesBurbujas.megaMaximo + 1));
        expect(p.cuantas(TipoBurbuja.chica), 0,
            reason: 'las chicas solo salen de las mega y de los jefes');
        // El orden tiene todas; las dos primeras son normales (o el jefe
        // primero).
        final orden = p.orden(math.Random(semilla));
        expect(
            orden.length,
            p.total -
                p.cuantas(TipoBurbuja.mega) * AjustesBurbujas.hijasMega -
                p.burbujitasDelJefe);
        if (p.jefe == null) {
          expect(orden.take(2), everyElement(TipoBurbuja.normal));
          expect(p.cuantas(TipoBurbuja.normal), greaterThanOrEqualTo(3));
        } else {
          expect(orden.first, TipoBurbuja.jefe);
        }
      }
    }
  });

  test('Cada tipo sale desde su nivel, y la primera vez es "nuevo"', () {
    final desde = <TipoBurbuja, int>{
      TipoBurbuja.superBurbuja: AjustesBurbujas.superDesdeNivel,
      TipoBurbuja.animalito: AjustesBurbujas.animalitoDesdeNivel,
      TipoBurbuja.mega: AjustesBurbujas.megaDesdeNivel,
      TipoBurbuja.rapida: AjustesBurbujas.rapidaDesdeNivel,
    };
    // Uno nuevo a lo más cada 5 niveles (o menos).
    final niveles = desde.values.toList()..sort();
    expect(niveles.first, lessThanOrEqualTo(5));
    for (var k = 1; k < niveles.length; k++) {
      expect(niveles[k] - niveles[k - 1], inInclusiveRange(1, 5));
    }
    for (var semilla = 0; semilla < 30; semilla++) {
      for (final p in jugar(semilla, 40)) {
        desde.forEach((tipo, nivel) {
          if (p.numero < nivel) {
            expect(p.cuantas(tipo), 0, reason: '$tipo en el nivel ${p.numero}');
          } else if (p.numero == nivel) {
            expect(p.cuantas(tipo), 1, reason: 'la primera vez sale una $tipo');
            expect(p.nuevos, <TipoBurbuja>[tipo]);
          } else if (p.jefe == null) {
            expect(p.cuantas(tipo), greaterThanOrEqualTo(1),
                reason: 'desde que sale, sale siempre: $tipo, ${p.numero}');
          }
        });
        if (!desde.containsValue(p.numero)) expect(p.nuevos, isEmpty);
      }
    }
  });

  test('Va subiendo de a poco: cada 5 niveles hay más cosas', () {
    // El promedio de muchas partidas.
    const partidas = 200;
    final totales = List<double>.filled(41, 0);
    final rapidez = List<double>.filled(41, 0);
    final especiales = List<double>.filled(41, 0);
    final cuantos = List<int>.filled(41, 0);
    for (var semilla = 0; semilla < partidas; semilla++) {
      for (final p in jugar(semilla, 40)) {
        rapidez[p.numero] += p.velocidad / partidas;
        if (p.jefe != null) continue; // los de jefe son distintos
        cuantos[p.numero]++;
        totales[p.numero] += p.total;
        for (final t in PlanNivel.especiales) {
          especiales[p.numero] += p.cuantas(t);
        }
      }
    }
    for (var n = 1; n <= 40; n++) {
      totales[n] /= math.max(1, cuantos[n]);
      especiales[n] /= math.max(1, cuantos[n]);
    }
    // Más burbujas hasta llegar al máximo (nivel 12 más o menos)...
    for (var n = 1; n + 5 <= 12; n++) {
      expect(totales[n + 5], greaterThan(totales[n]),
          reason: 'nivel ${n + 5} con más burbujas que el $n');
    }
    // ... más rápidas hasta el nivel 24...
    for (var n = 1; n + 5 <= 24; n++) {
      expect(rapidez[n + 5], greaterThan(rapidez[n]));
    }
    // ... y cada vez más especiales (en vez de normales) hasta el 21.
    for (var n = AjustesBurbujas.superDesdeNivel; n + 5 <= 21; n++) {
      expect(especiales[n + 5], greaterThan(especiales[n]),
          reason: 'nivel ${n + 5} con más burbujas especiales que el $n');
    }
  });

  test('A veces sale un nivel más tranquilo (nunca en los 3 primeros)', () {
    var tranquilos = 0;
    var niveles = 0;
    for (var semilla = 0; semilla < 100; semilla++) {
      for (final p in jugar(semilla, 30)) {
        if (p.numero <= 3) {
          expect(p.tranquilo, isFalse);
          expect(p.dificultad, p.numero);
          continue;
        }
        niveles++;
        if (p.tranquilo) {
          tranquilos++;
          expect(
              p.dificultad,
              inInclusiveRange(
                  p.numero - AjustesBurbujas.nivelesMasFacil, p.numero - 1));
        } else {
          expect(p.dificultad, p.numero);
        }
      }
    }
    final parte = tranquilos / niveles;
    expect(parte, closeTo(AjustesBurbujas.probabilidadNivelTranquilo, 0.06));
  });

  test('Cada nivel trae una sorpresa distinta (no todos son iguales)', () {
    final distintos = <String>{
      for (var semilla = 0; semilla < 40; semilla++)
        PlanNivel.para(15, math.Random(semilla))
            .cantidades
            .entries
            .map((e) => '${e.key.name}${e.value}')
            .join(','),
    };
    expect(distintos.length, greaterThanOrEqualTo(4));
  });

  test('De vez en cuando, un nivel de jefe (nunca dos seguidos)', () {
    final jefes = TipoJefe.deLosAjustes;
    expect(jefes.first, TipoJefe.rey);
    var deJefe = 0;
    var niveles = 0;
    final vistos = <TipoJefe>{};
    for (var semilla = 0; semilla < 100; semilla++) {
      final planes = jugar(semilla, 60);
      var sinJefe = 0;
      TipoJefe? anterior;
      for (final p in planes) {
        final jefe = p.jefe;
        if (p.numero < AjustesBurbujas.jefeDesdeNivel) {
          expect(jefe, isNull);
          sinJefe++;
          continue;
        }
        if (p.numero == AjustesBurbujas.jefeDesdeNivel) {
          expect(jefe, TipoJefe.rey, reason: 'el primero es el Rey Burbuja');
        }
        niveles++;
        if (jefe == null) {
          sinJefe++;
          expect(sinJefe,
              lessThanOrEqualTo(AjustesBurbujas.nivelesSinJefeMaximo + 3),
              reason: 'no pasan muchos niveles sin jefe');
          continue;
        }
        deJefe++;
        vistos.add(jefe);
        expect(p.nuevos, isEmpty, reason: 'no cuando sale una burbuja nueva');
        expect(sinJefe, greaterThan(0),
            reason: 'nunca dos niveles de jefe seguidos (${p.numero})');
        expect(jefe, isNot(anterior), reason: 'no se repite el mismo jefe');
        anterior = jefe;
        sinJefe = 0;
        // El jefe y unas pocas normales; las burbujitas que suelta cuentan.
        expect(p.cuantas(TipoBurbuja.jefe), 1);
        expect(p.cuantas(TipoBurbuja.normal), AjustesBurbujas.normalesConJefe);
        for (final t in PlanNivel.especiales) {
          expect(p.cuantas(t), 0);
        }
        expect(p.toquesJefe,
            inInclusiveRange(2, AjustesBurbujas.toquesJefeMaximo));
        expect(
            p.toquesJefe,
            greaterThanOrEqualTo(math.min(AjustesBurbujas.toquesJefeAlEmpezar,
                AjustesBurbujas.toquesJefeMaximo)));
        expect(
            p.total,
            1 +
                AjustesBurbujas.normalesConJefe +
                (p.toquesJefe - 1) * AjustesBurbujas.burbujitasPorToqueJefe +
                AjustesBurbujas.burbujitasAlReventarJefe);
      }
    }
    expect(vistos, jefes.toSet(), reason: 'salen todos los jefes');
    // Más o menos 1 de cada 4 o 5 niveles.
    expect(deJefe / niveles, inInclusiveRange(0.15, 0.3));
  });

  test('Los jefes piden más toques en los niveles altos', () {
    final bajo = PlanNivel.deJefe(AjustesBurbujas.jefeDesdeNivel, TipoJefe.rey);
    final alto = PlanNivel.deJefe(60, TipoJefe.rey);
    expect(bajo.toquesJefe, AjustesBurbujas.toquesJefeAlEmpezar);
    expect(alto.toquesJefe, AjustesBurbujas.toquesJefeMaximo);
    expect(alto.total, lessThanOrEqualTo(AjustesBurbujas.totalMaximo));
    for (final j in TipoJefe.values) {
      expect(PlanNivel.deJefe(10, j).jefe, j);
    }
  });
}
