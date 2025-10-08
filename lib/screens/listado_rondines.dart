import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListadoRondines extends StatefulWidget {
  const ListadoRondines({super.key});

  @override
  ListadoRondinesState createState() => ListadoRondinesState();
}

class ListadoRondinesState extends State<ListadoRondines> {
  TextEditingController controlDeFecha = TextEditingController();

  // Datos de ejemplo con fecha
  final List<Map<String, String>> todosRondines = List.generate(50, (index) {
    final fecha = DateTime.now().add(Duration(days: index % 5));
    final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    return {"Hora": "08:00 AM", "Fecha": fechaStr};
  });

  List<Map<String, String>> rondinesFiltrados = [];
  bool seleccionarTodos = false; // Estado del checkbox de encabezado
  final Map<int, bool> seleccionados = {}; // Estado de checkboxes por fila

  @override
  void initState() {
    super.initState();
    rondinesFiltrados = List.from(todosRondines);
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
            barrasuperior(size),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.18),
                  barradebusqueda(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: PaginatedDataTable(
                        header: const Text('Rondines'),
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value: seleccionarTodos,
                              onChanged: (valor) {
                                if (valor == null) return;
                                setState(() {
                                  seleccionarTodos = valor;
                                  // Actualizar todos los checkboxes de filas
                                  for (
                                    int i = 0;
                                    i < rondinesFiltrados.length;
                                    i++
                                  ) {
                                    seleccionados[i] = valor;
                                  }
                                });
                              },
                            ),
                          ),
                          const DataColumn(label: Text('Fecha')),
                          const DataColumn(label: Text('Hora')),
                        ],
                        source: RondinesDataSource(
                          rondinesFiltrados,
                          seleccionados: seleccionados,
                          onChanged: (index, valor) {
                            setState(() {
                              seleccionados[index] = valor;
                              // Actualizar checkbox del encabezado si todos están marcados
                              seleccionarTodos =
                                  seleccionados.length ==
                                      rondinesFiltrados.length &&
                                  !seleccionados.containsValue(false);
                            });
                          },
                        ),
                        rowsPerPage: 10,
                        availableRowsPerPage: const [5, 10, 20],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Ejemplo: imprimir los rondines seleccionados
                          final seleccion = seleccionados.entries
                              .where((e) => e.value)
                              .map((e) => rondinesFiltrados[e.key]["Nombre"])
                              .toList();
                          print("Rondines seleccionados: $seleccion");
                        },
                        child: const Text('Generar PDF'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            'opciones_rondines',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Regresar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
      decoration: InputDecoration(
        labelText: 'Buscar por fecha',
        filled: true,
        prefixIcon: const Icon(Icons.calendar_month),
        suffixIcon: controlDeFecha.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    controlDeFecha.clear();
                    rondinesFiltrados = List.from(todosRondines);
                    seleccionados.clear();
                    seleccionarTodos = false;
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
      final fechaStr = DateFormat('yyyy-MM-dd').format(seleccionado);
      setState(() {
        controlDeFecha.text = fechaStr;
        rondinesFiltrados = todosRondines
            .where((r) => r["Fecha"] == fechaStr)
            .toList();
        seleccionados.clear();
        seleccionarTodos = false;
      });
    }
  }
}

// Fuente de datos para la tabla paginada con checkbox en la primera columna
class RondinesDataSource extends DataTableSource {
  final List<Map<String, String>> rondines;
  final Map<int, bool> seleccionados;
  final Function(int index, bool valor) onChanged;

  RondinesDataSource(
    this.rondines, {
    required this.seleccionados,
    required this.onChanged,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= rondines.length) return null;
    final ronda = rondines[index];
    final isSelected = seleccionados[index] ?? false;

    return DataRow(
      cells: [
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (valor) {
              if (valor == null) return;
              onChanged(index, valor);
            },
          ),
        ),
        DataCell(Text(ronda["Fecha"]!)),
        DataCell(Text(ronda["Hora"]!)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rondines.length;
  @override
  int get selectedRowCount => seleccionados.values.where((v) => v).length;
}
