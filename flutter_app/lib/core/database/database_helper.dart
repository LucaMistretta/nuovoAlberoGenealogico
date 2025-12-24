import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// Helper per la gestione del database SQLite locale
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Nome del database
  static const String _databaseName = 'agene.sqlite';
  static const String _databaseAssetPath = 'assets/database/agene.sqlite';
  static const int _databaseVersion = 2; // Incrementato per forzare aggiornamento

  /// Ottiene l'istanza del database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inizializza il database copiandolo dagli assets se necessario
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, _databaseName);

    // Verifica se il database esiste già e la sua versione
    final dbExists = await File(dbPath).exists();
    bool needsUpdate = false;

    if (dbExists) {
      // Controlla la versione del database esistente
      try {
        final existingDb = await openDatabase(dbPath, version: _databaseVersion);
        final version = await existingDb.getVersion();
        await existingDb.close();
        
        // Se la versione è inferiore, aggiorna il database
        if (version < _databaseVersion) {
          needsUpdate = true;
        }
      } catch (e) {
        // Se c'è un errore, probabilmente il database è corrotto o vecchio, ricopialo
        needsUpdate = true;
      }
    }

    if (!dbExists || needsUpdate) {
      // Chiudi il database se è aperto
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Elimina il database esistente se presente
      if (dbExists) {
        await File(dbPath).delete();
      }
      
      // Copia il database dagli assets
      await _copyDatabaseFromAssets(dbPath);
    }

    // Apri il database
    final db = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onOpen: (db) {
        // Abilita le foreign keys
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
    
    // Imposta la versione del database
    await db.setVersion(_databaseVersion);
    
    return db;
  }

  /// Copia il database dagli assets alla directory dell'app
  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    try {
      // Leggi il database dagli assets
      final ByteData data = await rootBundle.load(_databaseAssetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // Scrivi il database nella directory dell'app
      await File(dbPath).writeAsBytes(bytes);
    } catch (e) {
      // Se non trova il database negli assets, crea un database vuoto
      // Questo può succedere se il database deve essere scaricato dal server
      throw Exception(
        'Database non trovato negli assets. Assicurati di aver copiato '
        'database/agene.sqlite in assets/database/agene.sqlite',
      );
    }
  }

  /// Chiude il database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Verifica se il database esiste
  Future<bool> databaseExists() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, _databaseName);
    return await File(dbPath).exists();
  }

  /// Ottiene il percorso del database
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }
}

