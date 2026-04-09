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
        transport_type TEXT NOT NULL DEFAULT 'Jeepney',
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        fare REAL NOT NULL DEFAULT 0,
        via TEXT NOT NULL DEFAULT ''
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
    // ── TRANSPORTATION TYPES ──────────────────────────────────────────────────
    for (final t in [
      {
        'name': 'Jeepney (Traditional)',
        'fare': 14.00,
        'active': 1,
        'emoji': '🚙'
      },
      {
        'name': 'Jeepney (Modern/E-Jeep)',
        'fare': 17.00,
        'active': 1,
        'emoji': '🚌'
      },
      {'name': 'Tricycle', 'fare': 17.00, 'active': 1, 'emoji': '🛺'},
      {'name': 'UV Express / Van', 'fare': 50.00, 'active': 1, 'emoji': '🚐'},
      {'name': 'Bus (Ordinary)', 'fare': 35.00, 'active': 1, 'emoji': '🚍'},
      {'name': 'Bus (Aircon)', 'fare': 55.00, 'active': 1, 'emoji': '🚌'},
      {'name': 'PNR Train', 'fare': 30.00, 'active': 0, 'emoji': '🚆'},
    ]) {
      await db.insert('transportation', t);
    }

    // ── ROUTES ────────────────────────────────────────────────────────────────
    // NOTE: routes table now has a transport_type and via column added above.
    // Traditional Jeepney minimum fare is ₱14 per LTFRB March 2026 order.
    // Modern/E-Jeep minimum is ₱17.

    // --- Jeepney: Along AH-26 / National Highway (within Cabuyao) ---
    for (final r in [
      // AH-26 local hops
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Bigaa Junction',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Marinig',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Niugan / Nestlé Gate',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Pittland / LISP I',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Pulo / Diezmo Road Junction',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Sala / Asia Brewery',
        'fare': 14.00,
        'via': 'National Highway (AH-26)'
      },
      // Cabuyao ↔ Calamba
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Calamba City Hall',
        'fare': 18.00,
        'via': 'National Highway (AH-26) southbound'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'SM City Calamba',
        'fare': 20.00,
        'via': 'National Highway (AH-26) southbound'
      },
      // Cabuyao ↔ Sta. Rosa / Balibago
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 18.00,
        'via': 'National Highway (AH-26) northbound'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Cabuyao City Hall (Poblacion)',
        'destination': 'SM City Sta. Rosa',
        'fare': 20.00,
        'via': 'National Highway (AH-26) northbound'
      },
      // Cabuyao ↔ Biñan
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Biñan City Hall',
        'fare': 20.00,
        'via': 'National Highway northbound'
      },
      // Mamatid routes
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal',
        'destination': 'Cabuyao City Hall (Poblacion)',
        'fare': 14.00,
        'via': 'Mamatid Road'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal',
        'destination': 'Balibago Complex Terminal (Sta. Rosa)',
        'fare': 25.00,
        'via': 'SLEX / Mamplasan Exit'
      },
      {
        'transport_type': 'Jeepney (Traditional)',
        'origin': 'Mamatid Terminal',
        'destination': 'Alabang (Muntinlupa)',
        'fare': 50.00,
        'via': 'SLEX / Alabang Exit'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Modern / E-Jeepney Routes ---
    for (final r in [
      {
        'transport_type': 'Jeepney (Modern/E-Jeep)',
        'origin': 'Cabuyao Terminal (Poblacion)',
        'destination': 'SM City Calamba',
        'fare': 17.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Modern/E-Jeep)',
        'origin': 'Cabuyao Terminal (Poblacion)',
        'destination': 'Balibago Complex (Sta. Rosa)',
        'fare': 17.00,
        'via': 'National Highway (AH-26)'
      },
      {
        'transport_type': 'Jeepney (Modern/E-Jeep)',
        'origin': 'Pacita Terminal (San Pedro)',
        'destination': 'SM City Calamba',
        'fare': 35.00,
        'via': 'National Highway via Cabuyao'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Tricycle: Pulo-Diezmo Road Terminal ---
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Anywhere on AH-26 (drop-off)',
        'fare': 13.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Cabuyao Coliseum',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'San Carlos Village',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Villa Adelina Subdivision',
        'fare': 15.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Unilever / JJ',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Lazada Warehouse',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Mapúa Malayan Colleges Laguna',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ninja Van Sta. Elena',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 1 (LISP / Industrial)',
        'fare': 19.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 2 (LISP / Industrial)',
        'fare': 17.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Gate 3 (LISP / Industrial)',
        'fare': 19.00,
        'via': 'Pulo Diezmo Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Ilaya (Diezmo Interior)',
        'fare': 22.00,
        'via': 'Pulo Diezmo Road → Ilaya'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Pulo Diezmo Road Tricycle Terminal',
        'destination': 'Diezmo Proper',
        'fare': 25.00,
        'via': 'Pulo Diezmo Road'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Tricycle: Poblacion / City Hall Area ---
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Uno (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Dos (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Barangay Tres (Pob.)',
        'fare': 15.00,
        'via': 'Poblacion streets'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Banaybanay',
        'fare': 17.00,
        'via': 'Poblacion → Banaybanay Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Banlic',
        'fare': 17.00,
        'via': 'Poblacion → Banlic Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Gulod',
        'fare': 20.00,
        'via': 'Poblacion → Gulod Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'Casile',
        'fare': 20.00,
        'via': 'Poblacion → Casile Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Poblacion Tricycle Terminal (City Hall)',
        'destination': 'San Isidro',
        'fare': 17.00,
        'via': 'Poblacion → San Isidro Road'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Tricycle: Bigaa Terminal ---
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal',
        'destination': 'Bigaa Lakeshore (Laguna de Bay)',
        'fare': 15.00,
        'via': 'Bigaa Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal',
        'destination': 'Bigaa Elementary School',
        'fare': 15.00,
        'via': 'Bigaa Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal',
        'destination': 'Butong',
        'fare': 17.00,
        'via': 'Bigaa → Butong Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Bigaa Tricycle Terminal',
        'destination': 'Marinig',
        'fare': 17.00,
        'via': 'Bigaa → Marinig Road'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Tricycle: Sala Terminal ---
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal',
        'destination': 'Asia Brewery / Tanduay',
        'fare': 15.00,
        'via': 'Sala Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal',
        'destination': 'Sala Lakeshore (Laguna de Bay)',
        'fare': 17.00,
        'via': 'Sala Road → Lakeshore'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal',
        'destination': 'Niugan (Nestlé Philippines)',
        'fare': 17.00,
        'via': 'Sala → Niugan Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Sala Tricycle Terminal',
        'destination': 'Mamatid',
        'fare': 20.00,
        'via': 'Sala → Mamatid Road'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Tricycle: Mamatid Terminal ---
    for (final r in [
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal',
        'destination': 'Mamatid PNR Station',
        'fare': 15.00,
        'via': 'Mamatid Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal',
        'destination': 'San Vicente Ferrer Shrine',
        'fare': 15.00,
        'via': 'Mamatid Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal',
        'destination': 'Goldilocks Plant (Mamatid)',
        'fare': 15.00,
        'via': 'Mamatid Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal',
        'destination': 'Pittland / LISP I Gate',
        'fare': 17.00,
        'via': 'Mamatid → Pittland Road'
      },
      {
        'transport_type': 'Tricycle',
        'origin': 'Mamatid Tricycle Terminal',
        'destination': 'National Highway (AH-26) Drop-off',
        'fare': 20.00,
        'via': 'Mamatid Road → National Highway'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- UV Express / Van Routes ---
    for (final r in [
      {
        'transport_type': 'UV Express / Van',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Alabang (Muntinlupa)',
        'fare': 50.00,
        'via': 'SLEX / Expressway'
      },
      {
        'transport_type': 'UV Express / Van',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Nuvali (Sta. Rosa)',
        'fare': 20.00,
        'via': 'Sta. Rosa – Tagaytay Road'
      },
      {
        'transport_type': 'UV Express / Van',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Tagaytay City',
        'fare': 45.00,
        'via': 'Sta. Rosa – Tagaytay Road'
      },
      {
        'transport_type': 'UV Express / Van',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'Pacita Complex (San Pedro)',
        'fare': 25.00,
        'via': 'National Highway northbound'
      },
      {
        'transport_type': 'UV Express / Van',
        'origin': 'Balibago Complex Terminal (Sta. Rosa)',
        'destination': 'SM City Calamba',
        'fare': 35.00,
        'via': 'National Highway southbound'
      },
    ]) {
      await db.insert('routes', r);
    }

    // --- Bus Routes (passing through or originating in Cabuyao) ---
    for (final r in [
      {
        'transport_type': 'Bus (Ordinary)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Alabang / Starmall (Muntinlupa)',
        'fare': 50.00,
        'via': 'SLEX northbound'
      },
      {
        'transport_type': 'Bus (Aircon)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Alabang / Starmall (Muntinlupa)',
        'fare': 80.00,
        'via': 'SLEX northbound'
      },
      {
        'transport_type': 'Bus (Ordinary)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Cubao / Buendia (Manila)',
        'fare': 120.00,
        'via': 'SLEX → EDSA northbound'
      },
      {
        'transport_type': 'Bus (Aircon)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Cubao / Buendia (Manila)',
        'fare': 160.00,
        'via': 'SLEX → EDSA northbound'
      },
      {
        'transport_type': 'Bus (Ordinary)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Calamba (Grand Terminal)',
        'fare': 35.00,
        'via': 'National Highway / SLEX southbound'
      },
      {
        'transport_type': 'Bus (Aircon)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Calamba (Grand Terminal)',
        'fare': 55.00,
        'via': 'National Highway / SLEX southbound'
      },
      {
        'transport_type': 'Bus (Ordinary)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Los Baños',
        'fare': 60.00,
        'via': 'National Highway southbound'
      },
      {
        'transport_type': 'Bus (Ordinary)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'San Pablo City',
        'fare': 120.00,
        'via': 'National Highway southbound'
      },
      {
        'transport_type': 'Bus (Aircon)',
        'origin': 'Cabuyao (National Highway)',
        'destination': 'Batangas City / Grand Terminal',
        'fare': 200.00,
        'via': 'SLEX → STAR Tollway southbound'
      },
    ]) {
      await db.insert('routes', r);
    }

    // ── TERMINALS ─────────────────────────────────────────────────────────────
    for (final t in [
      // Jeepney / Main Terminals
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Cabuyao City Hall Terminal (Poblacion)',
        'description':
            'Main jeepney terminal along the National Highway near Cabuyao City Hall. Hub for northbound (Sta. Rosa) and southbound (Calamba) jeepneys.',
        'emoji': '🚙'
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Mamatid Terminal',
        'description':
            'Jeepney terminal in Barangay Mamatid. Serves routes to Poblacion, Alabang via SLEX, and Balibago. Near the PNR Mamatid Station.',
        'emoji': '🚙'
      },
      {
        'category': 'JEEPNEY TERMINAL',
        'name': 'Bigaa Junction Terminal',
        'description':
            'Terminal at Bigaa junction along AH-26. Jeepneys pass here going to Calamba or Sta. Rosa.',
        'emoji': '🚙'
      },
      // Tricycle Terminals
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Pulo Diezmo Road Tricycle Terminal',
        'description':
            'Located at the junction of AH-26 and Pulo-Diezmo Road. Serves Diezmo, Ilaya, LISP industrial gates, Mapúa MCL, and nearby subdivisions.',
        'emoji': '🛺'
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Poblacion Tricycle Terminal (City Hall)',
        'description':
            'Near Cabuyao City Hall. Serves the three Poblacion barangays and inner barangays like Banlic, Banaybanay, Gulod, and Casile.',
        'emoji': '🛺'
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Bigaa Tricycle Terminal',
        'description':
            'At the entrance of Brgy. Bigaa off AH-26. Serves the Bigaa lakeshore area, Butong, and Marinig.',
        'emoji': '🛺'
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Sala Tricycle Terminal',
        'description':
            'Along AH-26 near Brgy. Sala. Serves Sala interior, Asia Brewery/Tanduay area, Niugan, and the Laguna de Bay lakeshore.',
        'emoji': '🛺'
      },
      {
        'category': 'TRICYCLE TERMINAL',
        'name': 'Mamatid Tricycle Terminal',
        'description':
            'In Brgy. Mamatid near San Vicente Ferrer Shrine. Serves Mamatid interior, Pittland/LISP I gates, and the PNR station.',
        'emoji': '🛺'
      },
      // Bus / UV Express Terminals
      {
        'category': 'BUS TERMINAL',
        'name': 'Balibago Complex Terminal (Sta. Rosa)',
        'description':
            'Major inter-city transport hub in neighboring Sta. Rosa. Accessible from Cabuyao via jeepney along AH-26. Hub for buses to Manila (Cubao/Buendia/Alabang), UV Express to Tagaytay/Nuvali, and jeeps to Biñan/Pacita/Calamba.',
        'emoji': '🚍'
      },
      {
        'category': 'BUS TERMINAL',
        'name': 'Calamba Grand Terminal',
        'description':
            'Main bus terminal for Calamba City, south of Cabuyao along AH-26. Serves long-distance buses to Batangas, Quezon, Bicol, and local jeepneys.',
        'emoji': '🚍'
      },
      // Train Stations
      {
        'category': 'TRAIN STATION',
        'name': 'Cabuyao PNR Station',
        'description':
            'Philippine National Railways station in Cabuyao along the Calamba–Manila south line. Currently suspended pending rehabilitation.',
        'emoji': '🚆'
      },
      {
        'category': 'TRAIN STATION',
        'name': 'Mamatid PNR Station',
        'description':
            'Philippine National Railways station in Barangay Mamatid. On the south line toward Manila. Currently suspended pending rehabilitation.',
        'emoji': '🚆'
      },
      // Key Landmarks / Drop-off Points
      {
        'category': 'LANDMARK',
        'name': 'Mapúa Malayan Colleges Laguna (MCL)',
        'description':
            'University campus in Cabuyao. Reachable via tricycle from Pulo Diezmo Road Terminal (₱17) or jeepney along AH-26.',
        'emoji': '🏫'
      },
      {
        'category': 'LANDMARK',
        'name': 'LISP I (Light Industry and Science Park)',
        'description':
            'Major industrial park in Cabuyao hosting Nestlé, P&G, URC, Samsung, and others. Multiple gates accessible by tricycle from Pulo Diezmo and Mamatid terminals.',
        'emoji': '🏭'
      },
      {
        'category': 'LANDMARK',
        'name': 'Cabuyao Coliseum',
        'description':
            'Sports and events venue in Cabuyao. Reachable via tricycle from Pulo Diezmo Road Terminal (₱15).',
        'emoji': '🏟️'
      },
      {
        'category': 'LANDMARK',
        'name': 'Nestlé Philippines Plant (Niugan)',
        'description':
            'Nestlé manufacturing facility along AH-26 in Brgy. Niugan. Accessible by jeepney (drop-off) or tricycle from Sala terminal.',
        'emoji': '🏭'
      },
      {
        'category': 'LANDMARK',
        'name': 'San Vicente Ferrer Diocesan Shrine (Mamatid)',
        'description':
            'Popular Catholic shrine in Brgy. Mamatid. Reachable via tricycle from Mamatid Terminal (₱15).',
        'emoji': '⛪'
      },
    ]) {
      await db.insert('terminals', t);
    }

    // ── ZONES ─────────────────────────────────────────────────────────────────
    for (final z in [
      {
        'name': 'Zone 1 – National Highway Corridor (AH-26)',
        'color_hex': 'FF3B6FE0',
        'stop_count': 14
      },
      {
        'name': 'Zone 2 – Poblacion / City Center',
        'color_hex': 'FF43A047',
        'stop_count': 8
      },
      {
        'name': 'Zone 3 – Lakeshore Barangays (Laguna de Bay)',
        'color_hex': 'FF00ACC1',
        'stop_count': 6
      },
      {
        'name': 'Zone 4 – Industrial / LISP Area',
        'color_hex': 'FFFFC200',
        'stop_count': 10
      },
      {
        'name': 'Zone 5 – Upland / Interior Barangays (Casile, Gulod, Diezmo)',
        'color_hex': 'FF8E24AA',
        'stop_count': 7
      },
      {
        'name': 'Zone 6 – Mamatid / Pittland Corridor',
        'color_hex': 'FFE53935',
        'stop_count': 9
      },
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
