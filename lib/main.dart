import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_rondines/services/user_session.dart';
import 'package:aplicacion_rondines/screens/login_screen.dart';
import 'package:aplicacion_rondines/screens/opciones_rondines.dart';
import 'package:aplicacion_rondines/screens/rondin_afuera.dart';
import 'package:aplicacion_rondines/screens/rondin_interior.dart';
import 'package:aplicacion_rondines/screens/listado_rondines.dart';
import 'package:aplicacion_rondines/screens/seleccion_ronda.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSession(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Rondines',
        theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
        // Rutas de la aplicación
        routes: {
          'login': (_) => const LoginScreen(),
          'opciones_rondines': (_) => const OpcionesRondines(),
          'seleccion_ronda': (_) => const SeleccionRonda(),
          'rondin_afuera': (_) => const RondinAfuera(),
          'rondin_interior': (_) => const RondinInterior(),
          'listado_rondines': (_) => const ListadoRondines(),
        },
        initialRoute: 'login',
      ),
    );
  }
}
