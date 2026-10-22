import 'package:colorear_ninos/juegos/pintar/pintar_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Modo 2: un dibujo que ya estaba pintado (por ejemplo en el Modo 1) '
      'se pone al día al entrar, sin decir nada', (tester) async {
    sinAvisosDeSonido();
    await ModoPintado.cambiar(ModoPintado.porObjeto);
    final pez = leerDibujo('pez.json');
    final colores = PaletaDibujo.coloresDe(pez);
    Trazo llenar(String id, int color) => Trazo(
          region: zona(pez, id),
          color: colores[color].color,
          radio: 1500,
          semilla: 0,
          inicio: puntoDe(pez, id),
        );
    // Pintado antes: el cuerpo naranja y el agua celeste. (Lo anotado del
    // Modo 2 de antes quedó viejo: ahora el pez es naranja, no verde.)
    SharedPreferences.setMockInitialValues(<String, Object>{
      'paleta_pez': '{"colorPersonaje":"Verde"}',
    });
    await tester.runAsync(() async {
      await Pintura.abrir(pez);
      Pintura.hornear(
        pez,
        <Trazo>[llenar('cuerpo', 0), llenar('agua', 2)],
        Pintura.version('pez'),
      );
      await Pintura.guardarPendientes();
    });

    final lienzo = await abrirPantalla(tester, <Dibujo>[pez]);
    final paleta = PaletaDibujo.enMemoria('pez')!;
    expect(paleta.colorPersonaje, 'Naranja');
    expect(paleta.usadoEnResto('Celeste'), isTrue);
    expect(paleta.usadoEnResto('Naranja'), isFalse);
    expect(paleta.personajeTerminado, isFalse);
    expect(frases, <String>[AjustesPintar.vozEligeUnColor]);

    // El celeste no pinta el pez.
    await elegirColor(tester, 2);
    frases.clear();
    await tocar(tester, lienzo, pez, puntoDe(pez, 'cola'));
    expect(await pintadoEn(tester, pez, puntoDe(pez, 'cola')), 0);
    expect(frases, <String>['¡Pinta el pez con el naranja!']);

    await cerrarPantalla(tester);
    await tester.runAsync(() => Pintura.cerrar(pez));
  });
}
