import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/media_model.dart';
import '../../data/local/media_dao.dart';
import '../../services/image_service.dart';
import '../../core/utils/assets_image_loader.dart';
import 'dart:io';

/// Schermata galleria media di una persona
class MediaGalleryScreen extends StatefulWidget {
  final int personaId;
  final int initialIndex;

  const MediaGalleryScreen({
    super.key,
    required this.personaId,
    this.initialIndex = 0,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  final MediaDao _mediaDao = MediaDao();
  final ImageService _imageService = ImageService();
  List<MediaModel> _media = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mediaMaps = await _mediaDao.getMediaByPersonaId(widget.personaId);
      setState(() {
        _media = mediaMaps.map((map) => MediaModel.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Ottiene il file immagine, cercando prima negli assets poi nella directory locale
  Future<File?> _getImageFile(MediaModel media) async {
    // Il percorso nel database è già nella forma: media/persona_XX/timestamp_filename.jpg
    // Usa sempre il campo 'percorso' che contiene il percorso completo corretto
    String relativePath = _imageService.getRelativePathFromLaravelPath(media.percorso);
    
    // Debug: stampa tutti i dettagli
    debugPrint('=== Media ID: ${media.id} ===');
    debugPrint('Percorso DB: ${media.percorso}');
    debugPrint('Nome file DB: ${media.nomeFile}');
    debugPrint('Percorso relativo calcolato: $relativePath');
    
    // Se il percorso contiene solo il nome file, prova a costruire il percorso completo
    if (!relativePath.contains('/')) {
      relativePath = 'media/persona_${media.personaId}/$relativePath';
      debugPrint('Percorso ricostruito: $relativePath');
    }
    
    // Prova prima negli assets con il percorso dal database (timestamp)
    debugPrint('Cercando negli assets: assets/images/$relativePath');
    var assetsFile = await AssetsImageLoader.loadImageFromAssets(relativePath);
    if (assetsFile != null) {
      debugPrint('✓ Immagine trovata negli assets con percorso DB: ${assetsFile.path}');
      return assetsFile;
    }
    
    // Se non trova, prova con il nome file originale (potrebbe essere che negli assets
    // i file abbiano il nome originale invece del timestamp)
    final nomeFilePath = 'media/persona_${media.personaId}/${media.nomeFile}';
    debugPrint('Provo negli assets con nome file originale: assets/images/$nomeFilePath');
    assetsFile = await AssetsImageLoader.loadImageFromAssets(nomeFilePath);
    if (assetsFile != null) {
      debugPrint('✓ Immagine trovata negli assets con nome originale: ${assetsFile.path}');
      return assetsFile;
    }
    
    debugPrint('✗ Immagine non trovata negli assets, provo nella directory locale');
    
    // Poi prova nella directory locale dell'app con il percorso dal database
    var localFile = await _imageService.getImageFile(relativePath);
    if (localFile != null) {
      debugPrint('✓ Immagine trovata localmente: ${localFile.path}');
      return localFile;
    }
    
    // Prova anche con il nome file originale nella directory locale
    localFile = await _imageService.getImageFile(nomeFilePath);
    if (localFile != null) {
      debugPrint('✓ Immagine trovata localmente con nome originale: ${localFile.path}');
      return localFile;
    }
    
    debugPrint('✗✗✗ Immagine NON trovata: $relativePath né con nome originale: $nomeFilePath');
    debugPrint('=== Fine ricerca Media ID: ${media.id} ===');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_media.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Media')),
        body: const Center(
          child: Text('Nessun media disponibile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Media (${_currentIndex + 1}/${_media.length})'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: _currentIndex),
        itemCount: _media.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final media = _media[index];
          return Center(
            child: FutureBuilder<File?>(
              future: _getImageFile(media),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  );
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        media.isFoto ? Icons.photo : Icons.description,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(media.nomeFile),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

