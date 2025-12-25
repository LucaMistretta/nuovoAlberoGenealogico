import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import 'api_client.dart';
import 'data_export_service.dart';
import 'adb_sync_service.dart';
import 'image_service.dart';
import '../data/local/persona_dao.dart';
import '../data/local/evento_dao.dart';
import '../data/local/media_dao.dart';
import '../data/local/nota_dao.dart';
import '../data/local/tag_dao.dart';
import '../data/local/persona_legame_dao.dart';

/// Servizio per la sincronizzazione bidirezionale con il server Laravel
class SyncService {
  final ApiClient _apiClient = ApiClient();
  final DataExportService _exportService = DataExportService();
  final AdbSyncService _adbSyncService = AdbSyncService();
  final ImageService _imageService = ImageService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PersonaDao _personaDao = PersonaDao();
  final EventoDao _eventoDao = EventoDao();
  final MediaDao _mediaDao = MediaDao();
  final NotaDao _notaDao = NotaDao();
  final TagDao _tagDao = TagDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();

  /// Calcola le differenze tra database locale e server
  Future<Map<String, dynamic>> calculateDiff(DateTime? lastSyncTimestamp, {String syncMode = 'http'}) async {
    if (syncMode == 'adb') {
      // Per ADB, esporta i dati in un file e aspetta che lo script ADB li processi
      await _adbSyncService.exportDataToFile();
      throw Exception('Per ADB, usa lo script sync_via_adb.sh dal server. I dati sono stati esportati in sync_data.json');
    }

    // Modalità HTTP: calcola le differenze direttamente tramite API
    try {
      // Esporta i dati locali
      final appData = await _exportService.exportAllData();
      
      // Rimuovi il campo exported_at che non serve per il diff
      appData.remove('exported_at');

      // Chiama l'API per calcolare le differenze
      final response = await _apiClient.post('/sync/diff', {
        'app_data': appData,
        'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
      });

      if (response['success'] == true) {
        return response['diff'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Errore nel calcolo delle differenze');
      }
    } catch (e) {
      throw Exception('Errore durante il calcolo delle differenze: $e');
    }
  }

  /// Push: invia dati dall'app al server (App → Server)
  Future<Map<String, dynamic>> pushToServer(String syncMode) async {
    if (syncMode == 'adb') {
      // Per ADB, esporta i dati in un file e aspetta che lo script ADB li processi
      await _adbSyncService.exportDataToFile();
      throw Exception('Per ADB, esegui: ./sync_via_adb.sh push');
    }

    try {
      // Esporta i dati locali
      final appData = await _exportService.exportAllData();
      appData.remove('exported_at');

      // Invia al server
      final response = await _apiClient.post('/sync/push-from-app', {
        'app_data': appData,
        'sync_mode': syncMode,
      });

      if (response['success'] == true) {
        // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
        // Aggiorna last_synced_at per tutti i record sincronizzati
        // await _updateLastSyncedAt();
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Errore durante il push');
      }
    } catch (e) {
      throw Exception('Errore durante il push: $e');
    }
  }

  /// Pull: riceve dati dal server e li applica localmente (Server → App)
  Future<Map<String, dynamic>> pullFromServer(DateTime? lastSyncTimestamp, {String syncMode = 'http'}) async {
    if (syncMode == 'adb') {
      // Per ADB, verifica se ci sono dati da importare
      final hasData = await _adbSyncService.hasDataToImport();
      if (hasData) {
        await _adbSyncService.importDataFromFile();
        return {'success': true, 'message': 'Dati importati via ADB'};
      } else {
        throw Exception('Per ADB, esegui prima: ./sync_via_adb.sh pull');
      }
    }

    try {
      // Richiedi i dati dal server
      final response = await _apiClient.post('/sync/pull-to-app', {
        'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
      });

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        
        // I dati sono direttamente in 'data', non in 'data.data'
        final serverData = data.containsKey('data') ? data['data'] as Map<String, dynamic> : data;

        // Applica i dati al database locale
        await _applyServerData(serverData);

        // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
        // Aggiorna last_synced_at
        // await _updateLastSyncedAt();

        return data;
      } else {
        throw Exception(response['message'] ?? 'Errore durante il pull');
      }
    } catch (e) {
      throw Exception('Errore durante il pull: $e');
    }
  }

  /// Merge: unisce dati da entrambi i lati
  Future<Map<String, dynamic>> merge(DateTime? lastSyncTimestamp, String syncMode) async {
    if (syncMode == 'adb') {
      // Per ADB, esporta i dati e aspetta che lo script ADB faccia il merge
      await _adbSyncService.exportDataToFile();
      // Poi verifica se ci sono dati da importare dopo il merge
      final hasData = await _adbSyncService.hasDataToImport();
      if (hasData) {
        await _adbSyncService.importDataFromFile();
        return {'success': true, 'message': 'Merge completato via ADB'};
      } else {
        throw Exception('Per ADB, esegui: ./sync_via_adb.sh merge');
      }
    }

    try {
      // Esporta i dati locali
      final appData = await _exportService.exportAllData();
      appData.remove('exported_at');

      // Raccogli i file immagine da inviare
      final Map<String, File> mediaFiles = {};
      if (appData.containsKey('media')) {
        for (final media in appData['media'] as List) {
          final mediaId = media['id'];
          final percorso = media['percorso'] as String?;
          
          if (percorso != null && mediaId != null) {
            // Prova a trovare il file immagine locale
            final imageFile = await _imageService.getImageFile(percorso);
            if (imageFile != null && await imageFile.exists()) {
              // Usa media_id come chiave per identificare il file
              mediaFiles[mediaId.toString()] = imageFile;
            }
          }
        }
      }

      // Se ci sono file da inviare, usa multipart, altrimenti JSON normale
      final response = mediaFiles.isNotEmpty
          ? await _apiClient.postMultipart(
              '/sync/merge',
              {
                'app_data': appData,
                'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
              },
              mediaFiles,
            )
          : await _apiClient.post('/sync/merge', {
              'app_data': appData,
              'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
            });

      if (response['success'] == true) {
        final result = response['data'] as Map<String, dynamic>;
        
        // Se il server ha inviato dati aggiornati, applicali localmente
        if (result.containsKey('server_data')) {
          await _applyServerData(result['server_data'] as Map<String, dynamic>);
        }

        // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
        // Aggiorna last_synced_at
        // await _updateLastSyncedAt();

        return result;
      } else {
        throw Exception(response['message'] ?? 'Errore durante il merge');
      }
    } catch (e) {
      throw Exception('Errore durante il merge: $e');
    }
  }

  /// Ottiene lo stato della sincronizzazione
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiClient.get('/sync/status');
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Errore nel recupero dello stato');
      }
    } catch (e) {
      throw Exception('Errore durante il recupero dello stato: $e');
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
            // Usa updateOrInsert per gestire sia nuovi che esistenti
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

