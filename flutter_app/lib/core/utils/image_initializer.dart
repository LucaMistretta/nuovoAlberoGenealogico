import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../services/image_service.dart';

/// Utility per inizializzare le immagini al primo avvio dell'app
class ImageInitializer {
  final ImageService _imageService = ImageService();

  /// Copia tutte le immagini dagli assets alla directory dell'app
  /// Questo viene chiamato una sola volta al primo avvio
  Future<int> initializeImagesFromAssets() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'images'));
      
      // Se la directory immagini esiste già e non è vuota, salta la copia
      if (await imagesDir.exists()) {
        final files = await imagesDir.list().toList();
        if (files.isNotEmpty) {
          return files.length;
        }
      }

      int copiedCount = 0;
      
      // Lista delle directory persona negli assets
      final personaDirs = ['persona_20', 'persona_22', 'persona_24', 'persona_25'];
      
      for (final personaDir in personaDirs) {
        try {
          // Prova a caricare tutti i file dalla directory persona
          final manifestContent = await rootBundle.loadString('AssetManifest.json');
          final Map<String, dynamic> manifestMap = 
              json.decode(manifestContent) as Map<String, dynamic>;
          
          // Filtra i file che appartengono a questa directory persona
          final personaAssets = manifestMap.keys.where((key) => 
            key.startsWith('assets/images/media/$personaDir/') &&
            (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png'))
          );
          
          for (final assetPath in personaAssets) {
            try {
              // Rimuovi il prefisso "assets/images/" per ottenere il percorso relativo
              final relativePath = assetPath.replaceFirst('assets/images/', '');
              
              // Carica il file dagli assets
              final byteData = await rootBundle.load(assetPath);
              final bytes = byteData.buffer.asUint8List();
              
              // Salva nella directory dell'app
              final localPath = path.join(imagesDir.path, relativePath);
              final localFile = File(localPath);
              
              // Crea le directory necessarie
              await localFile.parent.create(recursive: true);
              
              // Scrivi il file
              await localFile.writeAsBytes(bytes);
              copiedCount++;
            } catch (e) {
              // Continua con il prossimo file
            }
          }
        } catch (e) {
          // Continua con la prossima directory
        }
      }
      
      return copiedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Copia le immagini dalla directory storage Laravel (se disponibile)
  /// Questo può essere chiamato manualmente per sincronizzare
  Future<int> copyImagesFromLaravelStorage(String storagePath) async {
    return await _imageService.copyImagesFromDirectory(storagePath);
  }
}

