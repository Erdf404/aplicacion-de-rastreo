// Repositorio para manejar las rondas que ejecuta el usuario
// y las coordenadas registradas durante la ronda

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../modelos.dart';

class RondasRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Crea un registro de ronda cuando el usuario inicia una ronda asignada
  // Retorna: El ID de la ronda creada (se usará para guardar coordenadas)

  Future<int> iniciarRonda({
    required int idUsuario,
    required int idRondaAsignada,
    required DateTime fechaHoraInicio,
  }) async {
    final db = await _dbHelper.database;

    // Crear objeto RondaUsuario
    final ronda = RondaUsuario(
      idUsuario: idUsuario,
      idRondaAsignada: idRondaAsignada,
      fecha: _formatearFecha(fechaHoraInicio), // "2025-10-14"
      horaInicio: _formatearFechaHora(fechaHoraInicio), // "2025-10-14T22:00:00"
      horaFinal: '', // Se llenará cuando termine la ronda
    );

    // Insertar y retornar el ID generado
    return await db.insert('rondas_usuarios', ronda.toMap());
  }

  // Actualiza la hora final cuando el usuario completa una ronda

  Future<bool> finalizarRonda({
    required int idRondaUsuario,
    required DateTime fechaHoraFinal,
  }) async {
    final db = await _dbHelper.database;

    try {
      final rowsAffected = await db.update(
        'rondas_usuarios',
        {'hora_final': _formatearFechaHora(fechaHoraFinal)},
        where: 'id_ronda_usuario = ?',
        whereArgs: [idRondaUsuario],
      );

      return rowsAffected > 0;
    } catch (e) {
      print('Error al finalizar ronda: $e');
      return false;
    }
  }

  // Guarda la ubicación del usuario en un momento específico durante la ronda
  // Parámetros:
  //   - idRondaUsuario: ID de la ronda activa
  //   - latitud/longitud: Posición GPS actual
  //   - codigoQrEscaneado: Código QR escaneado (opcional)
  //   - esValido: true si el QR es válido, false si no

  Future<int> registrarCoordenada({
    required int idRondaUsuario,
    required double latitud,
    required double longitud,
    String? codigoQrEscaneado,
    bool esValido = false,
  }) async {
    final db = await _dbHelper.database;

    final coordenada = CoordenadaUsuario(
      idRondaUsuario: idRondaUsuario,
      horaActual: _formatearFechaHora(DateTime.now()),
      latitudActual: latitud,
      longitudActual: longitud,
      codigoQr: codigoQrEscaneado,
      verificador: esValido,
    );

    return await db.insert('coordenadas_usuarios', coordenada.toMap());
  }

  // Verifica si un código QR escaneado existe en la base de datos
  // Retorna: El id_coordenada_admin si es válido, null si no existe

  Future<int?> verificarCodigoQr(String codigoQr) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'Qr',
      columns: ['id_coordenada_admin'],
      where: 'codigo_qr = ?',
      whereArgs: [codigoQr],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['id_coordenada_admin'] as int;
  }

  // Verifica si el QR escaneado pertenece a la ronda asignada actual
  // Retorna: true si el QR es parte de esta ronda, false si no

  Future<bool> verificarQrEnRondaAsignada({
    required int idRondaAsignada,
    required int idCoordenadaAdmin,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'ronda_coordenadas',
      where: 'id_ronda_asignada = ? AND id_coordenada_admin = ?',
      whereArgs: [idRondaAsignada, idCoordenadaAdmin],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Obtiene todas las rondas ejecutadas por un usuario
  // usado para mostrar el historial de rondas

  Future<List<RondaUsuario>> obtenerRondasUsuario(int idUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'rondas_usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, hora_inicio DESC', // Más recientes primero
    );

    return result.map((map) => RondaUsuario.fromMap(map)).toList();
  }

  // Obtiene todas las coordenadas registradas en una ronda específica
  // Útil para ver el tracking completo de una ronda

  Future<List<CoordenadaUsuario>> obtenerCoordenadasRonda(
    int idRondaUsuario,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'coordenadas_usuarios',
      where: 'id_ronda_usuario = ?',
      whereArgs: [idRondaUsuario],
      orderBy: 'hora_actual ASC', // Orden cronológico
    );

    return result.map((map) => CoordenadaUsuario.fromMap(map)).toList();
  }

  // Obtiene información completa de una ronda con su tipo
  // Retorna un Map con toda la información combinada

  Future<Map<String, dynamic>?> obtenerDetalleRonda(int idRondaUsuario) async {
    final db = await _dbHelper.database;

    // Query con JOIN para obtener información completa
    final result = await db.rawQuery(
      '''
      SELECT 
        ru.*,
        ra.fecha_de_ejecucion,
        ra.hora_de_ejecucion,
        tr.nombre_tipo_ronda,
        u.nombre as nombre_usuario
      FROM rondas_usuarios ru
      INNER JOIN Ronda_asignada ra ON ru.id_ronda_asignada = ra.id_ronda_asignada
      INNER JOIN Tipo_ronda tr ON ra.id_tipo = tr.id_tipo
      INNER JOIN usuarios u ON ru.id_usuario = u.id_usuario
      WHERE ru.id_ronda_usuario = ?
    ''',
      [idRondaUsuario],
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  // Cuenta cuántos checkpoints fueron verificados exitosamente en una ronda

  Future<int> contarCheckpointsVerificados(int idRondaUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM coordenadas_usuarios
      WHERE id_ronda_usuario = ? AND verificador = 1
    ''',
      [idRondaUsuario],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtiene las coordenadas que aún faltan por verificar en una ronda
  // Compara las coordenadas de la ronda asignada vs las ya verificadas

  Future<List<Map<String, dynamic>>> obtenerCheckpointsPendientes({
    required int idRondaAsignada,
    required int idRondaUsuario,
  }) async {
    final db = await _dbHelper.database;

    // Query: coordenadas asignadas que NO han sido verificadas
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
        AND ca.id_coordenada_admin NOT IN (
          SELECT DISTINCT cu.codigo_qr
          FROM coordenadas_usuarios cu
          INNER JOIN Qr q2 ON cu.codigo_qr = q2.codigo_qr
          WHERE cu.id_ronda_usuario = ? AND cu.verificador = 1
        )
      ORDER BY rc.orden ASC
    ''',
      [idRondaAsignada, idRondaUsuario],
    );

    return result;
  }

  // MÉTODOS AUXILIARES PRIVADOS
  // ============================================================================

  // Formatea DateTime a "2025-10-14"
  String _formatearFecha(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  // Formatea DateTime a formato ISO8601: "2025-10-14T22:30:00"
  String _formatearFechaHora(DateTime fecha) {
    return '${_formatearFecha(fecha)}T${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')}';
  }
}
