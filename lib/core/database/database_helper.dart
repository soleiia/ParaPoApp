import 'dart:io';
import 'package:flutter/foundation.dart';
// Use a PREFIX so Dart always calls sqflite's native APIs on Android/iOS,
// never sqflite_common_ffi's versions. This prevents the "databaseFactory
// not initialized" crash on Android.
import 'package:sqflite/sqflite.dart' as sq;
// Only pull the two desktop-init symbols from sqflite_common_ffi.
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show sqfliteFfiInit, databaseFactoryFfi;
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static sq.Database? _db;

  DatabaseHelper._internal();

  Future<sq.Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<sq.Database> _initDb() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // Desktop: use sqflite_common_ffi (pure Dart FFI — no native plugin)
      sqfliteFfiInit();
      sq.databaseFactory = databaseFactoryFfi;
    }
    // Android & iOS: sq.getDatabasesPath() uses sqflite's native plugin.
    // Desktop: databaseFactoryFfi was set above, sq.openDatabase routes through it.
    final dbPath = await sq.getDatabasesPath();
    final path = join(dbPath, 'para_po_v7.db');
    return await sq.openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(sq.Database db, int oldV, int newV) async {
    // Drop all tables and recreate fresh on any schema change
    for (final t in ['transportation', 'routes', 'terminals', 'zones', 'settings']) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
    await _onCreate(db, newV);
  }

  Future<void> _onCreate(sq.Database db, int version) async {
    // ── Transportation ────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE transportation (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        name   TEXT    NOT NULL,
        fare   REAL    NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        emoji  TEXT    NOT NULL DEFAULT '🚌'
      )
    ''');

    // ── Routes ────────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE routes (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        transport_type TEXT    NOT NULL DEFAULT 'Jeepney (Traditional)',
        origin         TEXT    NOT NULL,
        destination    TEXT    NOT NULL,
        fare           REAL    NOT NULL DEFAULT 0,
        via            TEXT    NOT NULL DEFAULT '',
        origin_lat     REAL    NOT NULL DEFAULT 14.2724,
        origin_lng     REAL    NOT NULL DEFAULT 121.1241,
        dest_lat       REAL    NOT NULL DEFAULT 14.2724,
        dest_lng       REAL    NOT NULL DEFAULT 121.1241
      )
    ''');

    // ── Terminals ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE terminals (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category    TEXT    NOT NULL,
        name        TEXT    NOT NULL,
        description TEXT    NOT NULL DEFAULT '',
        emoji       TEXT    NOT NULL DEFAULT '📍'
      )
    ''');

    // ── Zones ─────────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE zones (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        color_hex  TEXT    NOT NULL DEFAULT 'FF3B6FE0',
        stop_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Settings ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(sq.Database db) async {
    // ── Settings ──────────────────────────────────────────────────────────────
    await db.insert('settings', {'key': 'admin_pin', 'value': '1234'});

    // ── TRANSPORTATION (4 types only) ─────────────────────────────────────────
    for (final t in [
      {'name': 'Tricycle',              'fare': 17.00, 'active': 1, 'emoji': '🛺'},
      {'name': 'E-Tricycle',            'fare': 17.00, 'active': 1, 'emoji': '🛵'},
      {'name': 'Jeepney (Traditional)', 'fare': 15.00, 'active': 1, 'emoji': '🚙'},
      {'name': 'Jeepney (Modern)',      'fare': 17.00, 'active': 1, 'emoji': '🚌'},
    ]) {
      await db.insert('transportation', t);
    }

    // ── ROUTES — with real Cabuyao, Laguna GPS coordinates ─────────────────
    // Key coordinates (WGS-84 decimal degrees):
    //   Cabuyao City Hall (Poblacion): 14.2775, 121.1243
    //   Bigaa Junction AH-26:          14.2638, 121.1305
    //   Marinig:                       14.2566, 121.1359
    //   Niugan / Nestlé Gate:          14.2487, 121.1426
    //   Pittland / LISP I:             14.2429, 121.1469
    //   Pulo / Diezmo Road Jct:        14.2385, 121.1502
    //   Sala / Asia Brewery:           14.2395, 121.1095
    //   Calamba City Hall:             14.2106, 121.1654
    //   SM City Calamba:               14.2053, 121.1687
    //   Balibago Complex (Sta. Rosa):  14.3115, 121.1119
    //   SM City Sta. Rosa:             14.3240, 121.1076
    //   Biñan City Hall:               14.3408, 121.0793
    //   Mamatid Terminal:              14.2659, 121.1378
    //   Alabang (Muntinlupa):          14.4210, 121.0340
    //   Pulo Diezmo Rd Tricycle Term:  14.2385, 121.1502
    //   Cabuyao Coliseum:              14.2401, 121.1490
    //   San Carlos Village:            14.2370, 121.1510
    //   Villa Adelina Subdivision:     14.2355, 121.1520
    //   Unilever / JJ:                 14.2340, 121.1528
    //   Lazada Warehouse:              14.2330, 121.1535
    //   Mapúa MCL (64V7+7C):           14.2427, 121.1126  ← verified Plus Code
    //   Ninja Van Sta. Elena:          14.2310, 121.1550
    //   LISP Gate 1:                   14.2398, 121.1472
    //   LISP Gate 2:                   14.2385, 121.1502
    //   LISP Gate 3:                   14.2370, 121.1516
    //   Ilaya (Diezmo Interior):       14.2290, 121.1545
    //   Diezmo Proper:                 14.2250, 121.1570
    //   Poblacion Tricycle Terminal:   14.2775, 121.1243
    //   Brgy Uno:                      14.2780, 121.1230
    //   Brgy Dos:                      14.2785, 121.1218
    //   Brgy Tres:                     14.2790, 121.1205
    //   Banaybanay:                    14.2820, 121.1185
    //   Banlic:                        14.2750, 121.1200
    //   Gulod:                         14.2700, 121.1220
    //   Casile:                        14.2680, 121.1195
    //   San Isidro:                    14.2730, 121.1160
    //   Bigaa Tricycle Terminal:       14.2638, 121.1305
    //   Bigaa Lakeshore:               14.2580, 121.1270
    //   Bigaa Elem School:             14.2610, 121.1290
    //   Butong:                        14.2560, 121.1310
    //   Sala Tricycle Terminal:        14.2404, 121.1088  ← on AH-26 in Brgy Sala
    //   Asia Brewery / Tanduay:        14.2295, 121.1560
    //   Sala Lakeshore:                14.2280, 121.1540
    //   Niugan Nestlé:                 14.2487, 121.1426
    //   Mamatid Tricycle Terminal:     14.2659, 121.1378
    //   Mamatid PNR Station:           14.2670, 121.1360
    //   San Vicente Ferrer Shrine:     14.2680, 121.1350
    //   Goldilocks Plant:              14.2645, 121.1390
    //   Pacita Complex (San Pedro):    14.3500, 121.0540
    //   Pulo Diezmo E-Tricycle Term:   14.2385, 121.1502
    //   Poblacion E-Tricycle Terminal: 14.2775, 121.1243
    //   Mamatid E-Tricycle Terminal:   14.2659, 121.1378

    // Jeepney (Traditional) — National Highway / AH-26
    for (final r in [
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Bigaa Junction',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2638, 'dest_lng': 121.1305,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Marinig',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2566, 'dest_lng': 121.1359,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Niugan / Nestlé Gate',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2487, 'dest_lng': 121.1426,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Pittland / LISP I',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2429, 'dest_lng': 121.1469,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Pulo / Diezmo Road Junction',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2452, 'dest_lng': 121.1279,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Sala / Asia Brewery',
        'fare': 15.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2395, 'dest_lng': 121.1095,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Calamba City Hall',
        'fare': 18.00, 'via': 'National Highway (AH-26) southbound',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2106, 'dest_lng': 121.1654,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'SM City Calamba',
        'fare': 20.00, 'via': 'National Highway (AH-26) southbound',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2053, 'dest_lng': 121.1687,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 18.00, 'via': 'National Highway (AH-26) northbound',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.3115, 'dest_lng': 121.1119,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)', 'destination': 'SM City Sta. Rosa',
        'fare': 20.00, 'via': 'National Highway (AH-26) northbound',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.3240, 'dest_lng': 121.1076,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)', 'destination': 'Biñan City Hall',
        'fare': 20.00, 'via': 'National Highway northbound',
        'origin_lat': 14.3115, 'origin_lng': 121.1119, 'dest_lat': 14.3408, 'dest_lng': 121.0793,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal', 'destination': 'Cabuyao City Hall (Poblacion)',
        'fare': 15.00, 'via': 'Mamatid Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2775, 'dest_lng': 121.1243,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal', 'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 25.00, 'via': 'SLEX / Mamplasan Exit',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.3115, 'dest_lng': 121.1119,
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal', 'destination': 'Alabang (Muntinlupa)',
        'fare': 50.00, 'via': 'SLEX / Alabang Exit',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.4210, 'dest_lng': 121.0340,
      },
    ]) { await db.insert('routes', r); }

    // Jeepney (Modern)
    for (final r in [
      {
        'transport_type': 'Jeepney (Modern)',
        'origin': 'Cabuyao Terminal (Poblacion)', 'destination': 'SM City Calamba',
        'fare': 17.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2053, 'dest_lng': 121.1687,
      },
      {
        'transport_type': 'Jeepney (Modern)',
        'origin': 'Cabuyao Terminal (Poblacion)', 'destination': 'Balibago Complex (Sta. Rosa)',
        'fare': 17.00, 'via': 'National Highway (AH-26)',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.3115, 'dest_lng': 121.1119,
      },
      {
        'transport_type': 'Jeepney (Modern)',
        'origin': 'Pacita Terminal (San Pedro)', 'destination': 'SM City Calamba',
        'fare': 35.00, 'via': 'National Highway via Cabuyao',
        'origin_lat': 14.3500, 'origin_lng': 121.0540, 'dest_lat': 14.2053, 'dest_lng': 121.1687,
      },
    ]) { await db.insert('routes', r); }

    // Tricycle — Pulo Diezmo Road Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Anywhere on AH-26 (drop-off)',
        'fare': 13.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2452, 'dest_lng': 121.1285,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Cabuyao Coliseum',
        'fare': 15.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2452, 'dest_lng': 121.1340,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'San Carlos Village',
        'fare': 15.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2448, 'dest_lng': 121.1380,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Villa Adelina Subdivision',
        'fare': 15.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2445, 'dest_lng': 121.1415,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Unilever / JJ',
        'fare': 17.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2440, 'dest_lng': 121.1450,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Lazada Warehouse',
        'fare': 17.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2435, 'dest_lng': 121.1475,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Mapúa Malayan Colleges Laguna',
        'fare': 17.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2427, 'dest_lng': 121.1126,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Ninja Van Sta. Elena',
        'fare': 17.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2420, 'dest_lng': 121.1520,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Gate 1 (LISP / Industrial)',
        'fare': 19.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2415, 'dest_lng': 121.1540,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Gate 2 (LISP / Industrial)',
        'fare': 17.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2405, 'dest_lng': 121.1555,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Gate 3 (LISP / Industrial)',
        'fare': 19.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2395, 'dest_lng': 121.1568,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Ilaya (Diezmo Interior)',
        'fare': 22.00, 'via': 'Pulo Diezmo Road → Ilaya',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2350, 'dest_lng': 121.1590,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal', 'destination': 'Diezmo Proper',
        'fare': 25.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2300, 'dest_lng': 121.1610,
      },
    ]) { await db.insert('routes', r); }

    // Tricycle — Poblacion / City Hall Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Barangay Uno (Pob.)',
        'fare': 15.00, 'via': 'Poblacion streets',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2780, 'dest_lng': 121.1230,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Barangay Dos (Pob.)',
        'fare': 15.00, 'via': 'Poblacion streets',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2785, 'dest_lng': 121.1218,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Barangay Tres (Pob.)',
        'fare': 15.00, 'via': 'Poblacion streets',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2790, 'dest_lng': 121.1205,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Banaybanay',
        'fare': 17.00, 'via': 'Poblacion → Banaybanay Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2820, 'dest_lng': 121.1185,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Banlic',
        'fare': 17.00, 'via': 'Poblacion → Banlic Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2750, 'dest_lng': 121.1200,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Gulod',
        'fare': 20.00, 'via': 'Poblacion → Gulod Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2700, 'dest_lng': 121.1220,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'Casile',
        'fare': 20.00, 'via': 'Poblacion → Casile Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2680, 'dest_lng': 121.1195,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)', 'destination': 'San Isidro',
        'fare': 17.00, 'via': 'Poblacion → San Isidro Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2730, 'dest_lng': 121.1160,
      },
    ]) { await db.insert('routes', r); }

    // Tricycle — Bigaa Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal', 'destination': 'Bigaa Lakeshore (Laguna de Bay)',
        'fare': 15.00, 'via': 'Bigaa Road',
        'origin_lat': 14.2638, 'origin_lng': 121.1305, 'dest_lat': 14.2580, 'dest_lng': 121.1270,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal', 'destination': 'Bigaa Elementary School',
        'fare': 15.00, 'via': 'Bigaa Road',
        'origin_lat': 14.2638, 'origin_lng': 121.1305, 'dest_lat': 14.2610, 'dest_lng': 121.1290,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal', 'destination': 'Butong',
        'fare': 17.00, 'via': 'Bigaa → Butong Road',
        'origin_lat': 14.2638, 'origin_lng': 121.1305, 'dest_lat': 14.2560, 'dest_lng': 121.1310,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal', 'destination': 'Marinig',
        'fare': 17.00, 'via': 'Bigaa → Marinig Road',
        'origin_lat': 14.2638, 'origin_lng': 121.1305, 'dest_lat': 14.2566, 'dest_lng': 121.1359,
      },
    ]) { await db.insert('routes', r); }

    // Tricycle — Sala Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal', 'destination': 'Asia Brewery / Tanduay',
        'fare': 15.00, 'via': 'Sala Road',
        'origin_lat': 14.2404, 'origin_lng': 121.1088, 'dest_lat': 14.2395, 'dest_lng': 121.1095,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal', 'destination': 'Sala Lakeshore (Laguna de Bay)',
        'fare': 17.00, 'via': 'Sala Road → Lakeshore',
        'origin_lat': 14.2404, 'origin_lng': 121.1088, 'dest_lat': 14.2360, 'dest_lng': 121.1340,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal', 'destination': 'Niugan (Nestlé Philippines)',
        'fare': 17.00, 'via': 'Sala → Niugan Road',
        'origin_lat': 14.2404, 'origin_lng': 121.1088, 'dest_lat': 14.2487, 'dest_lng': 121.1285,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal', 'destination': 'Mamatid',
        'fare': 20.00, 'via': 'Sala → Mamatid Road',
        'origin_lat': 14.2404, 'origin_lng': 121.1088, 'dest_lat': 14.2659, 'dest_lng': 121.1095,
      },
    ]) { await db.insert('routes', r); }

    // Tricycle — Mamatid Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal', 'destination': 'Mamatid PNR Station',
        'fare': 15.00, 'via': 'Mamatid Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2670, 'dest_lng': 121.1360,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal', 'destination': 'San Vicente Ferrer Shrine',
        'fare': 15.00, 'via': 'Mamatid Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2680, 'dest_lng': 121.1350,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal', 'destination': 'Goldilocks Plant (Mamatid)',
        'fare': 15.00, 'via': 'Mamatid Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2645, 'dest_lng': 121.1390,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal', 'destination': 'Pittland / LISP I Gate',
        'fare': 17.00, 'via': 'Mamatid → Pittland Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2429, 'dest_lng': 121.1469,
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal', 'destination': 'National Highway (AH-26) Drop-off',
        'fare': 20.00, 'via': 'Mamatid Road → National Highway',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2638, 'dest_lng': 121.1305,
      },
    ]) { await db.insert('routes', r); }

    // E-Tricycle
    for (final r in [
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Pulo Diezmo Road E-Tricycle Terminal', 'destination': 'Mapúa Malayan Colleges Laguna',
        'fare': 15.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2427, 'dest_lng': 121.1126,
      },
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Pulo Diezmo Road E-Tricycle Terminal', 'destination': 'Gate 2 (LISP / Industrial)',
        'fare': 15.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2405, 'dest_lng': 121.1555,
      },
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Pulo Diezmo Road E-Tricycle Terminal', 'destination': 'Cabuyao Coliseum',
        'fare': 13.00, 'via': 'Pulo Diezmo Road',
        'origin_lat': 14.2452, 'origin_lng': 121.1279, 'dest_lat': 14.2452, 'dest_lng': 121.1340,
      },
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Poblacion E-Tricycle Terminal', 'destination': 'Banaybanay',
        'fare': 15.00, 'via': 'Poblacion → Banaybanay Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2820, 'dest_lng': 121.1185,
      },
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Poblacion E-Tricycle Terminal', 'destination': 'Banlic',
        'fare': 15.00, 'via': 'Poblacion → Banlic Road',
        'origin_lat': 14.2775, 'origin_lng': 121.1243, 'dest_lat': 14.2750, 'dest_lng': 121.1200,
      },
      {
        'transport_type': 'E-Tricycle',
        'origin': 'Mamatid E-Tricycle Terminal', 'destination': 'Pittland / LISP I Gate',
        'fare': 15.00, 'via': 'Mamatid → Pittland Road',
        'origin_lat': 14.2659, 'origin_lng': 121.1378, 'dest_lat': 14.2429, 'dest_lng': 121.1469,
      },
    ]) { await db.insert('routes', r); }

    // ── TERMINALS ─────────────────────────────────────────────────────────────
    for (final t in [
      {
        'category': 'JEEPNEY TERMINAL',
        'name':     'Cabuyao City Hall Terminal (Poblacion)',
        'description': 'Main jeepney terminal along the National Highway near Cabuyao City Hall. Hub for northbound (Sta. Rosa) and southbound (Calamba) jeepneys.',
        'emoji': '🚙',
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name':     'Mamatid Terminal',
        'description': 'Jeepney terminal in Barangay Mamatid. Serves routes to Poblacion, Alabang via SLEX, and Balibago. Near the PNR Mamatid Station.',
        'emoji': '🚙',
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name':     'Bigaa Junction Terminal',
        'description': 'Terminal at Bigaa junction along AH-26. Jeepneys pass here going to Calamba or Sta. Rosa.',
        'emoji': '🚙',
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name':     'Pulo Diezmo Road Tricycle Terminal',
        'description': 'Located at the junction of AH-26 and Pulo-Diezmo Road. Serves Diezmo, Ilaya, LISP industrial gates, Mapúa MCL, and nearby subdivisions.',
        'emoji': '🛺',
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name':     'Poblacion Tricycle Terminal (City Hall)',
        'description': 'Near Cabuyao City Hall. Serves the three Poblacion barangays and inner barangays like Banlic, Banaybanay, Gulod, and Casile.',
        'emoji': '🛺',
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name':     'Bigaa Tricycle Terminal',
        'description': 'At the entrance of Brgy. Bigaa off AH-26. Serves the Bigaa lakeshore area, Butong, and Marinig.',
        'emoji': '🛺',
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name':     'Sala Tricycle Terminal',
        'description': 'Along AH-26 near Brgy. Sala. Serves Sala interior, Asia Brewery / Tanduay area, Niugan, and the Laguna de Bay lakeshore.',
        'emoji': '🛺',
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name':     'Mamatid Tricycle Terminal',
        'description': 'In Brgy. Mamatid near San Vicente Ferrer Shrine. Serves Mamatid interior, Pittland / LISP I gates, and the PNR station.',
        'emoji': '🛺',
      },
      {
        'category': 'E-TRICYCLE TERMINAL',
        'name':     'Pulo Diezmo Road E-Tricycle Terminal',
        'description': 'Electric tricycle terminal at the AH-26 and Pulo-Diezmo Road junction. Eco-friendly option serving LISP gates, MCL, and the Diezmo corridor.',
        'emoji': '🛵',
      },
      {
        'category': 'E-TRICYCLE TERMINAL',
        'name':     'Poblacion E-Tricycle Terminal',
        'description': 'E-tricycle terminal near City Hall serving the Poblacion area and nearby barangays like Banlic and Banaybanay.',
        'emoji': '🛵',
      },
      {
        'category': 'E-TRICYCLE TERMINAL',
        'name':     'Mamatid E-Tricycle Terminal',
        'description': 'Electric tricycle terminal in Mamatid serving Pittland / LISP I Gate and the immediate Mamatid area.',
        'emoji': '🛵',
      },
      {
        'category': 'BUS TERMINAL',
        'name':     'Balibago Complex Terminal (Sta. Rosa)',
        'description': 'Major inter-city transport hub in neighboring Sta. Rosa. Accessible from Cabuyao via jeepney along AH-26. Hub for buses to Manila and UV Express to Tagaytay.',
        'emoji': '🚍',
      },
      {
        'category': 'BUS TERMINAL',
        'name':     'Calamba Grand Terminal',
        'description': 'Main bus terminal for Calamba City south of Cabuyao. Serves long-distance buses to Batangas, Quezon, Bicol, and local jeepneys.',
        'emoji': '🚍',
      },
      {
        'category': 'TRAIN STATION',
        'name':     'Cabuyao PNR Station',
        'description': 'Philippine National Railways station in Cabuyao along the Calamba–Manila south line. Currently suspended pending rehabilitation.',
        'emoji': '🚆',
      },
      {
        'category': 'TRAIN STATION',
        'name':     'Mamatid PNR Station',
        'description': 'Philippine National Railways station in Barangay Mamatid. On the south line toward Manila. Currently suspended pending rehabilitation.',
        'emoji': '🚆',
      },
      {
        'category': 'LANDMARK',
        'name':     'Mapúa Malayan Colleges Laguna (MCL)',
        'description': 'University campus in Cabuyao. Reachable via tricycle from Pulo Diezmo Road Terminal (₱17) or jeepney along AH-26.',
        'emoji': '🏫',
      },
      {
        'category': 'LANDMARK',
        'name':     'LISP I (Light Industry and Science Park)',
        'description': 'Major industrial park in Cabuyao hosting Nestlé, P&G, URC, Samsung, and others. Multiple gates accessible by tricycle from Pulo Diezmo and Mamatid terminals.',
        'emoji': '🏭',
      },
      {
        'category': 'LANDMARK',
        'name':     'Cabuyao Coliseum',
        'description': 'Sports and events venue in Cabuyao. Reachable via tricycle from Pulo Diezmo Road Terminal (₱15).',
        'emoji': '🏟️',
      },
      {
        'category': 'LANDMARK',
        'name':     'Nestlé Philippines Plant (Niugan)',
        'description': 'Nestlé manufacturing facility along AH-26 in Brgy. Niugan. Accessible by jeepney drop-off or tricycle from Sala terminal.',
        'emoji': '🏭',
      },
      {
        'category': 'LANDMARK',
        'name':     'San Vicente Ferrer Diocesan Shrine (Mamatid)',
        'description': 'Popular Catholic shrine in Brgy. Mamatid. Reachable via tricycle from Mamatid Terminal (₱15).',
        'emoji': '⛪',
      },
    ]) {
      await db.insert('terminals', t);
    }

    // ── ZONES ─────────────────────────────────────────────────────────────────
    for (final z in [
      {
        'name':       'Zone 1 – National Highway Corridor (AH-26)',
        'color_hex':  'FF3B6FE0',
        'stop_count': 14,
      },
      {
        'name':       'Zone 2 – Poblacion / City Center',
        'color_hex':  'FF43A047',
        'stop_count': 8,
      },
      {
        'name':       'Zone 3 – Lakeshore Barangays (Laguna de Bay)',
        'color_hex':  'FF00ACC1',
        'stop_count': 6,
      },
      {
        'name':       'Zone 4 – Industrial / LISP Area',
        'color_hex':  'FFFFC200',
        'stop_count': 10,
      },
      {
        'name':       'Zone 5 – Upland / Interior Barangays',
        'color_hex':  'FF8E24AA',
        'stop_count': 7,
      },
      {
        'name':       'Zone 6 – Mamatid / Pittland Corridor',
        'color_hex':  'FFE53935',
        'stop_count': 9,
      },
    ]) {
      await db.insert('zones', z);
    }
  }

  // ── Generic CRUD helpers ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table, orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    final db   = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
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
    return db.query(
      table,
      where: '$column LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'id ASC',
    );
  }

  Future<int> count(String table) async {
    final db    = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
    return result.first['c'] as int? ?? 0;
  }

  Future<String?> getSetting(String key) async {
    final db   = await database;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: sq.ConflictAlgorithm.replace);
  }
}
