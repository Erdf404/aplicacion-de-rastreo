import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/user_session.dart';
import '/database/repositories/consultas_repository.dart';

class SeleccionRonda extends StatefulWidget {
  const SeleccionRonda({super.key});

  @override
  State<SeleccionRonda> createState() => _SeleccionRondaState();
}

class _SeleccionRondaState extends State<SeleccionRonda> {
  final ConsultasRepository _consultasRepo = ConsultasRepository();
  List<Map<String, dynamic>> _rondasAsignadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRondasAsignadas();
  }

  Future<void> _cargarRondasAsignadas() async {
    final userSession = Provider.of<UserSession>(context, listen: false);

    if (userSession.idUsuario == null) {
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    final rondas = await _consultasRepo.obtenerRondasAsignadas(
      userSession.idUsuario!,
    );

    setState(() {
      _rondasAsignadas = rondas;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            _logoyusuario(size),
            Column(
              children: [
                SizedBox(height: size.height * 0.15),

                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Selecciona una ronda para ejecutar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Lista de rondas
                Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _rondasAsignadas.isEmpty
                      ? _buildEmptyState()
                      : _buildListaRondas(),
                ),

                // Botón regresar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: MaterialButton(
                    height: size.height * 0.07,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.grey,
                    child: const Text(
                      'Regresar',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaRondas() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _rondasAsignadas.length,
      itemBuilder: (context, index) {
        final ronda = _rondasAsignadas[index];
        return _buildTarjetaRonda(ronda);
      },
    );
  }

  Widget _buildTarjetaRonda(Map<String, dynamic> ronda) {
    final fechaEjecucion = DateTime.parse(ronda['fecha_de_ejecucion']);
    final horaEjecucion = DateTime.parse(ronda['hora_de_ejecucion']);

    final fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaEjecucion);
    final horaFormateada = DateFormat('HH:mm').format(horaEjecucion);

    // Determinar el tipo de ronda (exterior/interior)

    final esExterior = ronda['id_tipo'] == 1;

    final icono = esExterior ? Icons.location_on : Icons.qr_code_scanner;
    final color = esExterior ? Colors.blue : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _seleccionarRonda(ronda, esExterior),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: 30),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ronda['nombre_tipo_ronda'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          fechaFormateada,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          horaFormateada,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${ronda['total_checkpoints']} checkpoints',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No tienes rondas asignadas',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Contacta a tu administrador',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
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
            child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
          ),
          SizedBox(
            height: size.height * 0.1,
            width: size.width * 0.4,
            child: const Center(
              child: Text(
                textAlign: TextAlign.center,
                'Selección de Ronda',
                style: TextStyle(
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

  void _seleccionarRonda(Map<String, dynamic> ronda, bool esExterior) {
    final args = {
      'id_ronda_asignada': ronda['id_ronda_asignada'],
      'nombre_tipo_ronda': ronda['nombre_tipo_ronda'],
      'total_checkpoints': ronda['total_checkpoints'],
    };

    if (esExterior) {
      Navigator.pushNamed(context, 'rondin_afuera', arguments: args);
    } else {
      Navigator.pushNamed(context, 'rondin_interior', arguments: args);
    }
  }
}
