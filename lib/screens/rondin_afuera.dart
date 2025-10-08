import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class RondinAfuera extends StatefulWidget {
  const RondinAfuera({super.key});

  @override
  State<RondinAfuera> createState() => _RondinAfueraState();
}

class PuntoRondin {
  final DateTime tiempo;
  final double latitud;
  final double longitud;

  PuntoRondin({
    required this.tiempo,
    required this.latitud,
    required this.longitud,
  });
}

class _RondinAfueraState extends State<RondinAfuera> {
  List<PuntoRondin> puntos = [];
  DateTime? primerTiempo;
  DateTime? ultimoTiempo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Permiso denegado");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print(
        "Permiso denegado permanentemente. Abra la configuracion para cambiarlo manualmente",
      );
      await Geolocator.openAppSettings();
      return;
    }
  }

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
                    //boton de marcar punto
                    onTap: () async {
                      try {
                        // Intentar obtener la posición con un límite de 5 segundos
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(
                            seconds:
                                5, //tiempo maximo para obtener la ubicacion
                          ),
                        );

                        setState(() {
                          DateTime ahora = DateTime.now();
                          primerTiempo ??= ahora;
                          ultimoTiempo = ahora;
                          puntos.add(
                            PuntoRondin(
                              tiempo: ahora,
                              latitud: position.latitude,
                              longitud: position.longitude,
                            ),
                          );
                        });

                        print("Punto guardado");
                      } catch (e) {
                        // Si no se obtiene la ubicación a tiempo o hay error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No se pudo obtener la ubicación a tiempo.',
                            ),
                          ),
                        );
                      }
                    },
                    child: botondeiniciar(size),
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                selectorrondas(),
                SizedBox(height: size.height * 0.05),
                botondeterminar(size, context),
                SizedBox(
                  height: size.height * 0.15,
                ), //espacio entre los botones y el fondo
                botondesalir(size, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MaterialButton botondesalir(Size size, BuildContext context) {
    return MaterialButton(
      height: size.height * 0.07,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 198, 20, 59),
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

  MaterialButton botondeterminar(Size size, BuildContext context) {
    return MaterialButton(
      height: size.height * 0.07,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 85, 20, 198),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text(
          'Finalizar rondin',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Tiempos marcados"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Inicio: ${primerTiempo != null ? DateFormat('dd MMM yyyy HH:mm').format(primerTiempo!) : '--:--'}  "
                      "Fin: ${ultimoTiempo != null ? DateFormat('dd MMM yyyy HH:mm').format(ultimoTiempo!) : '--:--'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: puntos.length,
                        itemBuilder: (context, index) {
                          final punto = puntos[index];
                          final horaFormateada = DateFormat(
                            'HH:mm',
                          ).format(punto.tiempo);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              "${index + 1}. Hora: $horaFormateada\n"
                              "Lat: ${punto.latitud.toStringAsFixed(3)}, "
                              "Lng: ${punto.longitud.toStringAsFixed(3)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    for (var puntos in puntos) {
                      print(
                        "Hora: ${puntos.tiempo}, Latitud: ${puntos.latitud}, Longitud: ${puntos.longitud}",
                      );
                    }
                    setState(() {
                      puntos.clear();
                      primerTiempo = null;
                      ultimoTiempo = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Aceptar"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: Text("continuar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Container selectorrondas() {
    return Container(
      child: ElevatedButton(
        child: const Text("Rondas asignadas"),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: 10, // Número de rondas disponibles
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Ronda ${index + 1}'),
                      onTap: () {
                        // Acción al seleccionar una ronda
                        Navigator.pop(context); // Cerrar el modal
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Container botondeiniciar(Size size) {
    return Container(
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
                'Rondin Exterior',
                style: TextStyle(
                  color: Color.fromARGB(255, 127, 30, 144),
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
