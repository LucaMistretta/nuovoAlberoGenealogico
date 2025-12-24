import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility per caricare immagini dagli assets dell'app
class AssetsImageLoader {
  /// Carica un'immagine dagli assets e la copia nella directory dell'app se necessario
  static Future<File?> loadImageFromAssets(String assetPath) async {
    try {
      // Il percorso negli assets è: assets/images/media/persona_XX/file.jpg
      // Il percorso passato è già: media/persona_XX/file.jpg
      final fullAssetPath = 'assets/images/$assetPath';
      
      debugPrint('AssetsImageLoader: cercando asset: $fullAssetPath');
      
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = path.join(appDir.path, 'images', assetPath);
      final localFile = File(localPath);
      
      debugPrint('AssetsImageLoader: percorso locale: $localPath');

      // Se il file esiste già localmente, restituiscilo
      if (await localFile.exists()) {
        debugPrint('AssetsImageLoader: ✓ file già esistente localmente: $localPath');
        return localFile;
      }

      // Prova a caricare dagli assets
      try {
        debugPrint('AssetsImageLoader: caricamento da assets: $fullAssetPath');
        final byteData = await rootBundle.load(fullAssetPath);
        final bytes = byteData.buffer.asUint8List();
        
        debugPrint('AssetsImageLoader: asset caricato, dimensione: ${bytes.length} bytes');

        // Crea le directory necessarie
        await localFile.parent.create(recursive: true);
        debugPrint('AssetsImageLoader: directory create: ${localFile.parent.path}');

        // Scrivi il file localmente
        await localFile.writeAsBytes(bytes);
        debugPrint('AssetsImageLoader: ✓ file scritto localmente: $localPath');
        
        // Verifica che il file sia stato scritto correttamente
        if (await localFile.exists()) {
          final savedSize = await localFile.length();
          debugPrint('AssetsImageLoader: ✓ file verificato, dimensione: $savedSize bytes');
          return localFile;
        } else {
          debugPrint('AssetsImageLoader: ✗ ERRORE - file non esiste dopo il salvataggio!');
          return null;
        }
      } catch (e) {
        debugPrint('AssetsImageLoader: errore nel caricamento da assets: $e');
        // Se non trova negli assets, prova anche senza il prefisso assets/images
        // perché potrebbe essere già incluso nel percorso
        try {
          debugPrint('AssetsImageLoader: provo senza prefisso: $assetPath');
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();
          await localFile.parent.create(recursive: true);
          await localFile.writeAsBytes(bytes);
          debugPrint('AssetsImageLoader: ✓ file caricato senza prefisso');
          return localFile;
        } catch (e2) {
          debugPrint('AssetsImageLoader: ✗ ERRORE anche senza prefisso: $e2');
          // Se non trova, restituisci null
          return null;
        }
      }
    } catch (e) {
      debugPrint('AssetsImageLoader: ✗ ERRORE generale: $e');
      return null;
    }
  }

  /// Verifica se un'immagine esiste negli assets
  static Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load('assets/images/$assetPath');
      return true;
    } catch (e) {
      return false;
    }
  }
}

