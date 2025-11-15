import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../modelos.dart';

class RondasRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> iniciarRonda({
    required int idUsuario,
    required int idRondaAsignada,
    required DateTime fechaHoraInicio,
  }) async {
    final db = await _dbHelper.database;

    final ronda = RondaUsuario(
      idUsuario: idUsuario,
      idRondaAsignada: idRondaAsignada,
      fecha: _formatearFecha(fechaHoraInicio),
      horaInicio: _formatearFechaHora(fechaHoraInicio),
      horaFinal: '',
    );

    return await db.insert('rondas_usuarios', ronda.toMap());
  }

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
      return false;
    }
  }

  Future<int> registrarCoordenada({
    required int idRondaUsuario,
    double? latitud,
    double? longitud,
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

  Future<int?> verificarCodigoQr(String codigoQr) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'Coordenadas_admin',
      columns: ['id_coordenada_admin'],
      where: 'codigo_qr = ?',
      whereArgs: [codigoQr],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['id_coordenada_admin'] as int;
  }

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

  Future<List<RondaUsuario>> obtenerRondasUsuario(int idUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'rondas_usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, hora_inicio DESC',
    );

    return result.map((map) => RondaUsuario.fromMap(map)).toList();
  }

  Future<List<CoordenadaUsuario>> obtenerCoordenadasRonda(
    int idRondaUsuario,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'coordenadas_usuarios',
      where: 'id_ronda_usuario = ?',
      whereArgs: [idRondaUsuario],
      orderBy: 'hora_actual ASC',
    );

    return result.map((map) => CoordenadaUsuario.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>?> obtenerDetalleRonda(int idRondaUsuario) async {
    final db = await _dbHelper.database;

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

  Future<List<Map<String, dynamic>>> obtenerCheckpointsPendientes({
    required int idRondaAsignada,
    required int idRondaUsuario,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        ca.id_coordenada_admin,
        ca.nombre_coordenada,
        ca.latitud,
        ca.longitud,
        rc.orden,
        ca.codigo_qr
      FROM ronda_coordenadas rc
      INNER JOIN Coordenadas_admin ca 
        ON rc.id_coordenada_admin = ca.id_coordenada_admin
      WHERE rc.id_ronda_asignada = ?
        AND ca.id_coordenada_admin NOT IN (
          SELECT DISTINCT cu.id_ronda_usuario
          FROM coordenadas_usuarios cu
          WHERE cu.id_ronda_usuario = ? AND cu.verificador = 1
        )
      ORDER BY rc.orden ASC
    ''',
      [idRondaAsignada, idRondaUsuario],
    );

    return result;
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  String _formatearFechaHora(DateTime fecha) {
    return '${_formatearFecha(fecha)}T${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')}';
  }

  Future<bool> marcarRondaSincronizada(int idRondaUsuario) async {
    final db = await _dbHelper.database;

    try {
      final rowsAffected = await db.update(
        'rondas_usuarios',
        {'sincronizada': 1},
        where: 'id_ronda_usuario = ?',
        whereArgs: [idRondaUsuario],
      );
      return rowsAffected > 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<RondaUsuario>> obtenerRondasNoSincronizadas(int idUsuario) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'rondas_usuarios',
      where: 'id_usuario = ? AND sincronizada = 0',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, hora_inicio DESC',
    );

    return result.map((map) => RondaUsuario.fromMap(map)).toList();
  }

  Future<bool> eliminarRonda(int idRondaUsuario) async {
    final db = await _dbHelper.database;

    try {
      await db.delete(
        'coordenadas_usuarios',
        where: 'id_ronda_usuario = ?',
        whereArgs: [idRondaUsuario],
      );

      final rowsAffected = await db.delete(
        'rondas_usuarios',
        where: 'id_ronda_usuario = ?',
        whereArgs: [idRondaUsuario],
      );

      return rowsAffected > 0;
    } catch (e) {
      return false;
    }
  }
}
