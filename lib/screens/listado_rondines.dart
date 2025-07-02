import 'package:flutter/material.dart';

class ListadoRondines extends StatelessWidget {
  const ListadoRondines({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Text(
            'listado rondines',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
