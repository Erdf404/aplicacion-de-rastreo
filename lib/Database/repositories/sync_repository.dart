// Repositorio encargado de sincronizar datos entre la nube y la base de datos local

import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../modelos.dart';

class SyncRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // IMPORTAR TODOS LOS DATOS DESDE JSON

  // Este método recibe el JSON completo desde la nube y lo guarda en la BD local

  Future<bool> importarDatosDesdeNube(Map<String, dynamic> jsonData) async {
    final db = await _dbHelper.database;

    try {
      await _dbHelper.borrarDatosNube();
      await db.transaction((txn) async {
        // 1. Guardar tipo de usuario
        if (jsonData['usuario']?['tipo_usuario'] != null) {
          final tipoUsuario = TipoUsuario.fromJson(
            jsonData['usuario']['tipo_usuario'],
          );
          await txn.insert(
            'tipos_de_usuarios',
            tipoUsuario.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // 2. Guardar usuario
        if (jsonData['usuario'] != null) {
          final usuario = Usuario.fromJson(jsonData['usuario']);
          await txn.insert(
            'usuarios',
            usuario.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // 3. Guardar tipos de ronda
        if (jsonData['tipos_ronda'] != null) {
          final List<dynamic> tiposRonda = jsonData['tipos_ronda'];
          for (var tipoJson in tiposRonda) {
            final tipoRonda = TipoRonda.fromJson(tipoJson);
            await txn.insert(
              'Tipo_ronda',
              tipoRonda.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // 4. Guardar coordenadas admin
        if (jsonData['coordenadas_admin'] != null) {
          final List<dynamic> coordenadas = jsonData['coordenadas_admin'];

          for (var coordJson in coordenadas) {
            try {
              final coordenada = CoordenadaAdmin(
                idCoordenadaAdmin: coordJson['id_coordenada_admin'],
                latitud: coordJson['latitud'] != null
                    ? (coordJson['latitud'] as num).toDouble()
                    : null,
                longitud: coordJson['longitud'] != null
                    ? (coordJson['longitud'] as num).toDouble()
                    : null,
                nombreCoordenada: coordJson['nombre_coordenada'] ?? '',
                codigoQr: coordJson['codigo_qr'],
              );

              await txn.insert('Coordenadas_admin', {
                'id_coordenada_admin': coordenada.idCoordenadaAdmin,
                'latitud': coordenada.latitud,
                'longitud': coordenada.longitud,
                'nombre_coordenada': coordenada.nombreCoordenada,
                'codigo_qr': coordenada.codigoQr,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            } catch (e) {
              print(
                'Error guardando coordenada ${coordJson['id_coordenada_admin']}: $e',
              );
            }
          }

          print('Coordenadas Admin guardadas correctamente');
        }

        // 5. Guardar rondas asignadas y sus coordenadas
        if (jsonData['rondas_asignadas'] != null) {
          final List<dynamic> rondasAsignadas = jsonData['rondas_asignadas'];

          final hoy = DateTime.now();
          final manana = hoy.add(const Duration(days: 1));
          final fechaHoy = DateFormat('yyyy-MM-dd').format(hoy);
          final fechaManana = DateFormat('yyyy-MM-dd').format(manana);

          print('Filtrando rondas: $fechaHoy y $fechaManana');

          for (var rondaJson in rondasAsignadas) {
            try {
              print('Procesando ronda: ${rondaJson['id_ronda_asignada']}');
              print('Ronda JSON completo: $rondaJson');
              final ronda = RondaAsignada.fromJson(rondaJson);

              if (ronda.fechaDeEjecucion == fechaHoy ||
                  ronda.fechaDeEjecucion == fechaManana) {
                await txn.insert(
                  'Ronda_asignada',
                  ronda.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );

                if (rondaJson['coordenadas'] != null) {
                  final List<dynamic> coordenadas = rondaJson['coordenadas'];
                  for (var coordJson in coordenadas) {
                    final rondaCoordenada = RondaCoordenada(
                      idRondaAsignada: ronda.idRondaAsignada,
                      idCoordenadaAdmin:
                          coordJson['id_coordenada_admin'] as int,
                      orden: coordJson['orden'] as int,
                    );
                    await txn.insert(
                      'ronda_coordenadas',
                      rondaCoordenada.toMap(),
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );
                  }
                }

                print(
                  'Ronda ${ronda.idRondaAsignada} guardada - ${ronda.fechaDeEjecucion}',
                );
              } else {
                print(
                  'Ronda ${ronda.idRondaAsignada} ignorada - ${ronda.fechaDeEjecucion}',
                );
              }
            } catch (e) {
              print('Error al guardar ronda: $e');
            }
          }
        }
      });

      return true;
    } catch (e) {
      print('Error al importar datos: $e');
      return false;
    }
  }

  Future<bool> tienesDatosLocales() async {
    final db = await _dbHelper.database;

    // Verifica si hay al menos un usuario guardado
    final result = await db.query('usuarios', limit: 1);
    return result.isNotEmpty;
  }

  // Obtener los datos del usuario guardados localmente

  Future<Usuario?> obtenerUsuarioLocal(int idUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Usuario.fromMap(result.first);
  }

  // Borra datos obtenidos de la nube y los vuelve a descargar
  // Mantiene las rondas ejecutadas localmente y no las borra ni modifica

  Future<bool> actualizarDatosNube(Map<String, dynamic> jsonData) async {
    try {
      // Primero borra datos de la nube (no borra rondas_usuarios)
      await _dbHelper.borrarDatosNube();

      // Luego importa los nuevos datos
      return await importarDatosDesdeNube(jsonData);
    } catch (e) {
      print('Error al actualizar datos: $e');
      return false;
    }
  }
}
