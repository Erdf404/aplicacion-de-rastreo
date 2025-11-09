class TipoUsuario {
  final int tipoId;
  final String nombreTipoUsuario;

  TipoUsuario({required this.tipoId, required this.nombreTipoUsuario});

  Map<String, dynamic> toMap() {
    return {'tipo_id': tipoId, 'nombre_tipo_usuario': nombreTipoUsuario};
  }

  factory TipoUsuario.fromMap(Map<String, dynamic> map) {
    return TipoUsuario(
      tipoId: map['tipo_id'] as int,
      nombreTipoUsuario: map['nombre_tipo_usuario'] as String,
    );
  }

  factory TipoUsuario.fromJson(Map<String, dynamic> json) {
    return TipoUsuario(
      tipoId: json['tipo_id'] as int,
      nombreTipoUsuario: json['nombre_tipo_usuario']?.toString() ?? '',
    );
  }
}

class Usuario {
  final int idUsuario;
  final int idTipo;
  final String nombre;
  final String contrasena;
  final String? correo;

  Usuario({
    required this.idUsuario,
    required this.idTipo,
    required this.nombre,
    required this.contrasena,
    this.correo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_tipo': idTipo,
      'nombre': nombre,
      'contrasena': contrasena,
      'correo': correo,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['id_usuario'] as int,
      idTipo: map['id_tipo'] as int,
      nombre: map['nombre'] as String,
      contrasena: map['contrasena'] as String,
      correo: map['correo'] as String?,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int,
      idTipo: json['id_tipo'] as int,
      nombre: json['nombre'] as String,
      contrasena: json['contrasena']?.toString() ?? '',
      correo: json['correo'] as String?,
    );
  }
}

class TipoRonda {
  final int idTipo;
  final String nombreTipoRonda;

  TipoRonda({required this.idTipo, required this.nombreTipoRonda});

  Map<String, dynamic> toMap() {
    return {'id_tipo': idTipo, 'nombre_tipo_ronda': nombreTipoRonda};
  }

  factory TipoRonda.fromMap(Map<String, dynamic> map) {
    return TipoRonda(
      idTipo: map['id_tipo'] as int,
      nombreTipoRonda: map['nombre_tipo_ronda'] as String,
    );
  }

  factory TipoRonda.fromJson(Map<String, dynamic> json) {
    return TipoRonda(
      idTipo: json['id_tipo'] as int,
      nombreTipoRonda: json['nombre_tipo_ronda']?.toString() ?? '',
    );
  }
}

class CoordenadaAdmin {
  final int idCoordenadaAdmin;
  final double? latitud;
  final double? longitud;
  final String nombreCoordenada;
  final String? codigoQr;

  CoordenadaAdmin({
    required this.idCoordenadaAdmin,
    this.latitud,
    this.longitud,
    required this.nombreCoordenada,
    this.codigoQr,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_coordenada_admin': idCoordenadaAdmin,
      'latitud': latitud,
      'longitud': longitud,
      'nombre_coordenada': nombreCoordenada,
      'codigo_qr': codigoQr,
    };
  }

  factory CoordenadaAdmin.fromMap(Map<String, dynamic> map) {
    return CoordenadaAdmin(
      idCoordenadaAdmin: map['id_coordenada_admin'] as int,
      latitud: map['latitud'] != null
          ? (map['latitud'] as num).toDouble()
          : null,
      longitud: map['longitud'] != null
          ? (map['longitud'] as num).toDouble()
          : null,
      nombreCoordenada: map['nombre_coordenada'] as String,
      codigoQr: map['codigo_qr'] as String?,
    );
  }

  factory CoordenadaAdmin.fromJson(Map<String, dynamic> json) {
    return CoordenadaAdmin(
      idCoordenadaAdmin: json['id_coordenada_admin'] as int,
      latitud: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      nombreCoordenada: json['nombre_coordenada'] as String,
      codigoQr: json['codigo_qr']?.toString(),
    );
  }
}

class RondaAsignada {
  final int idRondaAsignada;
  final int idTipo;
  final int idUsuario;
  final String fechaDeEjecucion;
  final String horaDeEjecucion;
  final double? distanciaPermitida;

  RondaAsignada({
    required this.idRondaAsignada,
    required this.idTipo,
    required this.idUsuario,
    required this.fechaDeEjecucion,
    required this.horaDeEjecucion,
    this.distanciaPermitida,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_ronda_asignada': idRondaAsignada,
      'id_tipo': idTipo,
      'id_usuario': idUsuario,
      'fecha_de_ejecucion': fechaDeEjecucion,
      'hora_de_ejecucion': horaDeEjecucion,
      'distancia_permitida': distanciaPermitida ?? 50,
    };
  }

  factory RondaAsignada.fromMap(Map<String, dynamic> map) {
    return RondaAsignada(
      idRondaAsignada: map['id_ronda_asignada'] as int,
      idTipo: map['id_tipo'] as int,
      idUsuario: map['id_usuario'] as int,
      fechaDeEjecucion: map['fecha_de_ejecucion'] as String,
      horaDeEjecucion: map['hora_de_ejecucion'] as String,
      distanciaPermitida: map['distancia_permitida'] != null
          ? (map['distancia_permitida'] as num).toDouble()
          : 50.0,
    );
  }

  factory RondaAsignada.fromJson(Map<String, dynamic> json) {
    return RondaAsignada(
      idRondaAsignada: json['id_ronda_asignada'] as int,
      idTipo: json['id_tipo'] as int,
      idUsuario: json['id_usuario'] as int,
      fechaDeEjecucion: json['fecha_de_ejecucion'] as String,
      horaDeEjecucion: json['hora_de_ejecucion'] as String,
      distanciaPermitida: json['distancia_permitida'] != null
          ? (json['distancia_permitida'] as num).toDouble()
          : 50.0,
    );
  }
}

class RondaCoordenada {
  final int idRondaAsignada;
  final int idCoordenadaAdmin;
  final int orden;

  RondaCoordenada({
    required this.idRondaAsignada,
    required this.idCoordenadaAdmin,
    required this.orden,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_ronda_asignada': idRondaAsignada,
      'id_coordenada_admin': idCoordenadaAdmin,
      'orden': orden,
    };
  }

  factory RondaCoordenada.fromMap(Map<String, dynamic> map) {
    return RondaCoordenada(
      idRondaAsignada: map['id_ronda_asignada'] as int,
      idCoordenadaAdmin: map['id_coordenada_admin'] as int,
      orden: map['orden'] as int,
    );
  }

  factory RondaCoordenada.fromJson(Map<String, dynamic> json) {
    return RondaCoordenada(
      idRondaAsignada: json['id_ronda_asignada'] as int,
      idCoordenadaAdmin: json['id_coordenada_admin'] as int,
      orden: json['orden'] as int,
    );
  }
}

class RondaUsuario {
  final int? idRondaUsuario;
  final int idUsuario;
  final int idRondaAsignada;
  final String fecha;
  final String horaInicio;
  final String horaFinal;
  final bool sincronizada;

  RondaUsuario({
    this.idRondaUsuario,
    required this.idUsuario,
    required this.idRondaAsignada,
    required this.fecha,
    required this.horaInicio,
    required this.horaFinal,
    this.sincronizada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_ronda_usuario': idRondaUsuario,
      'id_usuario': idUsuario,
      'id_ronda_asignada': idRondaAsignada,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_final': horaFinal,
      'sincronizada': sincronizada ? 1 : 0,
    };
  }

  factory RondaUsuario.fromMap(Map<String, dynamic> map) {
    return RondaUsuario(
      idRondaUsuario: map['id_ronda_usuario'] as int?,
      idUsuario: map['id_usuario'] as int,
      idRondaAsignada: map['id_ronda_asignada'] as int,
      fecha: map['fecha'] as String,
      horaInicio: map['hora_inicio'] as String,
      horaFinal: map['hora_final'] as String,
      sincronizada: (map['sincronizada'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ronda_usuario': idRondaUsuario,
      'id_usuario': idUsuario,
      'id_ronda_asignada': idRondaAsignada,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_final': horaFinal,
    };
  }
}

class CoordenadaUsuario {
  final int? id;
  final int idRondaUsuario;
  final String horaActual;
  final double? latitudActual;
  final double? longitudActual;
  final String? codigoQr;
  final bool verificador;

  CoordenadaUsuario({
    this.id,
    required this.idRondaUsuario,
    required this.horaActual,
    this.latitudActual,
    this.longitudActual,
    this.codigoQr,
    required this.verificador,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_ronda_usuario': idRondaUsuario,
      'hora_actual': horaActual,
      'latitud_actual': latitudActual,
      'longitud_actual': longitudActual,
      'codigo_qr': codigoQr,
      'verificador': verificador ? 1 : 0,
    };
  }

  factory CoordenadaUsuario.fromMap(Map<String, dynamic> map) {
    return CoordenadaUsuario(
      id: map['id'] as int?,
      idRondaUsuario: map['id_ronda_usuario'] as int,
      horaActual: map['hora_actual'] as String,
      latitudActual: map['latitud_actual'] as double?,
      longitudActual: map['longitud_actual'] as double?,
      codigoQr: map['codigo_qr'] as String?,
      verificador: map['verificador'] == 1,
    );
  }
}
