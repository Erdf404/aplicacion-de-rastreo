import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_session.dart';
import '/database/repositories/rondas_repository.dart';
import '/database/repositories/consultas_repository.dart';
import '../database/modelos.dart';
import '../widgets/pantalla_escaneo_qr.dart';

class RondinInterior extends StatefulWidget {
  const RondinInterior({super.key});

  @override
  State<RondinInterior> createState() => _RondinInteriorState();
}

class _RondinInteriorState extends State<RondinInterior> {
  // Repositories
  final RondasRepository _rondasRepo = RondasRepository();
  final ConsultasRepository _consultasRepo = ConsultasRepository();

  // Datos de la ronda
  int? _idRondaUsuario;
  int? _idRondaAsignada;
  String? _nombreTipoRonda;
  List<Map<String, dynamic>> _checkpoints = [];
  List<CoordenadaUsuario> _coordenadasRegistradas = [];

  // Estado
  bool _rondaIniciada = false;
  bool _cargando = false;
  DateTime? _horaInicio;
  int _checkpointsVerificados = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener argumentos pasados desde seleccion_ronda
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _idRondaAsignada == null) {
      _idRondaAsignada = args['id_ronda_asignada'];
      _nombreTipoRonda = args['nombre_tipo_ronda'];
      _cargarCheckpoints();
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
      // Crear registro de ronda en la BD
      final idRonda = await _rondasRepo.iniciarRonda(
        idUsuario: userSession.idUsuario!,
        idRondaAsignada: _idRondaAsignada!,
        fechaHoraInicio: DateTime.now(),
      );

      // Actualizar sesión del usuario
      userSession.iniciarRonda(
        idRondaUsuario: idRonda,
        idRondaAsignada: _idRondaAsignada!,
        tipoRonda: 'interior',
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

  Future<void> _escanearQR() async {
    // Si no se ha iniciado la ronda, iniciarla primero
    if (!_rondaIniciada) {
      await _iniciarRonda();
      if (!_rondaIniciada) return; // Si falla, no continuar
    }

    // Abrir escáner QR
    final codigoQR = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (codigoQR == null) return;

    setState(() => _cargando = true);

    try {
      // 1. Verificar que el QR existe en la BD
      final idCoordenada = await _rondasRepo.verificarCodigoQr(codigoQR);

      if (idCoordenada == null) {
        setState(() => _cargando = false);
        _mostrarError('❌ Código QR no válido');
        return;
      }

      // 2. Verificar que el QR pertenece a esta ronda
      final perteneceARonda = await _rondasRepo.verificarQrEnRondaAsignada(
        idRondaAsignada: _idRondaAsignada!,
        idCoordenadaAdmin: idCoordenada,
      );

      if (!perteneceARonda) {
        setState(() => _cargando = false);
        _mostrarError('❌ Este QR no pertenece a esta ronda');
        return;
      }

      // 3. Verificar que no se haya escaneado antes
      final yaEscaneado = _coordenadasRegistradas.any(
        (c) => c.codigoQr == codigoQR && c.verificador,
      );

      if (yaEscaneado) {
        setState(() => _cargando = false);
        _mostrarError('⚠️ Ya escaneaste este checkpoint');
        return;
      }

      // 4. declara que no hay posicion en la ronda interior

      Position? position;
      position = null;

      // 5. Registrar checkpoint en la BD
      await _rondasRepo.registrarCoordenada(
        idRondaUsuario: _idRondaUsuario!,
        latitud: position?.latitude ?? 0.0,
        longitud: position?.longitude ?? 0.0,
        codigoQrEscaneado: codigoQR,
        esValido: true,
      );

      // 6. Recargar coordenadas y actualizar contador
      await _recargarCoordenadas();

      setState(() {
        _checkpointsVerificados++;
        _cargando = false;
      });

      // Obtener nombre del checkpoint
      final checkpoint = _checkpoints.firstWhere(
        (c) => c['id_coordenada_admin'] == idCoordenada,
        orElse: () => {'nombre_coordenada': 'Checkpoint'},
      );

      _mostrarMensaje(
        '✅ ${checkpoint['nombre_coordenada']} verificado\n'
        'Progreso: $_checkpointsVerificados/${_checkpoints.length}',
        Colors.green,
      );

      // Si completó todos los checkpoints
      if (_checkpointsVerificados >= _checkpoints.length) {
        _mostrarDialogoCompletado();
      }
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al registrar QR: $e');
    }
  }

  Future<void> _recargarCoordenadas() async {
    if (_idRondaUsuario == null) return;

    final coordenadas = await _rondasRepo.obtenerCoordenadasRonda(
      _idRondaUsuario!,
    );

    setState(() => _coordenadasRegistradas = coordenadas);
  }

  void _mostrarDialogoCompletado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 ¡Todos los checkpoints verificados!'),
        content: const Text(
          'Has completado todos los puntos de la ronda.\n'
          '¿Deseas finalizar la ronda ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizarRonda();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarRonda() async {
    if (_idRondaUsuario == null) return;

    // Confirmar finalización
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Ronda'),
        content: Text(
          'Checkpoints verificados: $_checkpointsVerificados/${_checkpoints.length}\n'
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
    final porcentaje = _checkpoints.isEmpty
        ? 0
        : (_checkpointsVerificados / _checkpoints.length * 100).round();

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
            Text(
              'Checkpoints: $_checkpointsVerificados/${_checkpoints.length}',
            ),
            const SizedBox(height: 8),
            Text('Completitud: $porcentaje%'),
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

                      // Botón principal (escanear QR)
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: _cargando ? null : _escanearQR,
                          child: _botonIniciarRondin(size),
                        ),
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Información de checkpoints
                      _infoCheckpoints(),

                      SizedBox(height: size.height * 0.03),

                      // Lista de checkpoints
                      Expanded(child: _listaCheckpoints()),

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
    final porcentaje = _checkpoints.isEmpty
        ? 0
        : (_checkpointsVerificados / _checkpoints.length * 100).round();

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.qr_code_scanner,
                label: 'Verificados',
                value: '$_checkpointsVerificados/${_checkpoints.length}',
                color: Colors.purple,
              ),
              _buildInfoItem(
                icon: Icons.percent,
                label: 'Completitud',
                value: '$porcentaje%',
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
          if (_checkpoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _checkpointsVerificados / _checkpoints.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ],
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _listaCheckpoints() {
    if (_checkpoints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _checkpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = _checkpoints[index];
        final idCoordenada = checkpoint['id_coordenada_admin'];

        // Verificar si ya fue escaneado
        final escaneado = _coordenadasRegistradas.any(
          (c) => c.codigoQr == checkpoint['codigo_qr'] && c.verificador,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: escaneado ? Colors.green.shade50 : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: escaneado ? Colors.green : Colors.grey,
              child: escaneado
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text(
                      '${checkpoint['orden']}',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
            title: Text(
              checkpoint['nombre_coordenada'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: escaneado ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              'Código: ${checkpoint['codigo_qr'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: escaneado
                ? const Icon(Icons.verified, color: Colors.green)
                : const Icon(Icons.qr_code, color: Colors.grey),
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
            color: const Color.fromARGB(255, 130, 20, 198),
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

  Container _botonIniciarRondin(Size size) {
    return Container(
      height: size.height * 0.25,
      width: size.height * 0.25,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 200, 67, 205),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 187, 33, 243),
            offset: Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 214, 123, 226),
            Color.fromARGB(255, 185, 17, 200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _rondaIniciada ? Icons.qr_code_scanner : Icons.play_arrow,
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              _rondaIniciada ? 'Escanear\nQR' : 'Iniciar\nRonda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
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
            width: size.width * 0.5,
            child: Center(
              child: Text(
                textAlign: TextAlign.center,
                _nombreTipoRonda ?? 'Rondín Interior',
                style: const TextStyle(
                  color: Color.fromARGB(255, 119, 30, 144),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    _mostrarMensaje(mensaje, Colors.red);
  }
}
