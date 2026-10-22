import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'un dibujo que se celebró con la versión anterior (al 95%) y no está '
      'terminado vuelve a poder celebrarse', (tester) async {
    sinAvisosDeSonido();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paleta_antes', '{"celebrado":true}');
    final dibujo = cuadrado('antes');
    await abrirPantalla(tester, <Dibujo>[dibujo]);
    await esperar(tester, vueltas: 6);
    expect(PaletaDibujo.enMemoria('antes')!.celebrado, isFalse);
    expect(celebracion, findsNothing);
    await cerrarPantalla(tester);
  });
}
