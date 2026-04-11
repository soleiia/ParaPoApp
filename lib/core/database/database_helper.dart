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
    final path = join(dbPath, 'para_po_v3.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transportation (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT    NOT NULL,
        fare    REAL    NOT NULL DEFAULT 0,
        active  INTEGER NOT NULL DEFAULT 1,
        emoji   TEXT    NOT NULL DEFAULT '🚌',
        type    TEXT    NOT NULL DEFAULT 'JEEPNEY'
      )
    ''');
    await db.execute('''
      CREATE TABLE routes (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        origin           TEXT NOT NULL,
        destination      TEXT NOT NULL,
        fare             REAL NOT NULL DEFAULT 0,
        origin_lat       REAL,
        origin_lng       REAL,
        dest_lat         REAL,
        dest_lng         REAL,
        transport_type   TEXT NOT NULL DEFAULT 'JEEPNEY'
      )
    ''');
    await db.execute('''
      CREATE TABLE terminals (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category    TEXT NOT NULL,
        name        TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        emoji       TEXT NOT NULL DEFAULT '📍',
        lat         REAL,
        lng         REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE zones (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        color_hex  TEXT    NOT NULL DEFAULT 'FF3B6FE0',
        stop_count INTEGER NOT NULL DEFAULT 0,
        barangays  TEXT    NOT NULL DEFAULT ''
      )
    ''');
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // ── Transportation ─────────────────────────────────────────────────────
    for (final t in [
      {
        'name': 'Jeepney (Traditional)',
        'fare': 15.00,
        'active': 1,
        'emoji': '🚌',
        'type': 'JEEPNEY'
      },
      {
        'name': 'Jeepney (Modern)',
        'fare': 17.00,
        'active': 1,
        'emoji': '🚌',
        'type': 'JEEPNEY'
      },
      {
        'name': 'Tricycle (Solo)',
        'fare': 17.00,
        'active': 1,
        'emoji': '🛺',
        'type': 'TRICYCLE'
      },
    ]) {
      await db.insert('transportation', t);
    }

    // ── Routes ─────────────────────────────────────────────────────────────
    // Coordinates: origin_lat, origin_lng, dest_lat, dest_lng
    // Cabuyao Terminal (Sala): 14.2738, 121.1251
    // Calamba City Terminal:   14.2097, 121.1601
    // Sta. Rosa City Hall:     14.3122, 121.1122
    // Biñan City Terminal:     14.3392, 121.0789
    // Los Baños Terminal:      14.1663, 121.2397
    // Pasay Bus Terminal:      14.5378, 120.9980
    // SM Calamba:              14.2134, 121.1568
    // Cabuyao Market:          14.2756, 121.1234
    // Bigaa Terminal:          14.2894, 121.1219
    // Pulo Terminal:           14.2627, 121.1179
    // Butong Barangay Hall:    14.2651, 121.1098
    // Mamatid Terminal:        14.2435, 121.1356
    // Sta. Cruz Laguna:        14.2768, 121.4137
    // San Pablo City:          14.0688, 121.3224
    for (final r in [
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Calamba City Terminal',
        'fare': 20.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.2097,
        'dest_lng': 121.1601,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Sta. Rosa City Hall',
        'fare': 17.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.3122,
        'dest_lng': 121.1122,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Biñan City Terminal',
        'fare': 24.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.3392,
        'dest_lng': 121.0789,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Los Baños Public Market',
        'fare': 51.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.1663,
        'dest_lng': 121.2397,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'SM City Calamba',
        'fare': 35.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.2134,
        'dest_lng': 121.1568,
        'transport_type': 'UV_EXPRESS',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Pasay Bus Terminal (Manila)',
        'fare': 110.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.5378,
        'dest_lng': 120.9980,
        'transport_type': 'BUS',
      },
      {
        'origin': 'Cabuyao Public Market',
        'destination': 'Calamba City Terminal',
        'fare': 18.00,
        'origin_lat': 14.2756,
        'origin_lng': 121.1234,
        'dest_lat': 14.2097,
        'dest_lng': 121.1601,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Bigaa Terminal',
        'destination': 'Cabuyao Terminal (Sala)',
        'fare': 13.00,
        'origin_lat': 14.2894,
        'origin_lng': 121.1219,
        'dest_lat': 14.2738,
        'dest_lng': 121.1251,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Pulo Terminal',
        'destination': 'Cabuyao Terminal (Sala)',
        'fare': 13.00,
        'origin_lat': 14.2627,
        'origin_lng': 121.1179,
        'dest_lat': 14.2738,
        'dest_lng': 121.1251,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Butong Barangay',
        'destination': 'Calamba City Terminal',
        'fare': 22.00,
        'origin_lat': 14.2651,
        'origin_lng': 121.1098,
        'dest_lat': 14.2097,
        'dest_lng': 121.1601,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Mamatid Terminal',
        'destination': 'SM City Calamba',
        'fare': 20.00,
        'origin_lat': 14.2435,
        'origin_lng': 121.1356,
        'dest_lat': 14.2134,
        'dest_lng': 121.1568,
        'transport_type': 'JEEPNEY',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'Sta. Cruz, Laguna',
        'fare': 70.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.2768,
        'dest_lng': 121.4137,
        'transport_type': 'BUS',
      },
      {
        'origin': 'Cabuyao Terminal (Sala)',
        'destination': 'San Pablo City',
        'fare': 65.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.0688,
        'dest_lng': 121.3224,
        'transport_type': 'BUS',
      },
      {
        'origin': 'Sala (City Center)',
        'destination': 'Pulo Barangay',
        'fare': 15.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.2627,
        'dest_lng': 121.1179,
        'transport_type': 'TRICYCLE',
      },
      {
        'origin': 'Sala (City Center)',
        'destination': 'Mamatid',
        'fare': 25.00,
        'origin_lat': 14.2738,
        'origin_lng': 121.1251,
        'dest_lat': 14.2435,
        'dest_lng': 121.1356,
        'transport_type': 'TRICYCLE',
      },
    ]) {
      await db.insert('routes', r);
    }

    // ── Terminals ──────────────────────────────────────────────────────────
    for (final t in [
      {
        'category': 'PUBLIC TERMINAL',
        'name': 'Cabuyao City Public Terminal',
        'description':
            'Main transportation hub in Barangay Sala. Jeepney, UV Express, and bus routes depart from here.',
        'emoji': '🚉',
        'lat': 14.2738,
        'lng': 121.1251
      },
      {
        'category': 'MARKET TERMINAL',
        'name': 'Cabuyao Public Market Terminal',
        'description':
            'Terminal adjacent to Cabuyao Public Market. Serves local routes and inter-city jeepneys.',
        'emoji': '🏪',
        'lat': 14.2756,
        'lng': 121.1234
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Bigaa Terminal',
        'description':
            'Serves Barangay Bigaa and connecting routes to Cabuyao City Center and Biñan.',
        'emoji': '🚌',
        'lat': 14.2894,
        'lng': 121.1219
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Butong Terminal',
        'description':
            'Terminal in Barangay Butong. Routes to Calamba and Cabuyao City Center.',
        'emoji': '🚌',
        'lat': 14.2651,
        'lng': 121.1098
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Mamatid Terminal',
        'description':
            'Serves Barangay Mamatid. Connects to SM Calamba and Cabuyao routes.',
        'emoji': '🚌',
        'lat': 14.2435,
        'lng': 121.1356
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Pulo Tricycle Terminal',
        'description':
            'Tricycle terminal in Barangay Pulo. Serves local commuters within the barangay.',
        'emoji': '🛺',
        'lat': 14.2627,
        'lng': 121.1179
      },
      {
        'category': 'BUS STOP',
        'name': 'Cabuyao National Highway Bus Stop (DLTB)',
        'description':
            'Bus stop along the National Highway. Serves DLTB bus lines going to Manila and Sta. Cruz.',
        'emoji': '🚍',
        'lat': 14.2720,
        'lng': 121.1280
      },
      {
        'category': 'UV EXPRESS HUB',
        'name': 'Cabuyao UV Express Hub',
        'description':
            'Boarding point for UV Express vans going to SM Calamba and Pasay Terminal.',
        'emoji': '🚐',
        'lat': 14.2745,
        'lng': 121.1260
      },
      {
        'category': 'TERMINAL',
        'name': 'Pittland Terminal',
        'description':
            'Subdivision terminal near Pittland, Cabuyao. Tricycles and local jeepneys.',
        'emoji': '🏘️',
        'lat': 14.2561,
        'lng': 121.1418
      },
      {
        'category': 'TERMINAL',
        'name': 'Baclaran Junction Terminal',
        'description':
            'Junction terminal at Baclaran. Connects to Manila-bound routes.',
        'emoji': '🔀',
        'lat': 14.2480,
        'lng': 121.1390
      },
    ]) {
      await db.insert('terminals', t);
    }

    // ── Zones ──────────────────────────────────────────────────────────────
    for (final z in [
      {
        'name': 'Zone 1 – City Center',
        'color_hex': 'FF3B6FE0',
        'stop_count': 15,
        'barangays': 'Sala, Banay-Banay, Pulo'
      },
      {
        'name': 'Zone 2 – Northern District',
        'color_hex': 'FF43A047',
        'stop_count': 12,
        'barangays': 'Bigaa, Butong, Talavera, Gulod'
      },
      {
        'name': 'Zone 3 – Southern District',
        'color_hex': 'FFE53935',
        'stop_count': 10,
        'barangays': 'Mamatid, Pittland, Baclaran, Niugan'
      },
      {
        'name': 'Zone 4 – Industrial Zone',
        'color_hex': 'FFEF6C00',
        'stop_count': 8,
        'barangays': 'LIIP Area (Light Industry & Science Park)'
      },
      {
        'name': 'Zone 5 – Highway Corridor',
        'color_hex': 'FF8E24AA',
        'stop_count': 18,
        'barangays':
            'National Highway corridor from Biñan boundary to Calamba boundary'
      },
    ]) {
      await db.insert('zones', z);
    }
  }

  // ── Generic helpers ────────────────────────────────────────────────────────
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

  Future<int> count(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
    return (result.first['c'] as int? ?? 0);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
