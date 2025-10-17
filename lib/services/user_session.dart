// Servicio para manejar la sesión del usuario actual
// Usa ChangeNotifier para notificar cambios a los widgets

import 'package:flutter/foundation.dart';

class UserSession extends ChangeNotifier {
  // Datos del usuario actual
  int? _idUsuario;
  String? _nombre;
  String? _correo;
  int? _idTipo;
  String? _nombreTipoUsuario;

  // Datos de la ronda activa (si hay una en curso)
  int? _idRondaUsuarioActiva;
  int? _idRondaAsignadaActiva;
  String? _tipoRondaActiva; // 'interior' o 'exterior'
  bool _rondaEnCurso = false;

  // ============================================================================
  // GETTERS

  int? get idUsuario => _idUsuario;
  String? get nombre => _nombre;
  String? get correo => _correo;
  int? get idTipo => _idTipo;
  String? get nombreTipoUsuario => _nombreTipoUsuario;

  int? get idRondaUsuarioActiva => _idRondaUsuarioActiva;
  int? get idRondaAsignadaActiva => _idRondaAsignadaActiva;
  String? get tipoRondaActiva => _tipoRondaActiva;
  bool get rondaEnCurso => _rondaEnCurso;

  bool get isLoggedIn => _idUsuario != null;

  // ============================================================================
  // MÉTODOS DE SESIÓN

  // Iniciar sesión con datos del usuario
  void iniciarSesion({
    required int idUsuario,
    required String nombre,
    String? correo,
    int? idTipo,
    String? nombreTipoUsuario,
  }) {
    _idUsuario = idUsuario;
    _nombre = nombre;
    _correo = correo;
    _idTipo = idTipo;
    _nombreTipoUsuario = nombreTipoUsuario;
    notifyListeners();
  }

  // Cerrar sesión
  void cerrarSesion() {
    _idUsuario = null;
    _nombre = null;
    _correo = null;
    _idTipo = null;
    _nombreTipoUsuario = null;
    _limpiarRondaActiva();
    notifyListeners();
  }

  // ============================================================================
  // MÉTODOS DE RONDA ACTIVA

  // Iniciar una ronda
  void iniciarRonda({
    required int idRondaUsuario,
    required int idRondaAsignada,
    required String tipoRonda, // 'interior' o 'exterior'
  }) {
    _idRondaUsuarioActiva = idRondaUsuario;
    _idRondaAsignadaActiva = idRondaAsignada;
    _tipoRondaActiva = tipoRonda;
    _rondaEnCurso = true;
    notifyListeners();
  }

  // Finalizar la ronda activa
  void finalizarRonda() {
    _limpiarRondaActiva();
    notifyListeners();
  }

  // Limpiar datos de ronda activa
  void _limpiarRondaActiva() {
    _idRondaUsuarioActiva = null;
    _idRondaAsignadaActiva = null;
    _tipoRondaActiva = null;
    _rondaEnCurso = false;
  }

  // ============================================================================

  // Obtener nombre corto (primera palabra)
  String get nombreCorto {
    if (_nombre == null) return 'Usuario';
    return _nombre!.split(' ').first;
  }

  // Verificar si es administrador (ejemplo)
  bool get esAdmin => _idTipo == 1;

  // Debug
  @override
  String toString() {
    return 'UserSession(id: $_idUsuario, nombre: $_nombre, rondaEnCurso: $_rondaEnCurso)';
  }
}
