import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'data_export_service.dart';
import '../core/database/database_helper.dart';
import '../data/local/persona_dao.dart';
import '../data/local/evento_dao.dart';
import '../data/local/media_dao.dart';
import '../data/local/nota_dao.dart';
import '../data/local/tag_dao.dart';
import '../data/local/persona_legame_dao.dart';
import 'package:sqflite/sqflite.dart';

/// Servizio per sincronizzazione via USB ADB
/// Questo servizio esporta/importa dati tramite file JSON che vengono
/// trasferiti via ADB dallo script shell sync_via_adb.sh
class AdbSyncService {
  final DataExportService _exportService = DataExportService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PersonaDao _personaDao = PersonaDao();
  final EventoDao _eventoDao = EventoDao();
  final MediaDao _mediaDao = MediaDao();
  final NotaDao _notaDao = NotaDao();
  final TagDao _tagDao = TagDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();

  static const String _syncDataFileName = 'sync_data.json';
  static const String _syncResultFileName = 'sync_result.json';

  /// Esporta i dati dell'app in un file JSON per la sincronizzazione ADB
  Future<String> exportDataToFile() async {
    try {
      // Esporta tutti i dati
      final appData = await _exportService.exportAllData();
      appData.remove('exported_at');

      // Ottieni la directory dei file dell'app
      final appDir = await getApplicationDocumentsDirectory();
      final syncFile = File(path.join(appDir.path, _syncDataFileName));

      // Scrivi i dati nel file JSON
      await syncFile.writeAsString(json.encode(appData));

      return syncFile.path;
    } catch (e) {
      throw Exception('Errore durante l\'esportazione dei dati: $e');
    }
  }

  /// Importa i dati dal file JSON ricevuto via ADB
  Future<void> importDataFromFile() async {
    try {
      // Ottieni la directory dei file dell'app
      final appDir = await getApplicationDocumentsDirectory();
      final syncResultFile = File(path.join(appDir.path, _syncResultFileName));

      // Verifica che il file esista
      if (!await syncResultFile.exists()) {
        throw Exception('File di sync risultato non trovato');
      }

      // Leggi il file JSON
      final jsonString = await syncResultFile.readAsString();
      final serverData = json.decode(jsonString) as Map<String, dynamic>;

      // Applica i dati al database locale
      await _applyServerData(serverData);

      // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
      // Aggiorna last_synced_at
      // await _updateLastSyncedAt();

      // Elimina il file dopo l'importazione
      await syncResultFile.delete();
    } catch (e) {
      throw Exception('Errore durante l\'importazione dei dati: $e');
    }
  }

  /// Verifica se ci sono dati da importare
  Future<bool> hasDataToImport() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final syncResultFile = File(path.join(appDir.path, _syncResultFileName));
      return await syncResultFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Applica i dati ricevuti dal server al database locale
  Future<void> _applyServerData(Map<String, dynamic> serverData) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Applica persone
      if (serverData.containsKey('persone')) {
        for (final persona in serverData['persone'] as List) {
          final data = Map<String, dynamic>.from(persona);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('persone', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('persone', data);
            }
          }
        }
      }

      // Applica eventi
      if (serverData.containsKey('eventi')) {
        for (final evento in serverData['eventi'] as List) {
          final data = Map<String, dynamic>.from(evento);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('eventi', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('eventi', data);
            }
          }
        }
      }

      // Applica media
      if (serverData.containsKey('media')) {
        for (final media in serverData['media'] as List) {
          final data = Map<String, dynamic>.from(media);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('media', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('media', data);
            }
          }
        }
      }

      // Applica note
      if (serverData.containsKey('note')) {
        for (final nota in serverData['note'] as List) {
          final data = Map<String, dynamic>.from(nota);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('note', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('note', data);
            }
          }
        }
      }

      // Applica tags
      if (serverData.containsKey('tags')) {
        for (final tag in serverData['tags'] as List) {
          final data = Map<String, dynamic>.from(tag);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('tags', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('tags', data);
            }
          }
        }
      }

      // Applica persona_legami
      if (serverData.containsKey('persona_legami')) {
        for (final legame in serverData['persona_legami'] as List) {
          final data = Map<String, dynamic>.from(legame);
          final id = data['id'];
          // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
          // data['last_synced_at'] = now;
          if (id != null) {
            final count = await txn.update('persona_legami', data, where: 'id = ?', whereArgs: [id]);
            if (count == 0) {
              await txn.insert('persona_legami', data);
            }
          }
        }
      }
    });
  }

  /// Aggiorna last_synced_at per tutti i record
  Future<void> _updateLastSyncedAt() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE persone SET last_synced_at = ?', [now]);
      await txn.rawUpdate('UPDATE eventi SET last_synced_at = ?', [now]);
      await txn.rawUpdate('UPDATE media SET last_synced_at = ?', [now]);
      await txn.rawUpdate('UPDATE note SET last_synced_at = ?', [now]);
      await txn.rawUpdate('UPDATE tags SET last_synced_at = ?', [now]);
      await txn.rawUpdate('UPDATE persona_legami SET last_synced_at = ?', [now]);
    });
  }
}

