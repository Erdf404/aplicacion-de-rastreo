import 'package:flutter/material.dart';

class RondinInterior extends StatelessWidget {
  const RondinInterior({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        child: Center(
          child: Text(
            'Rondin Interior',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
