import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/media_model.dart';
import '../../data/local/media_dao.dart';
import '../../core/database/database_helper.dart';
import '../../services/image_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Schermata per gestire i media di una persona
class PersonaEditMediaScreen extends StatefulWidget {
  final int personaId;

  const PersonaEditMediaScreen({
    super.key,
    required this.personaId,
  });

  @override
  State<PersonaEditMediaScreen> createState() => _PersonaEditMediaScreenState();
}

class _PersonaEditMediaScreenState extends State<PersonaEditMediaScreen> {
  final MediaDao _mediaDao = MediaDao();
  final ImageService _imageService = ImageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<MediaModel> _media = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _addMedia() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Sorgente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galleria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File non trovato'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Genera un nome file univoco basato sul timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Usa sempre .jpg per le immagini compresse
      final fileName = 'img_$timestamp.jpg';
      final relativePath = 'media/persona_${widget.personaId}/$fileName';

      debugPrint('PersonaEditMediaScreen: Inizio salvataggio immagine');
      debugPrint('PersonaEditMediaScreen: File sorgente: ${file.path}');
      debugPrint('PersonaEditMediaScreen: Percorso relativo: $relativePath');

      // Copia e comprime l'immagine nella directory dell'app
      final copied = await _imageService.copyImage(file.path, relativePath);
      if (!copied) {
        debugPrint('PersonaEditMediaScreen: Errore nella copia dell\'immagine');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nel salvataggio dell\'immagine'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint('PersonaEditMediaScreen: Immagine copiata con successo');

      // Ottieni la dimensione del file compresso
      final imagePath = await _imageService.getImagePath(relativePath);
      final savedFile = File(imagePath);
      
      if (!await savedFile.exists()) {
        debugPrint('PersonaEditMediaScreen: File salvato non esiste: $imagePath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore: file salvato non trovato'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final fileSize = await savedFile.length();
      debugPrint('PersonaEditMediaScreen: Dimensione file salvato: $fileSize bytes');

      // Salva nel database
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      
      final insertedId = await db.insert(
        'media',
        {
          'persona_id': widget.personaId,
          'tipo': 'foto',
          'nome_file': fileName,
          'percorso': relativePath,
          'dimensione': fileSize,
          'mime_type': 'image/jpeg',
          'data_caricamento': now,
          'created_at': now,
          'updated_at': now,
        },
      );

      if (insertedId > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Immagine aggiunta con successo'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadMedia();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nel salvataggio nel database'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Errore nell\'aggiunta media: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedia(MediaModel media) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Media'),
        content: const Text('Sei sicuro di voler eliminare questo media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Elimina dal database
        final db = await DatabaseHelper.instance.database;
        await db.delete(
          'media',
          where: 'id = ?',
          whereArgs: [media.id],
        );

        // Elimina il file
        await _imageService.deleteImage(media.percorso);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Media eliminato con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadMedia();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'eliminazione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _media.isEmpty
                      ? const Center(
                          child: Text('Nessun media disponibile'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _media.length,
                          itemBuilder: (context, index) {
                            final media = _media[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                FutureBuilder<File?>(
                                  future: () async {
                                    final relativePath = _imageService.getRelativePathFromLaravelPath(media.percorso);
                                    var file = await _imageService.getImageFile(relativePath);
                                    if (file != null) return file;
                                    final nomeFilePath = 'media/persona_${media.personaId}/${media.nomeFile}';
                                    return await _imageService.getImageFile(nomeFilePath);
                                  }(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Image.file(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        media.isFoto
                                            ? Icons.photo
                                            : Icons.description,
                                        size: 48,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteMedia(media),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _addMedia,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Aggiungi Immagine'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

