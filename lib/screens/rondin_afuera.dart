import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../services/user_session.dart';
import '/database/repositories/rondas_repository.dart';
import '/database/repositories/consultas_repository.dart';
import '../database/modelos.dart';
import '../database/database_helper.dart';

class RondinAfuera extends StatefulWidget {
  const RondinAfuera({super.key});

  @override
  State<RondinAfuera> createState() => _RondinAfueraState();
}

class _RondinAfueraState extends State<RondinAfuera> {
  final RondasRepository _rondasRepo = RondasRepository();
  final ConsultasRepository _consultasRepo = ConsultasRepository();

  // Datos de la ronda
  int? _idRondaUsuario;
  int? _idRondaAsignada;
  String? _nombreTipoRonda;
  double _distanciaPermitida =
      50.0; //distancia permitida en caso de no cargar de la base de datos
  List<Map<String, dynamic>> _checkpoints = [];
  List<CoordenadaUsuario> _coordenadasRegistradas = [];

  // Estado
  bool _rondaIniciada = false;
  bool _cargando = false;
  DateTime? _horaInicio;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener informacion anterior desde seleccion_ronda
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _idRondaAsignada == null) {
      _idRondaAsignada = args['id_ronda_asignada'];
      _nombreTipoRonda = args['nombre_tipo_ronda'];
      _cargarCheckpoints();
      _cargarDistanciaPermitida();
    }
  }

  Future<void> _cargarDistanciaPermitida() async {
    if (_idRondaAsignada == null) return;
    try {
      final db = await DatabaseHelper().database;

      final result = await db.query(
        'ronda_asignada',
        columns: ['distancia_permitida'],
        where: 'id_ronda_asignada = ?',
        whereArgs: [_idRondaAsignada],
        limit: 1,
      );
      if (result.isNotEmpty) {
        setState(() {
          _distanciaPermitida = (result.first['distancia_permitida'] as num)
              .toDouble();
        });
      }
    } catch (e) {
      print('error al cargar distancia permitida: $e');
    }
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
        _mostrarError('Permiso de ubicación denegado');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _mostrarError(
        'Permiso denegado permanentemente. Habilítalo en configuración',
      );
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _cargarCheckpoints() async {
    if (_idRondaAsignada == null) return;

    setState(() => _cargando = true);

    final checkpoints = await _consultasRepo.obtenerCheckpointsRondaAsignada(
      _idRondaAsignada!,
    );

    setState(() {
      _checkpoints = checkpoints;
      _cargando = false;
    });
  }

  Future<void> _iniciarRonda() async {
    if (_idRondaAsignada == null) {
      _mostrarError('No se ha seleccionado una ronda');
      return;
    }

    setState(() => _cargando = true);

    final userSession = Provider.of<UserSession>(context, listen: false);

    try {
      // Crear registro de ronda en la base de datos
      final idRonda = await _rondasRepo.iniciarRonda(
        idUsuario: userSession.idUsuario!,
        idRondaAsignada: _idRondaAsignada!,
        fechaHoraInicio: DateTime.now(),
      );

      // Actualizar sesión del usuario
      userSession.iniciarRonda(
        idRondaUsuario: idRonda,
        idRondaAsignada: _idRondaAsignada!,
        tipoRonda: 'exterior',
      );

      setState(() {
        _idRondaUsuario = idRonda;
        _rondaIniciada = true;
        _horaInicio = DateTime.now();
        _cargando = false;
      });

      _mostrarMensaje('Ronda iniciada correctamente', Colors.green);
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al iniciar ronda: $e');
    }
  }

  Future<void> _marcarPunto() async {
    if (!_rondaIniciada) {
      await _iniciarRonda();
      return;
    }

    setState(() => _cargando = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Verifica si está cerca de algún checkpoint
      bool estaCercaDeCheckpoint = false;
      int? idCheckpointCercano;

      for (var checkpoint in _checkpoints) {
        final distancia = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          checkpoint['latitud'],
          checkpoint['longitud'],
        );

        if (distancia <= _distanciaPermitida) {
          //distancia permitida al rededor del punto, cambiar a que se conecte a la base de datos
          estaCercaDeCheckpoint = true;
          idCheckpointCercano = checkpoint['id_coordenada_admin'];
          break;
        }
      }

      // Guardar con validación
      await _rondasRepo.registrarCoordenada(
        idRondaUsuario: _idRondaUsuario!,
        latitud: position.latitude,
        longitud: position.longitude,
        esValido: estaCercaDeCheckpoint,
      );

      if (estaCercaDeCheckpoint) {
        _mostrarMensaje(' Checkpoint verificado', Colors.green);
      } else {
        _mostrarMensaje(
          '⚠️ No estás cerca de ningún checkpoint',
          Colors.orange,
        );
      }

      await _recargarCoordenadas();
      setState(() => _cargando = false);
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('No se pudo obtener la ubicación');
    }
  }

  Future<void> _recargarCoordenadas() async {
    if (_idRondaUsuario == null) return;

    final coordenadas = await _rondasRepo.obtenerCoordenadasRonda(
      _idRondaUsuario!,
    );

    setState(() => _coordenadasRegistradas = coordenadas);
  }

  Future<void> _finalizarRonda() async {
    if (_idRondaUsuario == null) return;

    // Confirmar finalización
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Ronda'),
        content: Text(
          'Se registraron ${_coordenadasRegistradas.length} puntos.\n'
          '¿Deseas finalizar la ronda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _cargando = true);

    try {
      // Actualizar hora final en la BD
      await _rondasRepo.finalizarRonda(
        idRondaUsuario: _idRondaUsuario!,
        fechaHoraFinal: DateTime.now(),
      );

      // Limpiar sesión
      final userSession = Provider.of<UserSession>(context, listen: false);
      userSession.finalizarRonda();

      setState(() => _cargando = false);

      // Mostrar resumen
      _mostrarDialogoResumen();
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al finalizar ronda: $e');
    }
  }

  void _mostrarDialogoResumen() {
    final duracion = DateTime.now().difference(_horaInicio!);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Ronda Completada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $_nombreTipoRonda'),
            const SizedBox(height: 8),
            Text('Puntos registrados: ${_coordenadasRegistradas.length}'),
            const SizedBox(height: 8),
            Text('Duración: ${horas}h ${minutos}m'),
            const SizedBox(height: 8),
            Text('Inicio: ${DateFormat('HH:mm').format(_horaInicio!)}'),
            Text('Fin: ${DateFormat('HH:mm').format(DateTime.now())}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a opciones
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        if (_rondaIniciada) {
          final salir = await _confirmarSalida();
          return salir ?? false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  _logoyusuario(size),
                  Column(
                    children: [
                      SizedBox(height: size.height * 0.2),

                      // Botón principal (marcar punto)
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: _cargando ? null : _marcarPunto,
                          child: _botondeiniciar(size),
                        ),
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Información de checkpoints
                      _infoCheckpoints(),

                      SizedBox(height: size.height * 0.03),

                      // Lista de puntos registrados
                      Expanded(child: _listaPuntosRegistrados()),

                      // Botones de acción
                      _botonesAccion(size),
                    ],
                  ),
                ],
              ),
            ),

            // Overlay de carga
            if (_cargando)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCheckpoints() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.location_on,
            label: 'Puntos',
            value: '${_coordenadasRegistradas.length}',
            color: Colors.blue,
          ),
          if (_checkpoints.isNotEmpty)
            _buildInfoItem(
              icon: Icons.check_circle,
              label: 'Checkpoints',
              value: '${_checkpoints.length}',
              color: Colors.green,
            ),
          if (_rondaIniciada && _horaInicio != null)
            _buildInfoItem(
              icon: Icons.access_time,
              label: 'Inicio',
              value: DateFormat('HH:mm').format(_horaInicio!),
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _listaPuntosRegistrados() {
    if (_coordenadasRegistradas.isEmpty) {
      return const Center(
        child: Text(
          'No hay puntos registrados',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _coordenadasRegistradas.length,
      itemBuilder: (context, index) {
        final coord = _coordenadasRegistradas[index];
        final hora = DateTime.parse(coord.horaActual);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(DateFormat('HH:mm:ss').format(hora)),
            subtitle: Text(
              'Lat: ${coord.latitudActual.toStringAsFixed(6)}\n'
              'Lng: ${coord.longitudActual.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _botonesAccion(Size size) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_rondaIniciada) ...[
            MaterialButton(
              height: size.height * 0.07,
              minWidth: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.green,
              onPressed: _cargando ? null : _finalizarRonda,
              child: const Text(
                'Finalizar Ronda',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
          ],
          MaterialButton(
            height: size.height * 0.07,
            minWidth: double.infinity,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: const Color.fromARGB(255, 198, 20, 59),
            onPressed: () async {
              if (_rondaIniciada) {
                final salir = await _confirmarSalida();
                if (salir == true && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Regresar',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Container _botondeiniciar(Size size) {
    return Container(
      height: size.height * 0.25,
      width: size.height * 0.25,
      decoration: BoxDecoration(
        color: Colors.blue[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade500,
            offset: const Offset(5, 5),
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
      child: Center(
        child: Text(
          _rondaIniciada ? 'Marcar\nPunto' : 'Iniciar\nRonda',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  SafeArea _logoyusuario(Size size) {
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
            child: Center(
              child: Text(
                textAlign: TextAlign.center,
                _nombreTipoRonda ?? 'Rondín Exterior',
                style: const TextStyle(
                  color: Color.fromARGB(255, 127, 30, 144),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmarSalida() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ronda en curso'),
        content: const Text(
          'Tienes una ronda activa.\n¿Deseas salir sin finalizarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    _mostrarMensaje(mensaje, Colors.red);
  }
}
