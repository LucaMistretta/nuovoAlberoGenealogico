import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../services/image_service.dart';

/// Utility per sincronizzare le immagini dal server al telefono
class ImageSync {
  final ImageService _imageService = ImageService();

  /// Copia tutte le immagini dalla directory assets alla directory dell'app
  Future<int> syncImagesFromAssets() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final assetsImagesDir = Directory(path.join(appDir.path, '..', 'flutter_assets', 'images'));
      final localImagesDir = Directory(path.join(appDir.path, 'images'));

      if (!await assetsImagesDir.exists()) {
        return 0;
      }

      int copiedCount = 0;

      // Itera su tutti i file nelle directory assets/images
      await for (final entity in assetsImagesDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: assetsImagesDir.path);
          final destPath = path.join(localImagesDir.path, relativePath);
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

      return copiedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Copia le immagini dalla directory storage Laravel alla directory dell'app
  /// Questo metodo può essere chiamato manualmente per sincronizzare le immagini
  Future<int> syncImagesFromLaravelStorage(String laravelStoragePath) async {
    try {
      final sourceDir = Directory(laravelStoragePath);
      if (!await sourceDir.exists()) {
        return 0;
      }

      return await _imageService.copyImagesFromDirectory(laravelStoragePath);
    } catch (e) {
      return 0;
    }
  }
}

