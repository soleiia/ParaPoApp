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
    final path = join(dbPath, 'para_po_v4.db');
    return await sq.openDatabase(
      path,
      version: 4,
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
        via            TEXT    NOT NULL DEFAULT ''
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

    // ── ROUTES ────────────────────────────────────────────────────────────────

    // Jeepney (Traditional) — National Highway / AH-26
    for (final r in [
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Bigaa Junction',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Marinig',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Niugan / Nestlé Gate',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Pittland / LISP I',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Pulo / Diezmo Road Junction',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Sala / Asia Brewery',
        'fare': 15.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Calamba City Hall',
        'fare': 18.00,
        'via': 'National Highway (AH-26) southbound',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'SM City Calamba',
        'fare': 20.00,
        'via': 'National Highway (AH-26) southbound',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 18.00,
        'via': 'National Highway (AH-26) northbound',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Cabuyao City Hall (Poblacion)',
        'destination': 'SM City Sta. Rosa',
        'fare': 20.00,
        'via': 'National Highway (AH-26) northbound',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Biñan City Hall',
        'fare': 20.00,
        'via': 'National Highway northbound',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Mamatid Terminal',
        'destination': 'Cabuyao City Hall (Poblacion)',
        'fare': 15.00,
        'via': 'Mamatid Road',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Mamatid Terminal',
        'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 25.00,
        'via': 'SLEX / Mamplasan Exit',
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin':      'Mamatid Terminal',
        'destination': 'Alabang (Muntinlupa)',
        'fare': 50.00,
        'via': 'SLEX / Alabang Exit',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Jeepney (Modern)
    for (final r in [
      {
        'transport_type': 'Jeepney (Modern)',
        'origin':      'Cabuyao Terminal (Poblacion)',
        'destination': 'SM City Calamba',
        'fare': 17.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Modern)',
        'origin':      'Cabuyao Terminal (Poblacion)',
        'destination': 'Balibago Complex (Sta. Rosa)',
        'fare': 17.00,
        'via': 'National Highway (AH-26)',
      },
      {
        'transport_type': 'Jeepney (Modern)',
        'origin':      'Pacita Terminal (San Pedro)',
        'destination': 'SM City Calamba',
        'fare': 35.00,
        'via': 'National Highway via Cabuyao',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Tricycle — Pulo Diezmo Road Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Anywhere on AH-26 (drop-off)',
        'fare': 13.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Cabuyao Coliseum',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'San Carlos Village',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Villa Adelina Subdivision',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Unilever / JJ',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Lazada Warehouse',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Mapúa Malayan Colleges Laguna',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ninja Van Sta. Elena',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 1 (LISP / Industrial)',
        'fare': 19.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 2 (LISP / Industrial)',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 3 (LISP / Industrial)',
        'fare': 19.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ilaya (Diezmo Interior)',
        'fare': 22.00,
        'via': 'Pulo Diezmo Road → Ilaya',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Diezmo Proper',
        'fare': 25.00,
        'via': 'Pulo Diezmo Road',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Tricycle — Poblacion / City Hall Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Uno (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Dos (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Tres (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Banaybanay',
        'fare': 17.00,
        'via': 'Poblacion → Banaybanay Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Banlic',
        'fare': 17.00,
        'via': 'Poblacion → Banlic Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Gulod',
        'fare': 20.00,
        'via': 'Poblacion → Gulod Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Casile',
        'fare': 20.00,
        'via': 'Poblacion → Casile Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'San Isidro',
        'fare': 17.00,
        'via': 'Poblacion → San Isidro Road',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Tricycle — Bigaa Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin':      'Bigaa Tricycle Terminal',
        'destination': 'Bigaa Lakeshore (Laguna de Bay)',
        'fare': 15.00,
        'via': 'Bigaa Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Bigaa Tricycle Terminal',
        'destination': 'Bigaa Elementary School',
        'fare': 15.00,
        'via': 'Bigaa Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Bigaa Tricycle Terminal',
        'destination': 'Butong',
        'fare': 17.00,
        'via': 'Bigaa → Butong Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Bigaa Tricycle Terminal',
        'destination': 'Marinig',
        'fare': 17.00,
        'via': 'Bigaa → Marinig Road',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Tricycle — Sala Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin':      'Sala Tricycle Terminal',
        'destination': 'Asia Brewery / Tanduay',
        'fare': 15.00,
        'via': 'Sala Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Sala Tricycle Terminal',
        'destination': 'Sala Lakeshore (Laguna de Bay)',
        'fare': 17.00,
        'via': 'Sala Road → Lakeshore',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Sala Tricycle Terminal',
        'destination': 'Niugan (Nestlé Philippines)',
        'fare': 17.00,
        'via': 'Sala → Niugan Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Sala Tricycle Terminal',
        'destination': 'Mamatid',
        'fare': 20.00,
        'via': 'Sala → Mamatid Road',
      },
    ]) {
      await db.insert('routes', r);
    }

    // Tricycle — Mamatid Terminal
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin':      'Mamatid Tricycle Terminal',
        'destination': 'Mamatid PNR Station',
        'fare': 15.00,
        'via': 'Mamatid Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Mamatid Tricycle Terminal',
        'destination': 'San Vicente Ferrer Shrine',
        'fare': 15.00,
        'via': 'Mamatid Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Mamatid Tricycle Terminal',
        'destination': 'Goldilocks Plant (Mamatid)',
        'fare': 15.00,
        'via': 'Mamatid Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Mamatid Tricycle Terminal',
        'destination': 'Pittland / LISP I Gate',
        'fare': 17.00,
        'via': 'Mamatid → Pittland Road',
      },
      {
        'transport_type': 'Tricycle',
        'origin':      'Mamatid Tricycle Terminal',
        'destination': 'National Highway (AH-26) Drop-off',
        'fare': 20.00,
        'via': 'Mamatid Road → National Highway',
      },
    ]) {
      await db.insert('routes', r);
    }

    // E-Tricycle — same corridors as Tricycle, slightly cheaper electric fare
    for (final r in [
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Pulo Diezmo Road E-Tricycle Terminal',
        'destination': 'Mapúa Malayan Colleges Laguna',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Pulo Diezmo Road E-Tricycle Terminal',
        'destination': 'Gate 2 (LISP / Industrial)',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Pulo Diezmo Road E-Tricycle Terminal',
        'destination': 'Cabuyao Coliseum',
        'fare': 13.00,
        'via': 'Pulo Diezmo Road',
      },
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Poblacion E-Tricycle Terminal',
        'destination': 'Banaybanay',
        'fare': 15.00,
        'via': 'Poblacion → Banaybanay Road',
      },
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Poblacion E-Tricycle Terminal',
        'destination': 'Banlic',
        'fare': 15.00,
        'via': 'Poblacion → Banlic Road',
      },
      {
        'transport_type': 'E-Tricycle',
        'origin':      'Mamatid E-Tricycle Terminal',
        'destination': 'Pittland / LISP I Gate',
        'fare': 15.00,
        'via': 'Mamatid → Pittland Road',
      },
    ]) {
      await db.insert('routes', r);
    }

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
