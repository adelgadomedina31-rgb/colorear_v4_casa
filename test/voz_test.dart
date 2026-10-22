import 'package:colorear_ninos/comun/voz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los nombres de las grabaciones van sin tildes ni espacios', () {
    expect(Voz.clave('Marrón'), 'marron');
    expect(Voz.clave('Elige un color'), 'elige_un_color');
    expect(Voz.clave('  ¡Rojo!  '), 'rojo');
    expect(Voz.clave('USA-OTRO color'), 'usa_otro_color');
  });
}
