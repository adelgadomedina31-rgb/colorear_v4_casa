import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los niveles de Burbujas: no se acaban, suben de a poco (con niveles
/// tranquilos al azar), cada pocos niveles aparece algo nuevo y en todos
/// llega un jefe.
void main() {
  /// Los planes de los niveles 1 a [hasta], jugados con la semilla
  /// [semilla] (como en el juego: recordando los últimos jefes).
  List<PlanNivel> jugar(int semilla, int hasta) {
    final azar = math.Random(semilla);
    var sinJefe = 1;
    final recientes = <TipoJefe>[];
    final planes = <PlanNivel>[];
    for (var n = 1; n <= hasta; n++) {
      final p = PlanNivel.para(n, azar,
          nivelesSinJefe: sinJefe, jefesRecientes: recientes);
      if (p.jefe != null) {
        sinJefe = 0;
        recientes.add(p.jefe!);
      } else {
        sinJefe++;
      }
      planes.add(p);
    }
    return planes;
  }

  /// Las que hay que reventar sin contar al jefe ni sus burbujitas.
  int sinElJefe(PlanNivel p) =>
      p.total - p.cuantas(TipoBurbuja.jefe) - p.burbujitasDelJefe;

  test('El nivel 1 es fácil: pocas burbujas normales, lentas, y el Rey', () {
    for (var semilla = 0; semilla < 20; semilla++) {
      final p = PlanNivel.para(1, math.Random(semilla));
      expect(p.numero, 1);
      expect(p.tranquilo, isFalse);
      expect(p.jefe, TipoJefe.rey, reason: 'el primero es el Rey Burbuja');
      expect(p.toquesJefe, AjustesBurbujas.toquesJefeAlEmpezar);
      expect(sinElJefe(p), AjustesBurbujas.burbujasAlEmpezar);
      expect(
          p.total, AjustesBurbujas.burbujasAlEmpezar + 1 + p.burbujitasDelJefe);
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
        // El orden tiene todas: primero el jefe y después dos normales.
        final orden = p.orden(math.Random(semilla));
        expect(
            orden.length,
            p.total -
                p.cuantas(TipoBurbuja.mega) * AjustesBurbujas.hijasMega -
                p.burbujitasDelJefe);
        expect(orden.first, TipoBurbuja.jefe);
        expect(orden.where((t) => t == TipoBurbuja.jefe), hasLength(1));
        expect(orden.skip(1).take(2), everyElement(TipoBurbuja.normal));
        expect(p.cuantas(TipoBurbuja.normal), greaterThanOrEqualTo(3));
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
          } else {
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
    final toques = List<double>.filled(41, 0);
    for (var semilla = 0; semilla < partidas; semilla++) {
      for (final p in jugar(semilla, 40)) {
        rapidez[p.numero] += p.velocidad / partidas;
        totales[p.numero] += p.total / partidas;
        toques[p.numero] += p.toquesJefe / partidas;
        for (final t in PlanNivel.especiales) {
          especiales[p.numero] += p.cuantas(t) / partidas;
        }
      }
    }
    // Más burbujas hasta llegar al máximo (nivel 9 más o menos)...
    for (var n = 1; n + 5 <= 9; n++) {
      expect(totales[n + 5], greaterThan(totales[n]),
          reason: 'nivel ${n + 5} con más burbujas que el $n');
    }
    // ... más rápidas hasta el nivel 24...
    for (var n = 1; n + 5 <= 24; n++) {
      expect(rapidez[n + 5], greaterThan(rapidez[n]));
    }
    // ... cada vez más especiales (en vez de normales) hasta el 15...
    for (var n = AjustesBurbujas.superDesdeNivel; n + 5 <= 15; n++) {
      expect(especiales[n + 5], greaterThan(especiales[n]),
          reason: 'nivel ${n + 5} con más burbujas especiales que el $n');
    }
    // ... y jefes más fuertes (más toques) hasta el 20.
    for (var n = 1; n + 5 <= 20; n++) {
      expect(toques[n + 5], greaterThan(toques[n]),
          reason: 'el jefe del nivel ${n + 5} pide más toques que el del $n');
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

  test(
      'En todos los niveles llega un jefe, nunca uno de los últimos que '
      'salieron, y salen todos', () {
    final jefes = TipoJefe.deLosAjustes;
    expect(jefes, TipoJefe.values, reason: 'están todos en la lista');
    expect(jefes.first, TipoJefe.rey);
    expect(AjustesBurbujas.vozJefes.keys, containsAll(AjustesBurbujas.jefes));
    final vecesCadaUno = <TipoJefe, int>{};
    for (var semilla = 0; semilla < 100; semilla++) {
      final recientes = <TipoJefe>[];
      for (final p in jugar(semilla, 60)) {
        final jefe = p.jefe;
        expect(jefe, isNotNull, reason: 'nivel ${p.numero} con jefe');
        if (p.numero == 1) expect(jefe, TipoJefe.rey);
        final ultimos = recientes.reversed.take(PlanNivel.jefesSinRepetir);
        expect(ultimos, isNot(contains(jefe)),
            reason: 'no se repite tan seguido (nivel ${p.numero})');
        recientes.add(jefe!);
        vecesCadaUno[jefe] = (vecesCadaUno[jefe] ?? 0) + 1;
        // El jefe y las burbujas del nivel; las burbujitas que suelta
        // cuentan.
        expect(p.cuantas(TipoBurbuja.jefe), 1);
        expect(p.toquesJefe,
            inInclusiveRange(3, AjustesBurbujas.toquesJefeMaximo));
        expect(
            p.burbujitasDelJefe,
            (p.toquesJefe - 1) * AjustesBurbujas.burbujitasPorToqueJefe +
                AjustesBurbujas.burbujitasAlReventarJefe);
      }
    }
    expect(vecesCadaUno.keys.toSet(), jefes.toSet(), reason: 'salen todos');
    // Más o menos parejo: cada uno sale al menos la mitad de lo que le
    // tocaría.
    final parejo = 100 * 59 / jefes.length;
    for (final veces in vecesCadaUno.values) {
      expect(veces, greaterThan(parejo / 2));
    }
  });

  test('Los jefes piden más toques en los niveles altos', () {
    final bajo = PlanNivel.deJefe(1, TipoJefe.rey);
    final alto = PlanNivel.deJefe(60, TipoJefe.rey);
    expect(bajo.toquesJefe, AjustesBurbujas.toquesJefeAlEmpezar);
    expect(alto.toquesJefe, AjustesBurbujas.toquesJefeMaximo);
    expect(alto.total, lessThanOrEqualTo(AjustesBurbujas.totalMaximo));
    for (final j in TipoJefe.values) {
      final p = PlanNivel.deJefe(10, j);
      expect(p.jefe, j);
      expect(p.tranquilo, isFalse);
    }
  });

  test('Los jefes son gigantes (pero caben en la pantalla)', () {
    expect(AjustesBurbujas.tamanoJefe, greaterThan(AjustesBurbujas.tamanoMega));
    expect(AjustesBurbujas.tamanoJefe, lessThanOrEqualTo(0.85));
  });
}
