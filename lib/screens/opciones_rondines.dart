import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_session.dart';
import '../services/sync_service.dart.dart';
import '../database/database_helper.dart';
import '/database/repositories/consultas_repository.dart';

class OpcionesRondines extends StatefulWidget {
  const OpcionesRondines({super.key});

  @override
  State<OpcionesRondines> createState() => _OpcionesRondinesState();
}

class _OpcionesRondinesState extends State<OpcionesRondines> {
  final ConsultasRepository _consultasRepo = ConsultasRepository();
  Map<String, dynamic>? _estadisticas;
  bool _cargandoEstadisticas = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final userSession = Provider.of<UserSession>(context, listen: false);

    if (userSession.idUsuario != null) {
      final stats = await _consultasRepo.obtenerEstadisticasUsuario(
        userSession.idUsuario!,
      );

      setState(() {
        _estadisticas = stats;
        _cargandoEstadisticas = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userSession = Provider.of<UserSession>(context);

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            _cuadromorado(size),
            _logoyusuario(size, userSession),
            _botonesrondines(size, context, userSession),
          ],
        ),
      ),
    );
  }

  Column _botonesrondines(
    Size size,
    BuildContext context,
    UserSession userSession,
  ) {
    return Column(
      children: [
        SizedBox(height: size.height * 0.25),

        // Tarjeta de estadísticas
        if (!_cargandoEstadisticas && _estadisticas != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.assignment_turned_in,
                  label: 'Completadas',
                  value: '${_estadisticas!['total_rondas']}',
                ),
                _buildStatItem(
                  icon: Icons.pending_actions,
                  label: 'Pendientes',
                  value: '${_estadisticas!['rondas_pendientes']}',
                ),
              ],
            ),
          ),

        SizedBox(height: size.height * 0.03),

        // Botones principales
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Botón: Ejecutar Ronda
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.deepPurple,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: const Text(
                    'Ejecutar Ronda',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                onPressed: () {
                  // Verifica si hay rondas pendientes
                  if (_estadisticas != null &&
                      _estadisticas!['rondas_pendientes'] > 0) {
                    Navigator.pushNamed(context, 'seleccion_ronda');
                  } else {
                    _mostrarMensaje('No tienes rondas asignadas');
                  }
                },
              ),
            ],
          ),
        ),

        SizedBox(height: size.height * 0.07),

        // Botones secundarios
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón: Ver Historial
              Expanded(
                child: MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.deepPurple,
                  child: const Text(
                    'Ver Historial',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, 'listado_rondines');
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Botón: subir Rondas a la nube
              Expanded(
                child: MaterialButton(
                  height: size.height * 0.07,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color.fromARGB(255, 85, 20, 198),
                  child: const Text(
                    'Subir rondas',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () {
                    _mostrarDialogoActualizar();
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: size.height * 0.1),

        // Botón: Cerrar Sesión
        MaterialButton(
          height: size.height * 0.07,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.red,
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          onPressed: () => _cerrarSesion(context, userSession),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.deepPurple),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  SafeArea _logoyusuario(Size size, UserSession userSession) {
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
                userSession.nombreCorto,
                style: const TextStyle(
                  color: Color.fromARGB(255, 144, 30, 30),
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

  Container _cuadromorado(Size size) {
    return Container(
      margin: EdgeInsets.only(top: size.height * 0.85),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
      ),
      width: double.infinity,
      height: size.height * 0.15,
    );
  }

  void _mostrarDialogoActualizar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar Rondas'),
        content: const Text(
          'Esto subirá tus rondas ejecutadas al servidor.\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sincronizarRondas();
            },
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sincronizarRondas() async {
    final userSession = Provider.of<UserSession>(context, listen: false);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Sincronizar
    final syncService = SyncService();
    final resultado = await syncService.sincronizarRondasPendientes(
      userSession.idUsuario!,
    );

    if (mounted) {
      Navigator.pop(context); // Cerrar loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(resultado['success'] ? '✅ Éxito' : '⚠️ Atención'),
          content: Text(resultado['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cerrarSesion(
    BuildContext context,
    UserSession userSession,
  ) async {
    // Siempre borrar datos de la nube al cerrar sesión
    // para que el siguiente usuario no vea rondas ajenas
    await DatabaseHelper().borrarDatosNube();

    // Preguntar si también borrar las rondas ejecutadas localmente
    final borrarRondas = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text(
          '¿Deseas eliminar también las rondas que realizaste?\n\n'
          '⚠️ Si no las eliminas, deberás sincronizarlas con el servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mantener rondas'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (borrarRondas == true) {
      await DatabaseHelper().borrarTodosDatos();
    }

    userSession.cerrarSesion();

    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
