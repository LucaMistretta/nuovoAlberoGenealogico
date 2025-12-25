import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella persona_legami
class PersonaLegameDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'persona_legami';

  /// Ottiene tutti i legami di una persona
  Future<List<Map<String, dynamic>>> getLegamiByPersonaId(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ? OR persona_collegata_id = ?',
      whereArgs: [personaId, personaId],
    );
  }

  /// Ottiene i legami dove la persona è principale
  Future<List<Map<String, dynamic>>> getLegamiAsPersona(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_id = ?',
      whereArgs: [personaId],
    );
  }

  /// Ottiene i legami dove la persona è collegata
  Future<List<Map<String, dynamic>>> getLegamiAsCollegata(int personaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: 'persona_collegata_id = ?',
      whereArgs: [personaId],
    );
  }

  /// Ottiene i legami per tipo
  Future<List<Map<String, dynamic>>> getLegamiByTipo(
    int personaId,
    int tipoLegameId,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      where: '(persona_id = ? OR persona_collegata_id = ?) AND tipo_legame_id = ?',
      whereArgs: [personaId, personaId, tipoLegameId],
    );
  }

  /// Ottiene tutti i legami
  Future<List<Map<String, dynamic>>> getAllLegami() async {
    final db = await _dbHelper.database;
    return await db.query(_tableName);
  }
}

