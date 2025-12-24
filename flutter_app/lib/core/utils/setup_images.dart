import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../../services/image_service.dart';

/// Utility per copiare le immagini dalla SD card alla directory dell'app al primo avvio
class SetupImages {
  final ImageService _imageService = ImageService();

  /// Copia le immagini da varie sorgenti possibili alla directory dell'app
  Future<int> copyImagesFromSDCard() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'images'));
      
      // Se le immagini esistono già e ci sono file, salta
      if (await imagesDir.exists()) {
        final files = await imagesDir.list(recursive: true).toList();
        final fileCount = files.whereType<File>().length;
        if (fileCount > 0) {
          debugPrint('SetupImages: Immagini già presenti ($fileCount file). Salto la copia.');
          return fileCount;
        }
      }

      // Crea la directory se non esiste
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Lista di percorsi possibili da cui copiare le immagini
      final possibiliPercorsi = [
        '/sdcard/Android/data/com.alberogenealogico.agene/files/images/media',
        '/storage/emulated/0/Android/data/com.alberogenealogico.agene/files/images/media',
        '/sdcard/Download/images/media',
        '/storage/emulated/0/Download/images/media',
      ];

      int totaleCopiate = 0;

      // Prova ogni percorso possibile
      for (final percorso in possibiliPercorsi) {
        try {
          final sourceDir = Directory(percorso);
          if (await sourceDir.exists()) {
            debugPrint('SetupImages: Trovata directory sorgente: $percorso');
            final copiate = await _imageService.copyImagesFromDirectory(percorso);
            totaleCopiate += copiate;
            debugPrint('SetupImages: Copiate $copiate immagini da $percorso');
            
            // Se abbiamo copiato immagini, possiamo fermarci
            if (copiate > 0) {
              break;
            }
          }
        } catch (e) {
          debugPrint('SetupImages: Errore nel percorso $percorso: $e');
          // Continua con il prossimo percorso
        }
      }

      // Se non abbiamo trovato immagini, prova anche a cercare nella directory esterna
      if (totaleCopiate == 0) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final externalImagesPath = path.join(externalDir.path, 'images', 'media');
            final externalImagesDir = Directory(externalImagesPath);
            if (await externalImagesDir.exists()) {
              debugPrint('SetupImages: Trovata directory esterna: $externalImagesPath');
              final copiate = await _imageService.copyImagesFromDirectory(externalImagesPath);
              totaleCopiate += copiate;
              debugPrint('SetupImages: Copiate $copiate immagini dalla directory esterna');
            }
          }
        } catch (e) {
          debugPrint('SetupImages: Errore nella directory esterna: $e');
        }
      }

      debugPrint('SetupImages: Totale immagini copiate: $totaleCopiate');
      return totaleCopiate;
    } catch (e) {
      debugPrint('SetupImages: Errore generale: $e');
      return 0;
    }
  }
}

