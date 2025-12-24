import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/tipo_legame_model.dart';

/// Data Access Object per la tabella tipi_di_legame
class TipoLegameDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'tipi_di_legame';

  /// Ottiene tutti i tipi di legame
  Future<List<TipoLegameModel>> getAllTipiLegame() async {
    final db = await _dbHelper.database;
    final results = await db.query(_tableName, orderBy: 'nome ASC');
    return results.map((map) => TipoLegameModel.fromMap(map)).toList();
  }

  /// Ottiene un tipo di legame per ID
  Future<TipoLegameModel?> getTipoLegameById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? TipoLegameModel.fromMap(results.first) : null;
  }

  /// Ottiene un tipo di legame per nome
  Future<TipoLegameModel?> getTipoLegameByNome(String nome) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'nome = ?',
      whereArgs: [nome],
      limit: 1,
    );
    return results.isNotEmpty ? TipoLegameModel.fromMap(results.first) : null;
  }
}

