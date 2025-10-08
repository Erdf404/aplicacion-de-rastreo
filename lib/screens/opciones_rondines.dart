import 'package:flutter/material.dart';

class OpcionesRondines extends StatelessWidget {
  const OpcionesRondines({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            cuadromorado(size),
            logoyusuario(size),
            botonesrondines(size, context),
          ],
        ),
      ),
    );
  }

  Column botonesrondines(Size size, BuildContext context) {
    return Column(
      children: [
        SizedBox(height: size.height * 0.25),
        Container(
          padding: const EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledColor: Colors.grey,
                color: Colors.deepPurple,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Text(
                    'Rondin exterior',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, 'rondin_afuera');
                },
              ),
              SizedBox(height: 20), //espacio entre los botones
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledColor: Colors.grey,
                color: const Color.fromARGB(255, 85, 20, 198),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Text(
                    'Rondin interior',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, 'rondin_interior');
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: size.height * 0.07,
        ), //espacio entre los botones y el fondo
        Container(
          padding: const EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.deepPurple,
                  child: Text(
                    'Subir rondines',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, 'login');
                  },
                ),
              ),
              SizedBox(width: 10), // espacio entre botones
              Expanded(
                child: MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color.fromARGB(255, 85, 20, 198),
                  child: Text(
                    'Ver rondines',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, 'listado_rondines');
                    // Acción para ver rondines
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: size.height * 0.1,
        ), //espacio entre los botones y el fondo
        // Botón para cerrar sesión
        MaterialButton(
          height: size.height * 0.07,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.red,
          child: Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'login');
          },
        ),
      ],
    );
  }

  SafeArea logoyusuario(Size size) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            //logo de la escuela
            height: size.height * 0.1,
            width: size.width * 0.5,

            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/ca/TSJZapopan_Logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            //nombre del usuario
            height: size.height * 0.1,
            width: size.width * 0.4,
            child: Center(
              child: Text(
                textAlign: TextAlign.center,
                'Nombre del usuario',
                style: TextStyle(
                  color: const Color.fromARGB(255, 144, 30, 30),
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

  Container cuadromorado(Size size) {
    return Container(
      margin: EdgeInsets.only(top: size.height * 0.85),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
      ),
      width: double.infinity,
      height: size.height * 0.15,
    );
  }
}
