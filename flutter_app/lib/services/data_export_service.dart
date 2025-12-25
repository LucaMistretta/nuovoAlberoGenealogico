import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../data/local/persona_dao.dart';
import '../data/local/evento_dao.dart';
import '../data/local/media_dao.dart';
import '../data/local/nota_dao.dart';
import '../data/local/tag_dao.dart';
import '../data/local/persona_legame_dao.dart';

/// Servizio per esportare tutti i dati dal database SQLite in formato JSON
class DataExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PersonaDao _personaDao = PersonaDao();
  final EventoDao _eventoDao = EventoDao();
  final MediaDao _mediaDao = MediaDao();
  final NotaDao _notaDao = NotaDao();
  final TagDao _tagDao = TagDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();

  /// Esporta tutti i dati del database in formato JSON
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      // Carica tutti i dati dalle tabelle
      final persone = await _personaDao.getAllPersone();
      final eventi = await _eventoDao.getAllEventi();
      final media = await _mediaDao.getAllMedia();
      final note = await _notaDao.getAllNote();
      final tags = await _tagDao.getAllTags();
      final legami = await _legameDao.getAllLegami();

      return {
        'persone': persone,
        'eventi': eventi,
        'media': media,
        'note': note,
        'tags': tags,
        'persona_legami': legami,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Errore durante l\'esportazione dei dati: $e');
    }
  }

  /// Esporta solo i dati modificati dopo una certa data
  Future<Map<String, dynamic>> exportModifiedData(DateTime? since) async {
    try {
      final db = await _dbHelper.database;
      
      Map<String, dynamic> data = {
        'persone': [],
        'eventi': [],
        'media': [],
        'note': [],
        'tags': [],
        'persona_legami': [],
        'exported_at': DateTime.now().toIso8601String(),
      };

      if (since != null) {
        final sinceStr = since.toIso8601String();
        
        // Query per ottenere solo i record modificati dopo la data specificata
        data['persone'] = await db.query(
          'persone',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
        
        data['eventi'] = await db.query(
          'eventi',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
        
        data['media'] = await db.query(
          'media',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
        
        data['note'] = await db.query(
          'note',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
        
        data['tags'] = await db.query(
          'tags',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
        
        data['persona_legami'] = await db.query(
          'persona_legami',
          where: 'updated_at > ? OR last_synced_at IS NULL',
          whereArgs: [sinceStr],
        );
      } else {
        // Se non c'è una data, esporta tutto
        return await exportAllData();
      }

      return data;
    } catch (e) {
      throw Exception('Errore durante l\'esportazione dei dati modificati: $e');
    }
  }
}

