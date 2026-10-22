import 'package:colorear_ninos/comun/dificultad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la dificultad sube con aciertos seguidos y baja con errores', () {
    final d = Dificultad(
      minimo: 2,
      maximo: 4,
      aciertosParaSubir: 3,
      erroresParaBajar: 2,
    );
    expect(d.opciones, 2);
    d.terminoRonda(0);
    d.terminoRonda(0);
    expect(d.opciones, 2);
    d.terminoRonda(1); // un error corta la racha, pero no baja
    expect(d.opciones, 2);
    d.terminoRonda(0);
    d.terminoRonda(0);
    d.terminoRonda(0);
    expect(d.opciones, 3);
    for (var k = 0; k < 9; k++) {
      d.terminoRonda(0);
    }
    expect(d.opciones, 4); // nunca más del máximo
    d.terminoRonda(3);
    expect(d.opciones, 3);
    d.terminoRonda(2);
    d.terminoRonda(5);
    expect(d.opciones, 2); // nunca menos del mínimo
  });
}
