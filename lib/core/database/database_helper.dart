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
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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
      {'name': 'Metra Electric',                  'fare': 2.25, 'active': 1, 'emoji': '🚊'},
      {'name': 'CTA Bus #151',                    'fare': 2.50, 'active': 0, 'emoji': '🚌'},
      {'name': 'Pace Bus #755',                   'fare': 3.00, 'active': 1, 'emoji': '🚍'},
      {'name': 'Chicago Water Taxi',              'fare': 8.00, 'active': 1, 'emoji': '⛴️'},
      {'name': 'Divvy Bike Share',                'fare': 3.00, 'active': 1, 'emoji': '🚲'},
      {'name': 'Chicago Transit Authority (CTA)', 'fare': 2.50, 'active': 1, 'emoji': '🚇'},
      {'name': 'Zipcar Car Share',                'fare': 6.00, 'active': 1, 'emoji': '🚗'},
    ]) { await db.insert('transportation', t); }

    for (final r in [
      {'origin': 'New York',      'destination': 'Los Angeles',   'fare': 5.00},
      {'origin': 'Los Angeles',   'destination': 'Chicago',       'fare': 8.00},
      {'origin': 'Chicago',       'destination': 'New York',      'fare': 10.00},
      {'origin': 'San Francisco', 'destination': 'Miami',         'fare': 6.00},
      {'origin': 'Miami',         'destination': 'Houston',       'fare': 9.00},
      {'origin': 'Houston',       'destination': 'San Francisco', 'fare': 12.00},
      {'origin': 'Boston',        'destination': 'Seattle',       'fare': 7.00},
      {'origin': 'Seattle',       'destination': 'Denver',        'fare': 5.50},
    ]) { await db.insert('routes', r); }

    for (final t in [
      {'category': 'COFFEE SHOP',          'name': 'Coffee Shop',         'description': 'Located at the corner of 5th and Main.',                     'emoji': '☕'},
      {'category': 'LIBRARY',              'name': 'Library',             'description': 'Features a wide selection of books and a quiet reading room.', 'emoji': '📚'},
      {'category': 'CITY HALL',            'name': 'City Hall',           'description': 'Home to city council meetings and administrative offices.',     'emoji': '🏛️'},
      {'category': 'UNIVERSITY CAFETERIA', 'name': 'University Cafeteria','description': 'Serves a variety of international cuisines and hosts events.', 'emoji': '🍽️'},
      {'category': 'MUSEUM',               'name': 'Museum',              'description': 'Features rotating exhibits and educational programs.',          'emoji': '🏺'},
      {'category': 'COMMUNITY CENTER',     'name': 'Community Center',    'description': 'Hosts events, classes, and community gatherings.',             'emoji': '🏢'},
    ]) { await db.insert('terminals', t); }

    for (final z in [
      {'name': 'Zone A - Downtown',   'color_hex': 'FF3B6FE0', 'stop_count': 12},
      {'name': 'Zone B - Midtown',    'color_hex': 'FF43A047', 'stop_count': 8},
      {'name': 'Zone C - Uptown',     'color_hex': 'FFE53935', 'stop_count': 6},
      {'name': 'Zone D - Suburbs',    'color_hex': 'FFFFC200', 'stop_count': 15},
      {'name': 'Zone E - Industrial', 'color_hex': 'FF8E24AA', 'stop_count': 4},
    ]) { await db.insert('zones', z); }
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

  Future<List<Map<String, dynamic>>> search(String table, String column, String query) async {
    final db = await database;
    return db.query(table, where: '$column LIKE ?', whereArgs: ['%$query%'], orderBy: 'id ASC');
  }
}
