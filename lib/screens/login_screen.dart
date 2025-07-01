import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            cajaarriba(size),
            iconousuario(),
            cajalogin(size, context),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView cajalogin(Size size, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        //caja para el login
        children: [
          SizedBox(height: size.height * 0.35), //de donde empieza la caja
          Container(
            padding: EdgeInsets.all(20), //padding de la caja
            margin: EdgeInsets.symmetric(
              horizontal: 30, //separacion de la caja a los lados
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, //color de fondo de la caja
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                //sombreado a la caja
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(5, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 10), //espacio entre el borde y el texto
                Text(
                  //titulo dentro de la caja
                  'Login',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                SizedBox(height: 30), //espacio entre el titulo y la caja
                Container(
                  child: Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        TextFormField(
                          autocorrect: false, //desactivar autocorrección
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            String pattern =
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; //exprecion regular para validar un correo
                            RegExp regExp = new RegExp(pattern);
                            return regExp.hasMatch(value ?? '')
                                ? null
                                : 'correo electronico invalido'; //mensaje de error si el correo no es válido
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20), //espacio entre los campos
                        TextFormField(
                          autocorrect: false, //desactivar autocorrección
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true, //ocultar texto de la contraseña
                          validator: (value) {
                            return (value != null && value.length >= 6)
                                ? null
                                : 'La contraseña es de minimo 6 caracteres'; //mensaje de error si la contraseña no es válida
                          },
                        ),
                        SizedBox(height: 20), //espacio entre los campos
                        MaterialButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledColor: Colors.grey,
                          color: Colors.deepPurple,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 70,
                              vertical: 20,
                            ),
                            child: Text(
                              'Ingresar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
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
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          Text(
            'Recuperar contraseña',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  SafeArea iconousuario() {
    return SafeArea(
      //espacio para evitar que el icono se superponga con la barra de estado
      child: Container(
        margin: EdgeInsets.only(top: 30),
        width: double.infinity,
        child: Icon(
          Icons.person_pin,
          size: 100,
          color: Colors.white,
        ), //icono de usuario con caracteristicas
      ),
    );
  }

  Container cajaarriba(Size size) {
    return Container(
      //fondo de pantalla de la parte superior
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
      ),
      width: double.infinity,
      height: size.height * 0.4,
    );
  }
}
