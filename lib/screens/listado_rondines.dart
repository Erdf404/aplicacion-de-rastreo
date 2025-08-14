import 'package:flutter/material.dart';

class ListadoRondines extends StatefulWidget {
  const ListadoRondines({super.key});

  @override
  ListadoRondinesState createState() => ListadoRondinesState();
}

class ListadoRondinesState extends State<ListadoRondines> {
  TextEditingController controlDeFecha = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            barrasuperior(size),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: size.height * 0.18,
                  ), //separacion entre la parte superior y el comienzo del listado

                  barradebusqueda(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextField barradebusqueda(BuildContext context) {
    return TextField(
      controller: controlDeFecha,
      decoration: const InputDecoration(
        labelText: 'Buscar por fecha',
        filled: true,
        prefixIcon: Icon(Icons.calendar_month),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      readOnly: true,
      onTap: () {
        elegirFecha(context);
      },
    );
  }

  SafeArea barrasuperior(Size size) {
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
                'Listado de Rondines',
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

  Future<void> elegirFecha(BuildContext context) async {
    DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (seleccionado != null) {
      setState(() {
        controlDeFecha.text = seleccionado.toString().split(" ")[0];
      });
    }
  }
}
