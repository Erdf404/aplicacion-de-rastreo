import 'package:flutter/material.dart';

class RondinAfuera extends StatelessWidget {
  const RondinAfuera({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Text(
            'Rondin Aire Libre',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
