import 'package:flutter/foundation.dart';

class UserSession extends ChangeNotifier {
  int? _idUsuario;
  String? _nombre;
  String? _correo;
  int? _idTipo;
  String? _nombreTipoUsuario;

  int? _idRondaUsuarioActiva;
  int? _idRondaAsignadaActiva;
  String? _tipoRondaActiva;
  bool _rondaEnCurso = false;

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

  void cerrarSesion() {
    _idUsuario = null;
    _nombre = null;
    _correo = null;
    _idTipo = null;
    _nombreTipoUsuario = null;
    _limpiarRondaActiva();
    notifyListeners();
  }

  void iniciarRonda({
    required int idRondaUsuario,
    required int idRondaAsignada,
    required String tipoRonda,
  }) {
    _idRondaUsuarioActiva = idRondaUsuario;
    _idRondaAsignadaActiva = idRondaAsignada;
    _tipoRondaActiva = tipoRonda;
    _rondaEnCurso = true;
    notifyListeners();
  }

  void finalizarRonda() {
    _limpiarRondaActiva();
    notifyListeners();
  }

  void _limpiarRondaActiva() {
    _idRondaUsuarioActiva = null;
    _idRondaAsignadaActiva = null;
    _tipoRondaActiva = null;
    _rondaEnCurso = false;
  }

  String get nombreCorto {
    if (_nombre == null) return 'Usuario';
    return _nombre!.split(' ').first;
  }

  bool get esAdmin => _idTipo == 1;
}
