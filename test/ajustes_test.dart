import 'package:colorear_ninos/juegos/pintar/partes/modo_pintado.dart';
import 'package:colorear_ninos/app/pantalla_ajustes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets('en Ajustes se elige el modo de pintar y queda guardado',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: PantallaAjustes()));
    await tester.pump();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Modo 1 - Pintado total'), findsOneWidget);
    expect(find.text('Modo 2 - Pintado por objeto'), findsOneWidget);

    Finder marca(int modo) => find.descendant(
          of: find.byKey(ValueKey<String>('modo_$modo')),
          matching: find.byIcon(Icons.check_circle_rounded),
        );
    // Empieza en el Modo 1.
    expect(marca(1), findsOneWidget);
    expect(marca(2), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey<String>('modo_2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('modo_2')));
    await tester.pump();
    expect(ModoPintado.actual, ModoPintado.porObjeto);
    expect(marca(1), findsNothing);
    expect(marca(2), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('modo_pintado'), 2);

    await tester.ensureVisible(find.byKey(const ValueKey<String>('modo_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('modo_1')));
    await tester.pump();
    expect(ModoPintado.actual, ModoPintado.total);
    expect(marca(1), findsOneWidget);
    expect(prefs.getInt('modo_pintado'), 1);
  });
}
