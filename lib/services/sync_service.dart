import 'dart:convert';
import 'package:http/http.dart' as http;
import '/database/repositories/rondas_repository.dart';
import '/database/repositories/consultas_repository.dart';

class SyncService {
  final RondasRepository _rondasRepo = RondasRepository();
  final ConsultasRepository _consultasRepo = ConsultasRepository();

  static const String _baseUrl = 'https://api-sistema-rondas.onrender.com/api';

  Future<Map<String, dynamic>> sincronizarRondasPendientes(
    int idUsuario,
  ) async {
    try {
      final rondas = await _rondasRepo.obtenerRondasNoSincronizadas(idUsuario);

      if (rondas.isEmpty) {
        return {
          'success': true,
          'sincronizadas': 0,
          'message': 'No hay rondas pendientes para sincronizar',
        };
      }

      int sincronizadas = 0;
      List<String> errores = [];

      for (var ronda in rondas) {
        if (ronda.idRondaUsuario == null) continue;

        try {
          final detalle = await _consultasRepo.obtenerDetalleRondaEjecutada(
            ronda.idRondaUsuario!,
          );

          if (detalle == null) continue;

          final exito = await _subirRondaAlServidor(detalle);

          if (exito) {
            await _rondasRepo.marcarRondaSincronizada(ronda.idRondaUsuario!);
            sincronizadas++;
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
      final payload = {
        'id_ronda_usuario': ronda['id_ronda_usuario'],
        'id_usuario': ronda['id_usuario'],
        'id_ronda_asignada': ronda['id_ronda_asignada'],
        'fecha': ronda['fecha'],
        'hora_inicio': ronda['hora_inicio'],
        'hora_final': ronda['hora_final'],
        'coordenadas': ronda['coordenadas'],
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
      return false;
    }
  }

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

  Future<void> intentarSincronizacionAutomatica(int idUsuario) async {
    if (await tieneConexion()) {
      await sincronizarRondasPendientes(idUsuario);
    }
  }
}
