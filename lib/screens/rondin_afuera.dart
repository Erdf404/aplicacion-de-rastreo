import 'package:flutter/material.dart';

class RondinAfuera extends StatefulWidget {
  const RondinAfuera({super.key});

  @override
  State<RondinAfuera> createState() => _RondinAfueraState();
}

class _RondinAfueraState extends State<RondinAfuera> {
  int contador = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            logousername(size),
            Column(
              children: [
                SizedBox(height: size.height * 0.2),
                Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        contador++;
                      });

                      // Acción del botón
                      Navigator.pushReplacementNamed(
                        context,
                        'opciones_rondines',
                      );
                    },
                    child: Container(
                      height: size.height * 0.25,
                      width: size.height * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade500,
                            offset: Offset(5, 5),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade200, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Iniciar\nMarcar punto',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SizedBox(
                          child: Text(
                            'Puntos registrados:',
                            style: TextStyle(
                              color: Color.fromARGB(255, 33, 30, 30),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          child: Text(
                            '$contador',
                            style: TextStyle(
                              color: Color.fromARGB(255, 33, 30, 30),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color.fromARGB(255, 85, 20, 198),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Text(
                      'Finalizar rondin',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, 'rondin_afuera');
                  },
                ),
                SizedBox(
                  height: size.height * 0.15,
                ), //espacio entre los botones y el fondo
                MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color.fromARGB(255, 85, 20, 198),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Text(
                      'Regresar',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      'opciones_rondines',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SafeArea logousername(Size size) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: size.height * 0.1,
            width: size.width * 0.5,
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/ca/TSJZapopan_Logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            height: size.height * 0.1,
            width: size.width * 0.4,
            child: const Center(
              child: Text(
                textAlign: TextAlign.center,
                'Nombre del usuario',
                style: TextStyle(
                  color: Color.fromARGB(255, 144, 30, 30),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
