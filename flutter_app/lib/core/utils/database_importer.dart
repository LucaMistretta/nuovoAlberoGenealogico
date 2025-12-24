import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../../services/image_service.dart';

/// Utility per importare database e immagini dal server Laravel
class DatabaseImporter {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageService _imageService = ImageService();

  /// Copia il database SQLite dalla directory sorgente
  Future<bool> copyDatabase(String sourceDbPath) async {
    try {
      final sourceFile = File(sourceDbPath);
      if (!await sourceFile.exists()) {
        throw Exception('Database sorgente non trovato: $sourceDbPath');
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final destPath = path.join(documentsDirectory.path, 'agene.sqlite');

      // Copia il file
      await sourceFile.copy(destPath);

      // Verifica l'integrità del database
      return await _verifyDatabaseIntegrity(destPath);
    } catch (e) {
      return false;
    }
  }

  /// Verifica l'integrità del database
  Future<bool> _verifyDatabaseIntegrity(String dbPath) async {
    try {
      // Prova ad aprire il database
      final db = await _dbHelper.database;
      
      // Esegui una query semplice per verificare che funzioni
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM persone');
      final count = result.first['count'] as int?;
      
      return count != null;
    } catch (e) {
      return false;
    }
  }

  /// Copia le immagini dalla directory storage del server Laravel
  Future<int> copyImages(String sourceImagesPath) async {
    try {
      return await _imageService.copyImagesFromDirectory(sourceImagesPath);
    } catch (e) {
      return 0;
    }
  }

  /// Importa tutto (database + immagini)
  Future<ImportResult> importAll({
    required String sourceDbPath,
    required String sourceImagesPath,
  }) async {
    final result = ImportResult();

    // Copia il database
    result.databaseCopied = await copyDatabase(sourceDbPath);
    if (!result.databaseCopied) {
      result.error = 'Errore nella copia del database';
      return result;
    }

    // Copia le immagini
    result.imagesCopied = await copyImages(sourceImagesPath);
    result.success = true;

    return result;
  }
}

/// Risultato dell'operazione di importazione
class ImportResult {
  bool success = false;
  bool databaseCopied = false;
  int imagesCopied = 0;
  String? error;

  @override
  String toString() {
    return 'ImportResult(success: $success, databaseCopied: $databaseCopied, '
        'imagesCopied: $imagesCopied, error: $error)';
  }
}

