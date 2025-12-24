import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella media
class MediaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'media';

  /// Ottiene tutti i media di una persona
  Future<List<Map<String, dynamic>>> getMediaByPersonaId(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ?',
      whereArgs: [personaId],
      orderBy: 'data_caricamento DESC',
    );
  }

  /// Ottiene i media per tipo
  Future<List<Map<String, dynamic>>> getMediaByTipo(
    int personaId,
    String tipo,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ? AND tipo = ?',
      whereArgs: [personaId, tipo],
      orderBy: 'data_caricamento DESC',
    );
  }

  /// Ottiene un media per ID
  Future<Map<String, dynamic>?> getMediaById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
}

