// Archivo principal que maneja la conexión y estructura de la base de datos SQLite

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // PATRÓN SINGLETON
  // ============================================================================
  // Garantiza que solo exista una instancia de DatabaseHelper en toda la app
  // Esto evita múltiples conexiones a la BD y problemas de concurrencia

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Constructor factory: siempre devuelve la misma instancia
  factory DatabaseHelper() {
    return _instance;
  }

  // Constructor privado: no se puede llamar desde fuera de esta clase
  DatabaseHelper._internal();

  // GETTER DE LA BASE DE DATOS
  // ============================================================================
  // Proporciona acceso a la BD, creándola si no existe

  Future<Database> get database async {
    // Si ya existe la BD, la devuelve
    if (_database != null) return _database!;

    // Si no existe, la crea e inicializa
    _database = await _initDatabase();
    return _database!;
  }

  // INICIALIZACIÓN DE LA BASE DE DATOS
  // ============================================================================

  Future<Database> _initDatabase() async {
    // Obtiene la ruta donde se guardará la BD en el dispositivo
    // Ejemplo en Android: /data/data/com.tu.app/databases/rondas_app.db
    String path = join(await getDatabasesPath(), 'rondas_app.db');

    return await openDatabase(
      path,
      version: 1, // Versión actual de la BD (se usa para migraciones)
      onCreate: _onCreate, // Se ejecuta solo la primera vez que se crea la BD
    );
  }

  // CREACIÓN DE TABLAS
  // ============================================================================
  // Se ejecuta SOLO cuando la app se instala por primera vez

  Future<void> _onCreate(Database db, int version) async {
    // TABLA: tipos_de_usuarios
    // Almacena los tipos de usuario (Admin, Guardia, Supervisor, etc.)
    // Datos de solo lectura que vienen de la nube
    await db.execute('''
      CREATE TABLE tipos_de_usuarios (
        tipo_id INTEGER PRIMARY KEY,
        nombre_tipo_usuario TEXT NOT NULL
      )
    ''');

    // TABLA: usuarios
    // Información de los usuarios del sistema
    // La contraseña debería estar hasheada (esto se manejara en el backend)
    await db.execute('''
      CREATE TABLE usuarios (
        id_usuario INTEGER PRIMARY KEY,
        id_tipo INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        contrasena TEXT NOT NULL,
        correo TEXT,
        FOREIGN KEY (id_tipo) REFERENCES tipos_de_usuarios(tipo_id)
      )
    ''');

    // TABLA: Tipo_ronda
    // Catalogo de tipos de rondas (Ixterior, Interior)
    await db.execute('''
      CREATE TABLE Tipo_ronda (
        id_tipo INTEGER PRIMARY KEY,
        nombre_tipo_ronda TEXT NOT NULL
      )
    ''');

    // TABLA: Coordenadas_admin
    // Puntos de control/checkpoints definidos por el administrador
    // Estos son los lugares donde el guardia debe pasar
    await db.execute('''
      CREATE TABLE Coordenadas_admin (
        id_coordenada_admin INTEGER PRIMARY KEY,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        nombre_coordenada TEXT NOT NULL
      )
    ''');

    // TABLA: Qr
    // Códigos QR asignados a cada coordenada
    // El guardia debe escanear estos QR para verificar su presencia
    await db.execute('''
      CREATE TABLE Qr (
        id_coordenada_admin INTEGER PRIMARY KEY,
        codigo_qr TEXT NOT NULL,
        FOREIGN KEY (id_coordenada_admin) REFERENCES Coordenadas_admin(id_coordenada_admin)
      )
    ''');

    // TABLA: Ronda_asignada
    // Rondas programadas que se asignan a los usuarios
    // Descargadas desde la nube al iniciar sesión
    await db.execute('''
      CREATE TABLE Ronda_asignada (
        id_ronda_asignada INTEGER PRIMARY KEY,
        id_tipo INTEGER NOT NULL,
        id_usuario INTEGER NOT NULL,
        fecha_de_ejecucion TEXT NOT NULL,
        hora_de_ejecucion TEXT NOT NULL,
        FOREIGN KEY (id_tipo) REFERENCES Tipo_ronda(id_tipo),
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
      )
    ''');

    // TABLA INTERMEDIA: ronda_coordenadas
    // Relaciona las rondas asignadas con sus coordenadas (checkpoints)
    // Esta tabla resuelve la relación muchos-a-muchos:
    // - Una ronda tiene múltiples coordenadas
    // - Una coordenada puede estar en múltiples rondas
    await db.execute('''
      CREATE TABLE ronda_coordenadas (
        id_ronda_asignada INTEGER NOT NULL,
        id_coordenada_admin INTEGER NOT NULL,
        orden INTEGER NOT NULL,
        PRIMARY KEY (id_ronda_asignada, id_coordenada_admin),
        FOREIGN KEY (id_ronda_asignada) REFERENCES Ronda_asignada(id_ronda_asignada),
        FOREIGN KEY (id_coordenada_admin) REFERENCES Coordenadas_admin(id_coordenada_admin)
      )
    ''');

    // TABLA: rondas_usuarios
    // Registro de rondas ejecutadas por los usuarios
    // Se crea localmente cuando el usuario completa una ronda
    await db.execute('''
      CREATE TABLE rondas_usuarios (
        id_ronda_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        id_ronda_asignada INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_final TEXT NOT NULL,
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
        FOREIGN KEY (id_ronda_asignada) REFERENCES Ronda_asignada(id_ronda_asignada)
      )
    ''');

    // TABLA: coordenadas_usuarios
    // Tracking de posición del usuario durante una ronda
    // Cada registro es un checkpoint verificado
    await db.execute('''
      CREATE TABLE coordenadas_usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_ronda_usuario INTEGER NOT NULL,
        hora_actual TEXT NOT NULL,
        latitud_actual REAL NOT NULL,
        longitud_actual REAL NOT NULL,
        codigo_qr TEXT,
        verificador INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_ronda_usuario) REFERENCES rondas_usuarios(id_ronda_usuario)
      )
    ''');

    // Índice para buscar rondas por usuario
    await db.execute('''
      CREATE INDEX idx_rondas_usuarios_id_usuario 
      ON rondas_usuarios(id_usuario)
    ''');

    // Índice para buscar coordenadas por ronda
    await db.execute('''
      CREATE INDEX idx_coordenadas_usuarios_id_ronda 
      ON coordenadas_usuarios(id_ronda_usuario)
    ''');

    // Índice para buscar rondas asignadas por usuario
    await db.execute('''
      CREATE INDEX idx_ronda_asignada_id_usuario 
      ON Ronda_asignada(id_usuario)
    ''');
  }

  // Se usa cuando el usuario cierra sesión y elige borrar todo

  Future<void> borrarTodosDatos() async {
    final db = await database;

    // Borra en orden inverso para respetar las foreign keys
    await db.delete('coordenadas_usuarios');
    await db.delete('rondas_usuarios');
    await db.delete('ronda_coordenadas');
    await db.delete('Ronda_asignada');
    await db.delete('Qr');
    await db.delete('Coordenadas_admin');
    await db.delete('Tipo_ronda');
    await db.delete('usuarios');
    await db.delete('tipos_de_usuarios');
  }

  // Mantiene las rondas ejecutadas localmente, borra solo datos descargados
  // Útil para actualizar datos sin perder el historial local

  Future<void> borrarDatosNube() async {
    final db = await database;

    // NO borra rondas_usuarios ni coordenadas_usuarios
    await db.delete('ronda_coordenadas');
    await db.delete('Ronda_asignada');
    await db.delete('Qr');
    await db.delete('Coordenadas_admin');
    await db.delete('Tipo_ronda');
    await db.delete('usuarios');
    await db.delete('tipos_de_usuarios');
  }

  // Se deberia llamar cuando la app se cierra

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
