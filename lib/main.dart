import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/app/menu_juegos.dart';
import 'package:colorear_ninos/app/presentacion.dart';
import 'package:colorear_ninos/juegos/pintar/partes/paleta_dibujo.dart';
import 'package:colorear_ninos/juegos/pintar/partes/pintura.dart';

// =============================================================================
//  AQUÍ ARRANCA LA APP. Normalmente no hace falta tocar este archivo.
//
//  El mapa de toda la app está en lib/LEEME.md.
//  Al abrir: la presentación (lib/app/presentacion.dart) y después el menú
//  de juegos (lib/app/menu_juegos.dart), que muestra los juegos de
//  lib/app/lista_juegos.dart.
// =============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Siempre vertical y a pantalla completa, para que sea más difícil salirse sin querer.
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ColorearApp());
}

class ColorearApp extends StatefulWidget {
  const ColorearApp({super.key});

  @override
  State<ColorearApp> createState() => _EstadoApp();
}

class _EstadoApp extends State<ColorearApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cuando la app se va a segundo plano o se cierra, se guarda lo pintado
  /// (juego Pintar).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      Pintura.guardarPendientes();
      PaletaDibujo.guardarPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARVI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF7043),
        scaffoldBackgroundColor: AjustesApp.fondoApp,
      ),
      home: AjustesApp.mostrarPresentacion
          ? const Presentacion()
          : const MenuJuegos(),
    );
  }
}
