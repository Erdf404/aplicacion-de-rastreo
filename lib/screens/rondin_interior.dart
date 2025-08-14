import 'package:flutter/material.dart';

class RondinInterior extends StatefulWidget {
  const RondinInterior({super.key});

  @override
  State<RondinInterior> createState() => _RondinInteriorState();
}

class _RondinInteriorState extends State<RondinInterior> {
  int contador =
      0; //cambiar a que el contador aumente cuando se registre en la base de datos

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
                      //accion cuando se precione el boton de iniciar rondin
                      setState(() {
                        contador++; //aumenta el contador de lugares registrados
                      });
                    },
                    child: BotonIniciarRondin(size),
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                RegistroDePuntos(),
                SizedBox(height: size.height * 0.05),
                BotonTerminarRondin(size, context),
                SizedBox(
                  height: size.height * 0.15,
                ), //espacio entre los botones y el fondo
                BotonSalir(size, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MaterialButton BotonSalir(Size size, BuildContext context) {
    return MaterialButton(
      height: size.height * 0.07,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 130, 20, 198),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text(
          'Regresar',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      onPressed: () {
        Navigator.pushReplacementNamed(context, 'opciones_rondines');
      },
    );
  }

  MaterialButton BotonTerminarRondin(Size size, BuildContext context) {
    return MaterialButton(
      height: size.height * 0.07,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 139, 20, 198),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text(
          'Finalizar rondin',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      onPressed: () {
        Navigator.pushReplacementNamed(context, 'rondin_interior');
      },
    );
  }

  Container RegistroDePuntos() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 30),
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
                'Lugares registrados:',
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
    );
  }

  Container BotonIniciarRondin(Size size) {
    return Container(
      height: size.height * 0.25,
      width: size.height * 0.25,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 200, 67, 205), //color del circulo
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 187, 33, 243), //color de la sombra
            offset: Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 214, 123, 226),
            const Color.fromARGB(255, 185, 17, 200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'Iniciar\nRegistrar lugar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            width: size.width * 0.5,
            child: const Center(
              child: Text(
                textAlign: TextAlign.center,
                'Rondin Interior',
                style: TextStyle(
                  color: Color.fromARGB(255, 119, 30, 144),
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
