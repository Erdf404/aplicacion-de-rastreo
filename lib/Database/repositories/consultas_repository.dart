// consultas_repository.dart
// Repositorio para consultas complejas con JOINs
// Usado principalmente para mostrar información en la UI

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class ConsultasRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Obtiene todas las rondas asignadas a un usuario
  // Incluye: tipo de ronda, fecha, hora, cantidad de checkpoints

  Future<List<Map<String, dynamic>>> obtenerRondasAsignadas(
    int idUsuario,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        ra.id_ronda_asignada,
        ra.fecha_de_ejecucion,
        ra.hora_de_ejecucion,
        tr.nombre_tipo_ronda,
        tr.id_tipo,
        COUNT(rc.id_coordenada_admin) as total_checkpoints
      FROM Ronda_asignada ra
      INNER JOIN Tipo_ronda tr ON ra.id_tipo = tr.id_tipo
      LEFT JOIN ronda_coordenadas rc 
        ON ra.id_ronda_asignada = rc.id_ronda_asignada
      WHERE ra.id_usuario = ?
      GROUP BY ra.id_ronda_asignada
      ORDER BY ra.fecha_de_ejecucion DESC, ra.hora_de_ejecucion DESC
    ''',
      [idUsuario],
    );

    return result;
  }

  // Obtiene todos los checkpoints (coordenadas) de una ronda asignada

  Future<List<Map<String, dynamic>>> obtenerCheckpointsRondaAsignada(
    int idRondaAsignada,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        ca.id_coordenada_admin,
        ca.nombre_coordenada,
        ca.latitud,
        ca.longitud,
        rc.orden,
        q.codigo_qr
      FROM ronda_coordenadas rc
      INNER JOIN Coordenadas_admin ca 
        ON rc.id_coordenada_admin = ca.id_coordenada_admin
      LEFT JOIN Qr q ON ca.id_coordenada_admin = q.id_coordenada_admin
      WHERE rc.id_ronda_asignada = ?
      ORDER BY rc.orden ASC
    ''',
      [idRondaAsignada],
    );

    return result;
  }

  // Obtiene todas las rondas que ha ejecutado un usuario con información resumida
  // Incluye: tipo, fecha, duración, checkpoints verificados

  Future<List<Map<String, dynamic>>> obtenerHistorialRondas(
    int idUsuario,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        ru.id_ronda_usuario,
        ru.fecha,
        ru.hora_inicio,
        ru.hora_final,
        tr.nombre_tipo_ronda,
        ra.fecha_de_ejecucion as fecha_asignada,
        COUNT(CASE WHEN cu.verificador = 1 THEN 1 END) as checkpoints_verificados,
        COUNT(cu.id) as total_registros
      FROM rondas_usuarios ru
      INNER JOIN Ronda_asignada ra 
        ON ru.id_ronda_asignada = ra.id_ronda_asignada
      INNER JOIN Tipo_ronda tr ON ra.id_tipo = tr.id_tipo
      LEFT JOIN coordenadas_usuarios cu 
        ON ru.id_ronda_usuario = cu.id_ronda_usuario
      WHERE ru.id_usuario = ?
      GROUP BY ru.id_ronda_usuario
      ORDER BY ru.fecha DESC, ru.hora_inicio DESC
    ''',
      [idUsuario],
    );

    return result;
  }

  // Información completa de una ronda específica ejecutada
  // Incluye todas las coordenadas registradas con timestamps

  Future<Map<String, dynamic>?> obtenerDetalleRondaEjecutada(
    int idRondaUsuario,
  ) async {
    final db = await _dbHelper.database;

    // Primero obtener información general de la ronda
    final rondaInfo = await db.rawQuery(
      '''
      SELECT 
        ru.*,
        tr.nombre_tipo_ronda,
        u.nombre as nombre_usuario,
        ra.fecha_de_ejecucion as fecha_asignada,
        ra.hora_de_ejecucion as hora_asignada
      FROM rondas_usuarios ru
      INNER JOIN Ronda_asignada ra 
        ON ru.id_ronda_asignada = ra.id_ronda_asignada
      INNER JOIN Tipo_ronda tr ON ra.id_tipo = tr.id_tipo
      INNER JOIN usuarios u ON ru.id_usuario = u.id_usuario
      WHERE ru.id_ronda_usuario = ?
    ''',
      [idRondaUsuario],
    );

    if (rondaInfo.isEmpty) return null;

    // Obtener coordenadas registradas
    final coordenadas = await db.rawQuery(
      '''
      SELECT 
        cu.*,
        ca.nombre_coordenada,
        ca.latitud as latitud_esperada,
        ca.longitud as longitud_esperada
      FROM coordenadas_usuarios cu
      LEFT JOIN Qr q ON cu.codigo_qr = q.codigo_qr
      LEFT JOIN Coordenadas_admin ca 
        ON q.id_coordenada_admin = ca.id_coordenada_admin
      WHERE cu.id_ronda_usuario = ?
      ORDER BY cu.hora_actual ASC
    ''',
      [idRondaUsuario],
    );

    // Combinar toda la información
    return {...rondaInfo.first, 'coordenadas': coordenadas};
  }

  // Busca rondas ejecutadas en un rango de fechas

  Future<List<Map<String, dynamic>>> buscarRondasPorFecha({
    required int idUsuario,
    required String fechaInicio, // Formato: "2025-10-01"
    required String fechaFin, // Formato: "2025-10-31"
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        ru.id_ronda_usuario,
        ru.fecha,
        ru.hora_inicio,
        ru.hora_final,
        tr.nombre_tipo_ronda,
        COUNT(CASE WHEN cu.verificador = 1 THEN 1 END) as checkpoints_verificados
      FROM rondas_usuarios ru
      INNER JOIN Ronda_asignada ra 
        ON ru.id_ronda_asignada = ra.id_ronda_asignada
      INNER JOIN Tipo_ronda tr ON ra.id_tipo = tr.id_tipo
      LEFT JOIN coordenadas_usuarios cu 
        ON ru.id_ronda_usuario = cu.id_ronda_usuario
      WHERE ru.id_usuario = ? 
        AND ru.fecha BETWEEN ? AND ?
      GROUP BY ru.id_ronda_usuario
      ORDER BY ru.fecha DESC, ru.hora_inicio DESC
    ''',
      [idUsuario, fechaInicio, fechaFin],
    );

    return result;
  }

  // Retorna estadísticas generales del usuario

  Future<Map<String, dynamic>> obtenerEstadisticasUsuario(int idUsuario) async {
    final db = await _dbHelper.database;

    // Total de rondas ejecutadas
    final totalRondas = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM rondas_usuarios
      WHERE id_usuario = ?
    ''',
      [idUsuario],
    );

    // Total de checkpoints verificados
    final totalCheckpoints = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM coordenadas_usuarios cu
      INNER JOIN rondas_usuarios ru ON cu.id_ronda_usuario = ru.id_ronda_usuario
      WHERE ru.id_usuario = ? AND cu.verificador = 1
    ''',
      [idUsuario],
    );

    // Rondas asignadas pendientes
    final rondasPendientes = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM Ronda_asignada ra
      LEFT JOIN rondas_usuarios ru 
        ON ra.id_ronda_asignada = ru.id_ronda_asignada
      WHERE ra.id_usuario = ? AND ru.id_ronda_usuario IS NULL
    ''',
      [idUsuario],
    );

    // Última ronda ejecutada
    final ultimaRonda = await db.rawQuery(
      '''
      SELECT fecha, hora_inicio
      FROM rondas_usuarios
      WHERE id_usuario = ?
      ORDER BY fecha DESC, hora_inicio DESC
      LIMIT 1
    ''',
      [idUsuario],
    );

    return {
      'total_rondas': Sqflite.firstIntValue(totalRondas) ?? 0,
      'total_checkpoints': Sqflite.firstIntValue(totalCheckpoints) ?? 0,
      'rondas_pendientes': Sqflite.firstIntValue(rondasPendientes) ?? 0,
      'ultima_ronda': ultimaRonda.isNotEmpty ? ultimaRonda.first : null,
    };
  }

  // Verifica si una ronda asignada ya fue completada

  Future<bool> rondaYaEjecutada(int idRondaAsignada) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'rondas_usuarios',
      where: 'id_ronda_asignada = ?',
      whereArgs: [idRondaAsignada],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Encuentra checkpoints cercanos a una ubicación GPS

  Future<List<Map<String, dynamic>>> obtenerCoordenadasCercanas({
    required double latitud,
    required double longitud,
    double radio = 0.001, // Aproximadamente 100 metros
  }) async {
    final db = await _dbHelper.database;

    // Búsqueda simple por rango (no es perfecta pero funciona)
    final result = await db.rawQuery(
      '''
      SELECT 
        ca.*,
        q.codigo_qr,
        ABS(ca.latitud - ?) + ABS(ca.longitud - ?) as distancia_aprox
      FROM Coordenadas_admin ca
      LEFT JOIN Qr q ON ca.id_coordenada_admin = q.id_coordenada_admin
      WHERE ca.latitud BETWEEN ? AND ?
        AND ca.longitud BETWEEN ? AND ?
      ORDER BY distancia_aprox ASC
      LIMIT 10
    ''',
      [
        latitud,
        longitud,
        latitud - radio,
        latitud + radio,
        longitud - radio,
        longitud + radio,
      ],
    );

    return result;
  }

  // Obtiene datos completos del usuario con su tipo

  Future<Map<String, dynamic>?> obtenerInfoUsuario(int idUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        u.*,
        tu.nombre_tipo_usuario
      FROM usuarios u
      INNER JOIN tipos_de_usuarios tu ON u.id_tipo = tu.tipo_id
      WHERE u.id_usuario = ?
    ''',
      [idUsuario],
    );

    if (result.isEmpty) return null;
    return result.first;
  }
}
