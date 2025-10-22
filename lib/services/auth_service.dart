// Servicio de autenticación que maneja login y sincronización con la nube

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../database/repositories/sync_repository.dart';
import 'user_session.dart';

class AuthService {
  final SyncRepository _syncRepo = SyncRepository();

  // CONFIGURACIÓN DEL BACKEND
  // IMPORTANTE: Cambia esta URL cuando se tenga el backend real
  static const String _baseUrl = 'https://tu-backend.com/api';

  // ============================================================================
  // LOGIN

  /// Autentica al usuario y descarga sus datos
  /// Retorna un mapa con el resultado:
  /// - success: bool
  /// - message: String
  /// - user: Map? (datos del usuario si el login fue exitoso)
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
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );

      // 2. Verificar respuesta del servidor
      if (response.statusCode == 200) {
        final Map<String, dynamic> datosUsuario = jsonDecode(response.body);

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

  // Modo offline, borrar cuando se termine

  Future<Map<String, dynamic>> loginOffline({
    required String correo,
    required String contrasena,
    required UserSession userSession,
  }) async {
    // Simularmred
    await Future.delayed(const Duration(seconds: 1));

    // Validación básica
    if (correo.isEmpty || contrasena.isEmpty) {
      return {'success': false, 'message': 'Complete todos los campos'};
    }

    // Datos simulados (JSON de ejemplo)
    final Map<String, dynamic> datosSimulados = {
      "usuario": {
        "id_usuario": 1,
        "id_tipo": 2,
        "nombre": "Juan Pérez",
        "contrasena": "hash_password",
        "correo": correo,
        "tipo_usuario": {"tipo_id": 2, "nombre_tipo_usuario": "Guardia"},
      },
      "tipos_ronda": [
        {"id_tipo": 1, "nombre_tipo_ronda": "Ronda exterior"},
        {"id_tipo": 2, "nombre_tipo_ronda": "Ronda interior"},
      ],
      "coordenadas_admin": [
        {
          "id_coordenada_admin": 1,
          "latitud": 20.6736,
          "longitud": -103.3444,
          "nombre_coordenada": "Entrada Principal",
          "qr": {"codigo_qr": "QR_ENTRADA_001"},
        },
        {
          "id_coordenada_admin": 2,
          "latitud": 20.6740,
          "longitud": -103.3450,
          "nombre_coordenada": "Almacén 1",
          "qr": {"codigo_qr": "QR_ALMACEN_001"},
        },
        {
          "id_coordenada_admin": 3,
          "latitud": 20.6745,
          "longitud": -103.3455,
          "nombre_coordenada": "Oficinas",
          "qr": {"codigo_qr": "QR_OFICINA_001"},
        },
      ],
      "rondas_asignadas": [
        {
          "id_ronda_asignada": 1,
          "id_tipo": 1,
          "id_usuario": 1,
          "fecha_de_ejecucion": "2025-10-22",
          "hora_de_ejecucion": "2025-10-15T22:00:00",
          "distancia_permitida": 10,
          "coordenadas": [
            {"id_coordenada_admin": 1, "orden": 1},
            {"id_coordenada_admin": 2, "orden": 2},
            {"id_coordenada_admin": 3, "orden": 3},
          ],
        },
        {
          "id_ronda_asignada": 2,
          "id_tipo": 2,
          "id_usuario": 1,
          "fecha_de_ejecucion": "2025-10-23",
          "hora_de_ejecucion": "2025-10-16T08:00:00",
          "distancia_permitida": 20,
          "coordenadas": [
            {"id_coordenada_admin": 1, "orden": 1},
            {"id_coordenada_admin": 3, "orden": 2},
          ],
        },
        {
          "id_ronda_asignada": 3,
          "id_tipo": 1,
          "id_usuario": 1,
          "fecha_de_ejecucion": "2025-10-23",
          "hora_de_ejecucion": "2025-10-16T20:00:00",
          "distancia_permitida": 15,
          "coordenadas": [
            {"id_coordenada_admin": 2, "orden": 1},
            {"id_coordenada_admin": 3, "orden": 2},
          ],
        },
      ],
    };

    // Guardar en BD local
    final guardadoExitoso = await _syncRepo.importarDatosDesdeNube(
      datosSimulados,
    );

    if (!guardadoExitoso) {
      return {'success': false, 'message': 'Error al guardar datos localmente'};
    }

    // Actualizar sesión
    userSession.iniciarSesion(
      idUsuario: 1,
      nombre: "Juan Pérez",
      correo: correo,
      idTipo: 2,
      nombreTipoUsuario: "Guardia",
    );

    return {
      'success': true,
      'message': 'Login offline exitoso',
      'user': datosSimulados['usuario'],
    };
  }

  // ============================================================================
  // LOGOUT

  /// Cierra la sesión del usuario
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
