import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

/// Data Access Object per la tabella persone
class PersonaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'persone';

  /// Ottiene tutte le persone
  Future<List<Map<String, dynamic>>> getAllPersone() async {
    final db = await _dbHelper.database;
    return await db.query(
      _tableName,
      orderBy: 'cognome ASC, nome ASC',
    );
  }

  /// Ottiene una persona per ID
  Future<Map<String, dynamic>?> getPersonaById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Cerca persone per nome o cognome
  Future<List<Map<String, dynamic>>> searchPersone(String query) async {
    final db = await _dbHelper.database;
    final searchTerm = '%$query%';
    return await db.query(
      _tableName,
      where: 'nome LIKE ? OR cognome LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      orderBy: 'cognome ASC, nome ASC',
    );
  }

  /// Ottiene le persone con filtri opzionali
  Future<List<Map<String, dynamic>>> getPersoneWithFilters({
    String? nome,
    String? cognome,
    DateTime? natoDa,
    DateTime? natoA,
    DateTime? decedutoDa,
    DateTime? decedutoA,
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (nome != null && nome.isNotEmpty) {
      where.add('nome LIKE ?');
      whereArgs.add('%$nome%');
    }

    if (cognome != null && cognome.isNotEmpty) {
      where.add('cognome LIKE ?');
      whereArgs.add('%$cognome%');
    }

    if (natoDa != null) {
      where.add('nato_il >= ?');
      whereArgs.add(natoDa.toIso8601String().split('T')[0]);
    }

    if (natoA != null) {
      where.add('nato_il <= ?');
      whereArgs.add(natoA.toIso8601String().split('T')[0]);
    }

    if (decedutoDa != null) {
      where.add('deceduto_il >= ?');
      whereArgs.add(decedutoDa.toIso8601String().split('T')[0]);
    }

    if (decedutoA != null) {
      where.add('deceduto_il <= ?');
      whereArgs.add(decedutoA.toIso8601String().split('T')[0]);
    }

    return await db.query(
      _tableName,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'cognome ASC, nome ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// Conta il numero totale di persone
  Future<int> countPersone() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Aggiorna una persona
  Future<bool> updatePersona(int id, Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      final rowsAffected = await db.update(
        _tableName,
        {
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return rowsAffected > 0;
    } catch (e) {
      return false;
    }
  }

  /// Crea una nuova persona
  Future<int?> insertPersona(Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      final id = await db.insert(
        _tableName,
        {
          ...data,
          'created_at': now,
          'updated_at': now,
        },
      );
      return id;
    } catch (e) {
      return null;
    }
  }
}
