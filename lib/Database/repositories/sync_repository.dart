import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../modelos.dart';

class SyncRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> importarDatosDesdeNube(Map<String, dynamic> jsonData) async {
    final db = await _dbHelper.database;

    try {
      await _dbHelper.borrarDatosNube();
      await db.transaction((txn) async {
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

        if (jsonData['usuario'] != null) {
          final usuario = Usuario.fromJson(jsonData['usuario']);
          await txn.insert(
            'usuarios',
            usuario.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

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
              // Error guardando coordenada individual, continuar con las demás
              continue;
            }
          }
        }

        if (jsonData['rondas_asignadas'] != null) {
          final List<dynamic> rondasAsignadas = jsonData['rondas_asignadas'];

          final hoy = DateTime.now();
          final manana = hoy.add(const Duration(days: 1));
          final fechaHoy = DateFormat('yyyy-MM-dd').format(hoy);
          final fechaManana = DateFormat('yyyy-MM-dd').format(manana);

          for (var rondaJson in rondasAsignadas) {
            try {
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
              }
            } catch (e) {
              // Error guardando ronda individual, continuar con las demás
              continue;
            }
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> tienesDatosLocales() async {
    final db = await _dbHelper.database;

    final result = await db.query('usuarios', limit: 1);
    return result.isNotEmpty;
  }

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

  Future<bool> actualizarDatosNube(Map<String, dynamic> jsonData) async {
    try {
      await _dbHelper.borrarDatosNube();
      return await importarDatosDesdeNube(jsonData);
    } catch (e) {
      return false;
    }
  }
}
