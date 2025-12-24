import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/image_service.dart';
import 'dart:io';

/// Widget per visualizzare l'avatar di una persona
class PersonaAvatar extends StatelessWidget {
  final String? imagePath; // Percorso relativo dell'immagine
  final String? nomeCompleto; // Nome completo per il placeholder
  final double radius;
  final bool isLocal; // Se true, cerca l'immagine localmente

  const PersonaAvatar({
    super.key,
    this.imagePath,
    this.nomeCompleto,
    this.radius = 30,
    this.isLocal = true,
  });

  @override
  Widget build(BuildContext context) {
    // Se non c'è un percorso immagine, mostra l'avatar con iniziale
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildInitialAvatar();
    }

    if (isLocal) {
      return _buildLocalAvatar();
    } else {
      return _buildNetworkAvatar();
    }
  }

  /// Costruisce l'avatar con iniziale
  Widget _buildInitialAvatar() {
    final initial = nomeCompleto != null && nomeCompleto!.isNotEmpty
        ? nomeCompleto![0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// Costruisce l'avatar con immagine locale
  Widget _buildLocalAvatar() {
    return FutureBuilder<File?>(
      future: ImageService().getImageFile(imagePath!),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(snapshot.data!),
            onBackgroundImageError: (exception, stackTrace) {
              // Se c'è un errore nel caricamento, mostra l'avatar con iniziale
            },
            child: snapshot.hasError ? _buildInitialAvatar() : null,
          );
        }
        return _buildInitialAvatar();
      },
    );
  }

  /// Costruisce l'avatar con immagine da rete
  Widget _buildNetworkAvatar() {
    return CachedNetworkImage(
      imageUrl: imagePath!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => _buildInitialAvatar(),
      errorWidget: (context, url, error) => _buildInitialAvatar(),
    );
  }
}

