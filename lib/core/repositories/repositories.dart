import 'package:para_po/core/database/database_helper.dart';
import 'package:para_po/core/models/models.dart';

class TransportRepository {
  final _db = DatabaseHelper.instance;
  Future<List<TransportModel>> getAll() async =>
    (await _db.queryAll('transportation')).map(TransportModel.fromMap).toList();
  Future<List<TransportModel>> search(String q) async =>
    (await _db.search('transportation', 'name', q)).map(TransportModel.fromMap).toList();
  Future<int> add(TransportModel item) => _db.insert('transportation', item.toMap());
  Future<int> update(TransportModel item) => _db.update('transportation', item.toMap());
  Future<int> delete(int id) => _db.delete('transportation', id);
}

class RouteRepository {
  final _db = DatabaseHelper.instance;
  Future<List<RouteModel>> getAll() async =>
    (await _db.queryAll('routes')).map(RouteModel.fromMap).toList();
  Future<List<RouteModel>> search(String q) async {
    final db = await _db.database;
    final rows = await db.query('routes',
      where: 'origin LIKE ? OR destination LIKE ?',
      whereArgs: ['%$q%', '%$q%'], orderBy: 'id ASC');
    return rows.map(RouteModel.fromMap).toList();
  }
  Future<int> add(RouteModel item) => _db.insert('routes', item.toMap());
  Future<int> update(RouteModel item) => _db.update('routes', item.toMap());
  Future<int> delete(int id) => _db.delete('routes', id);
}

class TerminalRepository {
  final _db = DatabaseHelper.instance;
  Future<List<TerminalModel>> getAll() async =>
    (await _db.queryAll('terminals')).map(TerminalModel.fromMap).toList();
  Future<List<TerminalModel>> search(String q) async =>
    (await _db.search('terminals', 'name', q)).map(TerminalModel.fromMap).toList();
  Future<int> add(TerminalModel item) => _db.insert('terminals', item.toMap());
  Future<int> update(TerminalModel item) => _db.update('terminals', item.toMap());
  Future<int> delete(int id) => _db.delete('terminals', id);
}

class ZoneRepository {
  final _db = DatabaseHelper.instance;
  Future<List<ZoneModel>> getAll() async =>
    (await _db.queryAll('zones')).map(ZoneModel.fromMap).toList();
  Future<int> add(ZoneModel item) => _db.insert('zones', item.toMap());
  Future<int> update(ZoneModel item) => _db.update('zones', item.toMap());
  Future<int> delete(int id) => _db.delete('zones', id);
}
