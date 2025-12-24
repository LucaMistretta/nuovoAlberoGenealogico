import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Servizio per la gestione delle immagini
class ImageService {
  static const String _imagesDirectoryName = 'images';

  /// Ottiene la directory delle immagini
  Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, _imagesDirectoryName));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    // Prova anche nella directory esterna (SD card) se disponibile
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalImagesDir = Directory(path.join(externalDir.path, _imagesDirectoryName));
        if (await externalImagesDir.exists()) {
          return externalImagesDir;
        }
      }
    } catch (e) {
      // Ignora errori e usa la directory interna
    }
    
    return imagesDir;
  }

  /// Ottiene il percorso completo di un'immagine
  Future<String> getImagePath(String relativePath) async {
    final imagesDir = await _getImagesDirectory();
    return path.join(imagesDir.path, relativePath);
  }

  /// Verifica se un'immagine esiste localmente
  Future<bool> imageExists(String relativePath) async {
    final imagePath = await getImagePath(relativePath);
    return await File(imagePath).exists();
  }

  /// Ottiene il file dell'immagine
  Future<File?> getImageFile(String relativePath) async {
    debugPrint('ImageService.getImageFile: cercando $relativePath');
    
    // Prova prima nella directory principale
    final imagePath = await getImagePath(relativePath);
    debugPrint('ImageService.getImageFile: percorso completo: $imagePath');
    
    final file = File(imagePath);
    if (await file.exists()) {
      debugPrint('ImageService.getImageFile: ✓ file trovato: $imagePath');
      return file;
    } else {
      debugPrint('ImageService.getImageFile: ✗ file non esiste: $imagePath');
    }
    
    // Prova anche nella SD card se disponibile
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalPath = path.join(externalDir.path, _imagesDirectoryName, relativePath);
        final externalFile = File(externalPath);
        if (await externalFile.exists()) {
          debugPrint('ImageService.getImageFile: ✓ immagine trovata su SD card: $externalPath');
          return externalFile;
        } else {
          debugPrint('ImageService.getImageFile: ✗ file non esiste su SD card: $externalPath');
        }
      }
    } catch (e) {
      debugPrint('ImageService.getImageFile: errore SD card: $e');
    }
    
    return null;
  }

  /// Copia e comprime un'immagine dalla directory sorgente alla directory locale
  Future<bool> copyImage(String sourcePath, String relativePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('ImageService: File sorgente non esiste: $sourcePath');
        return false;
      }

      debugPrint('ImageService: File sorgente trovato: $sourcePath');
      debugPrint('ImageService: Dimensione file sorgente: ${await sourceFile.length()} bytes');

      final imagesDir = await _getImagesDirectory();
      final destPath = path.join(imagesDir.path, relativePath);
      final destFile = File(destPath);

      debugPrint('ImageService: Directory destinazione: ${imagesDir.path}');
      debugPrint('ImageService: Percorso completo destinazione: $destPath');

      // Crea le directory necessarie
      await destFile.parent.create(recursive: true);
      debugPrint('ImageService: Directory create: ${destFile.parent.path}');

      // Comprimi l'immagine prima di salvarla
      try {
        debugPrint('ImageService: Inizio compressione...');
        final compressedData = await FlutterImageCompress.compressWithFile(
          sourceFile.absolute.path,
          minWidth: 1920,
          minHeight: 1080,
          quality: 85,
          format: CompressFormat.jpeg,
        );

        if (compressedData != null && compressedData.isNotEmpty) {
          await destFile.writeAsBytes(compressedData);
          debugPrint('ImageService: Immagine compressa salvata: $destPath');
          debugPrint('ImageService: Dimensione file compresso: ${compressedData.length} bytes');
          
          // Verifica che il file sia stato salvato correttamente
          if (await destFile.exists()) {
            final savedSize = await destFile.length();
            debugPrint('ImageService: File salvato verificato, dimensione: $savedSize bytes');
            return true;
          } else {
            debugPrint('ImageService: ERRORE - File non esiste dopo il salvataggio!');
            return false;
          }
        } else {
          debugPrint('ImageService: Dati compressi nulli o vuoti, copio il file originale');
          // Se la compressione fallisce, copia il file originale
          await sourceFile.copy(destPath);
          if (await destFile.exists()) {
            debugPrint('ImageService: File originale copiato con successo');
            return true;
          } else {
            debugPrint('ImageService: ERRORE - File originale non copiato!');
            return false;
          }
        }
      } catch (e, stackTrace) {
        debugPrint('ImageService: Errore nella compressione: $e');
        debugPrint('ImageService: Stack trace: $stackTrace');
        // Se la compressione fallisce, copia il file originale
        try {
          await sourceFile.copy(destPath);
          if (await destFile.exists()) {
            debugPrint('ImageService: File originale copiato come fallback');
            return true;
          } else {
            debugPrint('ImageService: ERRORE - Fallback fallito!');
            return false;
          }
        } catch (copyError) {
          debugPrint('ImageService: ERRORE nel fallback: $copyError');
          return false;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('ImageService: Errore generale nel salvataggio: $e');
      debugPrint('ImageService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Copia tutte le immagini da una directory sorgente
  Future<int> copyImagesFromDirectory(String sourceDirectory) async {
    int copiedCount = 0;
    try {
      final sourceDir = Directory(sourceDirectory);
      if (!await sourceDir.exists()) {
        return 0;
      }

      final imagesDir = await _getImagesDirectory();

      // Itera ricorsivamente su tutti i file nella directory sorgente
      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: sourceDirectory);
          final destPath = path.join(imagesDir.path, relativePath);
          final destFile = File(destPath);

          // Crea le directory necessarie
          await destFile.parent.create(recursive: true);

          // Copia il file se non esiste già
          if (!await destFile.exists()) {
            await entity.copy(destPath);
            copiedCount++;
          }
        }
      }
    } catch (e) {
      // Gestisci errori silenziosamente
    }
    return copiedCount;
  }

  /// Elimina un'immagine
  Future<bool> deleteImage(String relativePath) async {
    try {
      final imagePath = await getImagePath(relativePath);
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il percorso relativo da un percorso completo del server Laravel
  /// Il percorso nel database è già nella forma: media/persona_XX/file.jpg
  String getRelativePathFromLaravelPath(String laravelPath) {
    // Se il percorso è già nella forma corretta (media/persona_XX/file.jpg), restituiscilo così
    if (laravelPath.startsWith('media/')) {
      return laravelPath;
    }
    
    // Rimuove "storage/app/public/" se presente
    if (laravelPath.contains('storage/app/public/')) {
      return laravelPath.split('storage/app/public/').last;
    }
    // Rimuove "public/storage/" se presente
    if (laravelPath.contains('public/storage/')) {
      return laravelPath.split('public/storage/').last;
    }
    // Rimuove "public/" se presente
    if (laravelPath.contains('public/')) {
      return laravelPath.split('public/').last;
    }
    
    return laravelPath;
  }
}

