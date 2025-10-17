import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_session.dart';
import '../Database/repositories/consultas_repository.dart';

class ListadoRondines extends StatefulWidget {
  const ListadoRondines({super.key});

  @override
  ListadoRondinesState createState() => ListadoRondinesState();
}

class ListadoRondinesState extends State<ListadoRondines> {
  final ConsultasRepository _consultasRepo = ConsultasRepository();
  final TextEditingController _controlDeFecha = TextEditingController();

  List<Map<String, dynamic>> _todasLasRondas = [];
  List<Map<String, dynamic>> _rondasFiltradas = [];
  bool _cargando = true;
  final Map<int, bool> _seleccionados = {};

  @override
  void initState() {
    super.initState();
    _cargarRondas();
  }

  @override
  void dispose() {
    _controlDeFecha.dispose();
    super.dispose();
  }

  Future<void> _cargarRondas() async {
    final userSession = Provider.of<UserSession>(context, listen: false);

    if (userSession.idUsuario == null) {
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    setState(() => _cargando = true);

    try {
      final rondas = await _consultasRepo.obtenerHistorialRondas(
        userSession.idUsuario!,
      );

      setState(() {
        _todasLasRondas = rondas;
        _rondasFiltradas = rondas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar rondas: $e');
    }
  }

  void _filtrarPorFecha(String fecha) {
    setState(() {
      if (fecha.isEmpty) {
        _rondasFiltradas = List.from(_todasLasRondas);
      } else {
        _rondasFiltradas = _todasLasRondas
            .where((r) => r['fecha'] == fecha)
            .toList();
      }
      _seleccionados.clear();
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
            _barrasuperior(size),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.18),

                  // Barra de búsqueda
                  _barradebusqueda(context),

                  const SizedBox(height: 20),

                  // Lista de rondas
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : _rondasFiltradas.isEmpty
                        ? _buildEmptyState()
                        : _buildListaRondas(),
                  ),

                  const SizedBox(height: 20),

                  // Botones
                  _buildBotones(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaRondas() {
    return ListView.builder(
      itemCount: _rondasFiltradas.length,
      itemBuilder: (context, index) {
        final ronda = _rondasFiltradas[index];
        final isSelected = _seleccionados[index] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (valor) {
                setState(() {
                  _seleccionados[index] = valor ?? false;
                });
              },
            ),
            title: Text(
              ronda['nombre_tipo_ronda'] ?? 'Ronda',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatearFecha(ronda['fecha']),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      '${_formatearHora(ronda['hora_inicio'])} - ${_formatearHora(ronda['hora_final'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Checkpoints: ${ronda['checkpoints_verificados']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _verDetalle(ronda['id_ronda_usuario']),
            ),
          ),
        );
      },
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
            _controlDeFecha.text.isEmpty
                ? 'No has realizado rondas aún'
                : 'No hay rondas en esta fecha',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_controlDeFecha.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _controlDeFecha.clear();
                  _rondasFiltradas = List.from(_todasLasRondas);
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtro'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotones(BuildContext context) {
    final haySeleccionados = _seleccionados.values.any((v) => v);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: haySeleccionados ? _generarReporte : null,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar Reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Regresar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  TextField _barradebusqueda(BuildContext context) {
    return TextField(
      controller: _controlDeFecha,
      decoration: InputDecoration(
        labelText: 'Buscar por fecha',
        filled: true,
        prefixIcon: const Icon(Icons.calendar_month),
        suffixIcon: _controlDeFecha.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controlDeFecha.clear();
                    _filtrarPorFecha('');
                  });
                },
              )
            : null,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      readOnly: true,
      onTap: () => _elegirFecha(context),
    );
  }

  SafeArea _barrasuperior(Size size) {
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
                'Historial de Rondas',
                style: TextStyle(
                  color: Color.fromARGB(255, 119, 30, 144),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirFecha(BuildContext context) async {
    DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (seleccionado != null) {
      final fechaStr = DateFormat('yyyy-MM-dd').format(seleccionado);
      setState(() {
        _controlDeFecha.text = _formatearFecha(fechaStr);
        _filtrarPorFecha(fechaStr);
      });
    }
  }

  Future<void> _verDetalle(int idRondaUsuario) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detalle = await _consultasRepo.obtenerDetalleRondaEjecutada(
        idRondaUsuario,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (detalle == null) {
        _mostrarError('No se encontró información de la ronda');
        return;
      }

      // Mostrar diálogo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detalle['nombre_tipo_ronda'] ?? 'Detalle de Ronda'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalleItem('Fecha', _formatearFecha(detalle['fecha'])),
                _buildDetalleItem(
                  'Hora inicio',
                  _formatearHora(detalle['hora_inicio']),
                ),
                _buildDetalleItem(
                  'Hora fin',
                  _formatearHora(detalle['hora_final']),
                ),
                _buildDetalleItem(
                  'Usuario',
                  detalle['nombre_usuario'] ?? 'N/A',
                ),
                const Divider(height: 20),
                const Text(
                  'Coordenadas registradas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (detalle['coordenadas'] != null)
                  ...(detalle['coordenadas'] as List).map((coord) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            coord['verificador'] == 1
                                ? Icons.check_circle
                                : Icons.location_on,
                            size: 16,
                            color: coord['verificador'] == 1
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${coord['nombre_coordenada'] ?? 'Punto'} - '
                              '${_formatearHora(coord['hora_actual'])}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError('Error al cargar detalle: $e');
      }
    }
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _generarReporte() {
    final seleccionadas = _seleccionados.entries
        .where((e) => e.value)
        .map((e) => _rondasFiltradas[e.key])
        .toList();

    if (seleccionadas.isEmpty) {
      _mostrarError('No hay rondas seleccionadas');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar Reporte'),
        content: Text(
          'Se generará un reporte con ${seleccionadas.length} ronda(s).\n\n'
          'Esta funcionalidad estará disponible próximamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return fecha;
    }
  }

  String _formatearHora(String? hora) {
    if (hora == null || hora.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(hora);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return hora;
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }
}
