import 'dart:convert';
import 'package:http/http.dart' as http;
import '/database/repositories/rondas_repository.dart';
import '/database/repositories/consultas_repository.dart';

class SyncService {
  final RondasRepository _rondasRepo = RondasRepository();
  final ConsultasRepository _consultasRepo = ConsultasRepository();

  static const String _baseUrl = 'https://tu-backend.com/api';

  /// Sube todas las rondas ejecutadas localmente que no se han sincronizado
  /// Retorna: cantidad de rondas sincronizadas exitosamente
  Future<Map<String, dynamic>> sincronizarRondasPendientes(
    int idUsuario,
  ) async {
    try {
      // 1. Obtener todas las rondas del usuario
      final rondas = await _rondasRepo.obtenerRondasUsuario(idUsuario);

      if (rondas.isEmpty) {
        return {
          'success': true,
          'sincronizadas': 0,
          'message': 'No hay rondas para sincronizar',
        };
      }

      int sincronizadas = 0;
      List<String> errores = [];

      // 2. Por cada ronda, obtener su detalle y subirla
      for (var ronda in rondas) {
        if (ronda.idRondaUsuario == null) continue;

        try {
          // Obtener detalle completo (con coordenadas)
          final detalle = await _consultasRepo.obtenerDetalleRondaEjecutada(
            ronda.idRondaUsuario!,
          );

          if (detalle == null) continue;

          // Subir al servidor
          final exito = await _subirRondaAlServidor(detalle);

          if (exito) {
            sincronizadas++;
            // TODO: Marcar como sincronizada en BD local o algun mensaje de confirmación
          } else {
            errores.add('Ronda ${ronda.idRondaUsuario}');
          }
        } catch (e) {
          errores.add('Error en ronda ${ronda.idRondaUsuario}: $e');
        }
      }

      return {
        'success': errores.isEmpty,
        'sincronizadas': sincronizadas,
        'total': rondas.length,
        'errores': errores,
        'message': errores.isEmpty
            ? 'Se sincronizaron $sincronizadas ronda(s)'
            : 'Se sincronizaron $sincronizadas de ${rondas.length}',
      };
    } catch (e) {
      return {
        'success': false,
        'sincronizadas': 0,
        'message': 'Error al sincronizar: $e',
      };
    }
  }

  Future<bool> _subirRondaAlServidor(Map<String, dynamic> ronda) async {
    try {
      // Preparar datos para enviar
      final payload = {
        'id_ronda_usuario': ronda['id_ronda_usuario'],
        'id_usuario': ronda['id_usuario'],
        'id_ronda_asignada': ronda['id_ronda_asignada'],
        'fecha': ronda['fecha'],
        'hora_inicio': ronda['hora_inicio'],
        'hora_final': ronda['hora_final'],
        'coordenadas': ronda['coordenadas'], // Lista de coordenadas
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/rondas/subir'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al subir ronda: $e');
      return false;
    }
  }

  // verificar si hay conexión

  Future<bool> tieneConexion() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ping'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Intenta sincronizar automáticamente cuando hay conexión
  Future<void> intentarSincronizacionAutomatica(int idUsuario) async {
    if (await tieneConexion()) {
      await sincronizarRondasPendientes(idUsuario);
    }
  }
}
