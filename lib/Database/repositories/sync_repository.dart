// Repositorio encargado de sincronizar datos entre la nube y la base de datos local

import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../modelos.dart';

class SyncRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // IMPORTAR TODOS LOS DATOS DESDE JSON
  // ============================================================================
  // Este método recibe el JSON completo desde la nube y lo guarda en la BD local
  // Parámetro: jsonData - El JSON parseado con toda la información del usuario
  // Retorna: true si todo se guardó correctamente, false si hubo error

  Future<bool> importarDatosDesdeNube(Map<String, dynamic> jsonData) async {
    final db = await _dbHelper.database;

    try {
      // Usar transacción para garantizar que todo se guarde o nada
      // Si algo falla, se hace rollback automáticamente
      await db.transaction((txn) async {
        // 1. Guardar tipo de usuario
        if (jsonData['usuario']?['tipo_usuario'] != null) {
          final tipoUsuario = TipoUsuario.fromJson(
            jsonData['usuario']['tipo_usuario'],
          );
          await txn.insert(
            'tipos_de_usuarios',
            tipoUsuario.toMap(),
            conflictAlgorithm:
                ConflictAlgorithm.replace, // Reemplaza si ya existe
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

        // 4. Guardar coordenadas admin y sus QR
        if (jsonData['coordenadas_admin'] != null) {
          final List<dynamic> coordenadas = jsonData['coordenadas_admin'];
          for (var coordJson in coordenadas) {
            // Guardar coordenada
            final coordenada = CoordenadaAdmin.fromJson(coordJson);
            await txn.insert(
              'Coordenadas_admin',
              coordenada.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Guardar QR asociado (si existe)
            if (coordJson['qr'] != null) {
              final qr = Qr(
                idCoordenadaAdmin: coordenada.idCoordenadaAdmin,
                codigoQr: coordJson['qr']['codigo_qr'] as String,
              );
              await txn.insert(
                'Qr',
                qr.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
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
            // Guardar ronda asignada
            final ronda = RondaAsignada.fromJson(rondaJson);

            if (ronda.fechaDeEjecucion == fechaHoy ||
                ronda.fechaDeEjecucion == fechaManana) {
              await txn.insert(
                'Ronda_asignada',
                ronda.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              // Guardar coordenadas de esta ronda (tabla intermedia)
              if (rondaJson['coordenadas'] != null) {
                final List<dynamic> coordenadas = rondaJson['coordenadas'];
                for (var coordJson in coordenadas) {
                  final rondaCoordenada = RondaCoordenada(
                    idRondaAsignada: ronda.idRondaAsignada,
                    idCoordenadaAdmin: coordJson['id_coordenada_admin'] as int,
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
          }
        }
      });

      return true;
    } catch (e) {
      // Si algo falló, imprime el error y retorna false
      print('Error al importar datos: $e');
      return false;
    }
  }

  // VERIFICAR SI EXISTEN DATOS LOCALES
  // Útil para saber si el usuario ya descargó datos anteriormente

  Future<bool> tienesDatosLocales() async {
    final db = await _dbHelper.database;

    // Verifica si hay al menos un usuario guardado
    final result = await db.query('usuarios', limit: 1);
    return result.isNotEmpty;
  }

  // ============================================================================
  // Obtiene los datos del usuario guardados localmente

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
