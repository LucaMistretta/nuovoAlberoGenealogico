import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella note
class NotaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'note';

  /// Ottiene tutte le note di una persona
  Future<List<Map<String, dynamic>>> getNoteByPersonaId(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ?',
      whereArgs: [personaId],
      orderBy: 'created_at DESC',
    );
  }

  /// Ottiene una nota per ID
  Future<Map<String, dynamic>?> getNotaById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Crea una nuova nota
  Future<int> insertNota({
    required int personaId,
    required String contenuto,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert(
      _tableName,
      {
        'persona_id': personaId,
        'contenuto': contenuto,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  /// Aggiorna una nota esistente
  Future<int> updateNota({
    required int id,
    required String contenuto,
  }) async {
    final db = await _dbHelper.database;
    return await db.update(
      _tableName,
      {
        'contenuto': contenuto,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una nota
  Future<int> deleteNota(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

