// Archivo principal que maneja la conexión y estructura de la base de datos SQLite

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // GETTER DE LA BASE DE DATOS
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // INICIALIZACIÓN DE LA BASE DE DATOS
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rondas_app.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // CREACIÓN DE TABLAS
  Future<void> _onCreate(Database db, int version) async {
    // TABLA: tipos_de_usuarios
    await db.execute('''
      CREATE TABLE tipos_de_usuarios (
        tipo_id INTEGER PRIMARY KEY,
        nombre_tipo_usuario TEXT NOT NULL
      )
    ''');

    // TABLA: usuarios
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
    await db.execute('''
      CREATE TABLE Tipo_ronda (
        id_tipo INTEGER PRIMARY KEY,
        nombre_tipo_ronda TEXT NOT NULL
      )
    ''');

    // TABLA: Coordenadas_admin
    await db.execute('''
      CREATE TABLE Coordenadas_admin (
        id_coordenada_admin INTEGER PRIMARY KEY,
        latitud REAL,
        longitud REAL,
        nombre_coordenada TEXT NOT NULL,
        codigo_qr TEXT
      )
    ''');

    // TABLA: Ronda_asignada
    await db.execute('''
      CREATE TABLE Ronda_asignada (
        id_ronda_asignada INTEGER PRIMARY KEY,
        id_tipo INTEGER NOT NULL,
        id_usuario INTEGER NOT NULL,
        fecha_de_ejecucion TEXT NOT NULL,
        hora_de_ejecucion TEXT NOT NULL,
        distancia_permitida REAL NOT NULL,
        FOREIGN KEY (id_tipo) REFERENCES Tipo_ronda(id_tipo),
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
      )
    ''');

    // TABLA: ronda_coordenadas
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
    await db.execute('''
      CREATE TABLE rondas_usuarios (
        id_ronda_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        id_ronda_asignada INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_final TEXT NOT NULL,
        sincronizada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
        FOREIGN KEY (id_ronda_asignada) REFERENCES Ronda_asignada(id_ronda_asignada)
      )
    ''');

    // TABLA: coordenadas_usuarios
    await db.execute('''
      CREATE TABLE coordenadas_usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_ronda_usuario INTEGER NOT NULL,
        hora_actual TEXT NOT NULL,
        latitud_actual REAL,
        longitud_actual REAL,
        codigo_qr TEXT,
        verificador INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_ronda_usuario) REFERENCES rondas_usuarios(id_ronda_usuario)
      )
    ''');

    // Índices
    await db.execute('''
      CREATE INDEX idx_rondas_usuarios_id_usuario 
      ON rondas_usuarios(id_usuario)
    ''');

    await db.execute('''
      CREATE INDEX idx_rondas_usuarios_sincronizada 
      ON rondas_usuarios(sincronizada)
    ''');

    await db.execute('''
      CREATE INDEX idx_coordenadas_usuarios_id_ronda 
      ON coordenadas_usuarios(id_ronda_usuario)
    ''');

    await db.execute('''
      CREATE INDEX idx_ronda_asignada_id_usuario 
      ON Ronda_asignada(id_usuario)
    ''');
  }

  Future<void> borrarTodosDatos() async {
    final db = await database;

    await db.delete('coordenadas_usuarios');
    await db.delete('rondas_usuarios');
    await db.delete('ronda_coordenadas');
    await db.delete('Ronda_asignada');
    await db.delete('Coordenadas_admin');
    await db.delete('Tipo_ronda');
    await db.delete('usuarios');
    await db.delete('tipos_de_usuarios');
  }

  Future<void> borrarDatosNube() async {
    final db = await database;

    await db.delete('ronda_coordenadas');
    await db.delete('Ronda_asignada');
    await db.delete('Coordenadas_admin');
    await db.delete('Tipo_ronda');
    await db.delete('usuarios');
    await db.delete('tipos_de_usuarios');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
