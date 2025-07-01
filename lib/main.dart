import 'package:flutter/material.dart';
import 'package:aplicacion_rondines/screens/login_screen.dart';
import 'package:aplicacion_rondines/screens/opciones_rondines.dart';

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
      },
      initialRoute: 'login',
    );
  }
}
