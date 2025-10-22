import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aplicacion_rondines/services/user_session.dart';
import 'package:aplicacion_rondines/screens/login_screen.dart';
import 'package:aplicacion_rondines/screens/opciones_rondines.dart';
import 'package:aplicacion_rondines/screens/rondin_afuera.dart';
import 'package:aplicacion_rondines/screens/rondin_interior.dart';
import 'package:aplicacion_rondines/screens/listado_rondines.dart';
import 'package:aplicacion_rondines/screens/seleccion_ronda.dart';

import 'package:path/path.dart'; //cuando se termine la app eliminar
import 'package:sqflite/sqflite.dart'; //cuando se termine la app eliminar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //eliminar cuando se termine la app
  final dbPath = join(await getDatabasesPath(), 'rondas_app.db');
  await deleteDatabase(dbPath); // eliminar esta línea cuando se termine la app

  runApp(const MyApp());
}

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
