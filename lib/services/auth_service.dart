import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../database/repositories/sync_repository.dart';
import 'user_session.dart';

class AuthService {
  final SyncRepository _syncRepo = SyncRepository();

  static const String _baseUrl = 'https://api-sistema-rondas.onrender.com/api';

  Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
    required UserSession userSession,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
          )
          .timeout(
            const Duration(seconds: 1000),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> datosUsuario = jsonDecode(response.body);

        if (!_validarEstructuraJSON(datosUsuario)) {
          return {
            'success': false,
            'message': 'Respuesta del servidor inválida',
          };
        }

        final guardadoExitoso = await _syncRepo.importarDatosDesdeNube(
          datosUsuario,
        );

        if (!guardadoExitoso) {
          return {
            'success': false,
            'message': 'Error al guardar datos localmente',
          };
        }

        final usuario = datosUsuario['usuario'];
        userSession.iniciarSesion(
          idUsuario: usuario['id_usuario'],
          nombre: usuario['nombre'],
          correo: usuario['correo'],
          idTipo: usuario['id_tipo'],
          nombreTipoUsuario: usuario['tipo_usuario']?['nombre_tipo_usuario'],
        );

        return {'success': true, 'message': 'Login exitoso', 'user': usuario};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Correo o contraseña incorrectos'};
      } else {
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  Future<void> logout({
    required UserSession userSession,
    bool borrarDatos = false,
  }) async {
    if (borrarDatos) {
      final dbHelper = DatabaseHelper();
      await dbHelper.borrarTodosDatos();
    }

    userSession.cerrarSesion();
  }

  bool _validarEstructuraJSON(Map<String, dynamic> json) {
    return json.containsKey('usuario') &&
        json['usuario'].containsKey('id_usuario') &&
        json['usuario'].containsKey('nombre') &&
        json.containsKey('coordenadas_admin') &&
        json.containsKey('rondas_asignadas');
  }

  Future<bool> hayDatosLocales() async {
    return await _syncRepo.tienesDatosLocales();
  }

  Future<bool> sincronizarDatos({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      );

      if (response.statusCode == 200) {
        final datosUsuario = jsonDecode(response.body);
        return await _syncRepo.actualizarDatosNube(datosUsuario);
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
