import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella tags
class TagDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'tags';
  static const String _personaTagsTableName = 'persona_tags';

  /// Ottiene tutti i tag
  Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      orderBy: 'nome ASC',
    );
  }

  /// Ottiene i tag di una persona
  Future<List<Map<String, dynamic>>> getTagsByPersonaId(int personaId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT t.* FROM $_tableName t
      INNER JOIN $_personaTagsTableName pt ON t.id = pt.tag_id
      WHERE pt.persona_id = ?
      ORDER BY t.nome ASC
    ''', [personaId]);
  }

  /// Ottiene un tag per ID
  Future<Map<String, dynamic>?> getTagById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Crea un nuovo tag
  Future<int> insertTag({
    required String nome,
    String? colore,
    String? descrizione,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert(
      _tableName,
      {
        'nome': nome,
        'colore': colore ?? '#3b82f6',
        'descrizione': descrizione,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Aggiorna un tag esistente
  Future<int> updateTag({
    required int id,
    String? nome,
    String? colore,
    String? descrizione,
  }) async {
    final db = await _dbHelper.database;
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (nome != null) data['nome'] = nome;
    if (colore != null) data['colore'] = colore;
    if (descrizione != null) data['descrizione'] = descrizione;
    
    return await db.update(
      _tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un tag
  Future<int> deleteTag(int id) async {
    final db = await _dbHelper.database;
    // Elimina prima le associazioni con le persone
    await db.delete(
      _personaTagsTableName,
      where: 'tag_id = ?',
      whereArgs: [id],
    );
    // Poi elimina il tag
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Associa un tag a una persona
  Future<void> attachToPersona(int personaId, int tagId) async {
    final db = await _dbHelper.database;
    await db.insert(
      _personaTagsTableName,
      {
        'persona_id': personaId,
        'tag_id': tagId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Rimuove l'associazione tra un tag e una persona
  Future<int> detachFromPersona(int personaId, int tagId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _personaTagsTableName,
      where: 'persona_id = ? AND tag_id = ?',
      whereArgs: [personaId, tagId],
    );
  }
}

