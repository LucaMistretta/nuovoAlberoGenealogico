import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella eventi
class EventoDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'eventi';

  /// Ottiene tutti gli eventi di una persona
  Future<List<Map<String, dynamic>>> getEventiByPersonaId(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ?',
      whereArgs: [personaId],
      orderBy: 'data_evento DESC',
    );
  }

  /// Ottiene gli eventi per tipo
  Future<List<Map<String, dynamic>>> getEventiByTipo(
    int personaId,
    String tipoEvento,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ? AND tipo_evento = ?',
      whereArgs: [personaId, tipoEvento],
      orderBy: 'data_evento DESC',
    );
  }

  /// Ottiene un evento per ID
  Future<Map<String, dynamic>?> getEventoById(int id) async {
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

