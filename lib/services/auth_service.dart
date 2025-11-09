// Servicio de autenticación que maneja login y sincronización con la nube

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../database/repositories/sync_repository.dart';
import 'user_session.dart';
import 'dart:io';
import 'dart:convert';

class AuthService {
  final SyncRepository _syncRepo = SyncRepository();

  static const String _baseUrl = 'https://api-sistema-rondas.onrender.com/api';

  Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
    required UserSession userSession,
  }) async {
    try {
      // 1. Hacer petición al backend
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

      // 2. Verificar respuesta del servidor
      if (response.statusCode == 200) {
        final Map<String, dynamic> datosUsuario = jsonDecode(response.body);
        //borrar al final estas dos lineas
        final jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(datosUsuario);
        print('📦 JSON INICIO ===================');
        print(jsonString);
        print('📦 JSON FIN ======================');

        // 3. Validar que el JSON tenga la estructura correcta
        if (!_validarEstructuraJSON(datosUsuario)) {
          return {
            'success': false,
            'message': 'Respuesta del servidor inválida',
          };
        }

        // 4. Guardar datos en la base de datos local
        final guardadoExitoso = await _syncRepo.importarDatosDesdeNube(
          datosUsuario,
        );

        if (!guardadoExitoso) {
          return {
            'success': false,
            'message': 'Error al guardar datos localmente',
          };
        }

        // 5. Actualizar sesión del usuario
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
      print('Error en login: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Cierre de sesión
  /// Si borrarDatos es true, elimina toda la información local
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

  /// Valida que el JSON tenga la estructura esperada
  bool _validarEstructuraJSON(Map<String, dynamic> json) {
    return json.containsKey('usuario') &&
        json['usuario'].containsKey('id_usuario') &&
        json['usuario'].containsKey('nombre') &&
        json.containsKey('coordenadas_admin') &&
        json.containsKey('rondas_asignadas');
  }

  /// Verifica si hay datos guardados localmente
  Future<bool> hayDatosLocales() async {
    return await _syncRepo.tienesDatosLocales();
  }

  /// Sincronizar datos (actualizar desde la nube)
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
      print('Error al sincronizar: $e');
      return false;
    }
  }
}
