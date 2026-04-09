import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'para_po.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transportation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        fare REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        emoji TEXT NOT NULL DEFAULT '🚌'
      )
    ''');
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        fare REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE terminals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        emoji TEXT NOT NULL DEFAULT '📍'
      )
    ''');
    await db.execute('''
      CREATE TABLE zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT 'FF3B6FE0',
        stop_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    for (final t in [
      {'name': 'Jeepney', 'fare': 13.00, 'active': 1, 'emoji': '🚙'},
      {'name': 'Tricycle', 'fare': 17.00, 'active': 1, 'emoji': '🛺'},
    ]) {
      await db.insert('transportation', t);
    }

    for (final r in [
      {
        'origin': 'ANYWHERE ON AH-26',
        'destination': 'ANYWHERE ON AH-26',
        'fare': 13.00
      },
      {
        'origin': 'ANYWHERE ON AH-26',
        'destination': 'Pulo Diezmo Road Tricycle Station',
        'fare': 13.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Cabuyao Coliseum',
        'fare': 15.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'San Carlos Village',
        'fare': 15.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Villa Adelina Subdivision',
        'fare': 15.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Unilever/JJ',
        'fare': 17.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Lazada Warehouse',
        'fare': 17.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Mapua Malayan Colleges of Laguna',
        'fare': 17.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ninja Van Sta. Elena',
        'fare': 17.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 1',
        'fare': 19.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 2',
        'fare': 17.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 3',
        'fare': 19.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ilaya',
        'fare': 22.00
      },
      {
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Diezmo',
        'fare': 25.00
      },
    ]) {
      await db.insert('routes', r);
    }

    for (final t in [
      {
        'category': 'COFFEE SHOP',
        'name': 'Coffee Shop',
        'description': 'Located at the corner of 5th and Main.',
        'emoji': '☕'
      },
      {
        'category': 'LIBRARY',
        'name': 'Library',
        'description':
            'Features a wide selection of books and a quiet reading room.',
        'emoji': '📚'
      },
      {
        'category': 'CITY HALL',
        'name': 'City Hall',
        'description':
            'Home to city council meetings and administrative offices.',
        'emoji': '🏛️'
      },
      {
        'category': 'UNIVERSITY CAFETERIA',
        'name': 'University Cafeteria',
        'description':
            'Serves a variety of international cuisines and hosts events.',
        'emoji': '🍽️'
      },
      {
        'category': 'MUSEUM',
        'name': 'Museum',
        'description': 'Features rotating exhibits and educational programs.',
        'emoji': '🏺'
      },
      {
        'category': 'COMMUNITY CENTER',
        'name': 'Community Center',
        'description': 'Hosts events, classes, and community gatherings.',
        'emoji': '🏢'
      },
    ]) {
      await db.insert('terminals', t);
    }

    for (final z in [
      {'name': 'Zone A - Downtown', 'color_hex': 'FF3B6FE0', 'stop_count': 12},
      {'name': 'Zone B - Midtown', 'color_hex': 'FF43A047', 'stop_count': 8},
      {'name': 'Zone C - Uptown', 'color_hex': 'FFE53935', 'stop_count': 6},
      {'name': 'Zone D - Suburbs', 'color_hex': 'FFFFC200', 'stop_count': 15},
      {'name': 'Zone E - Industrial', 'color_hex': 'FF8E24AA', 'stop_count': 4},
    ]) {
      await db.insert('zones', z);
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table, orderBy: 'id ASC');
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> search(
      String table, String column, String query) async {
    final db = await database;
    return db.query(table,
        where: '$column LIKE ?', whereArgs: ['%$query%'], orderBy: 'id ASC');
  }
}
