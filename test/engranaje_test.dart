import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/app/pantalla_ajustes.dart';
import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets('el engranaje del menú de juegos abre los Ajustes',
      (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: MenuJuegos()));
    await esperar(tester);
    final engranaje = find.byKey(const ValueKey<String>('engranaje'));
    expect(engranaje, findsOneWidget);

    // Un toque normal (no hace falta dejarlo apretado).
    await tester.tap(engranaje);
    await esperar(tester, vueltas: 10);
    expect(find.byType(PantallaAjustes), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('modo_2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('modo_2')));
    await tester.pump();
    expect(ModoPintado.actual, ModoPintado.porObjeto);

    // Volver al menú.
    await tester.pageBack();
    await esperar(tester, vueltas: 10);
    expect(find.byType(PantallaAjustes), findsNothing);
    expect(engranaje, findsOneWidget);
  });
}
