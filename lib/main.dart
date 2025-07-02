import 'package:flutter/material.dart';
import 'package:aplicacion_rondines/screens/login_screen.dart';
import 'package:aplicacion_rondines/screens/opciones_rondines.dart';
import 'package:aplicacion_rondines/screens/rondin_afuera.dart';
import 'package:aplicacion_rondines/screens/rondin_interior.dart';
import 'package:aplicacion_rondines/screens/listado_rondines.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routes: {
        'login': (_) => LoginScreen(),
        'opciones_rondines': (_) => OpcionesRondines(),
        'rondin_afuera': (_) => RondinAfuera(),
        'rondin_interior': (_) => RondinInterior(),
        'listado_rondines': (_) => ListadoRondines(),
      },
      initialRoute: 'login',
    );
  }
}
