/// Modello per la tabella media
class MediaModel {
  final int id;
  final int personaId;
  final String tipo; // 'foto' o 'documento'
  final String nomeFile;
  final String percorso;
  final int? dimensione;
  final String? mimeType;
  final String? descrizione;
  final DateTime dataCaricamento;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MediaModel({
    required this.id,
    required this.personaId,
    required this.tipo,
    required this.nomeFile,
    required this.percorso,
    this.dimensione,
    this.mimeType,
    this.descrizione,
    required this.dataCaricamento,
    this.createdAt,
    this.updatedAt,
  });

  /// Verifica se è una foto
  bool get isFoto => tipo == 'foto';

  /// Verifica se è un documento
  bool get isDocumento => tipo == 'documento';

  /// Crea un'istanza da una mappa (da database SQLite)
  factory MediaModel.fromMap(Map<String, dynamic> map) {
    return MediaModel(
      id: map['id'] as int,
      personaId: map['persona_id'] as int,
      tipo: map['tipo'] as String,
      nomeFile: map['nome_file'] as String,
      percorso: map['percorso'] as String,
      dimensione: map['dimensione'] as int?,
      mimeType: map['mime_type'] as String?,
      descrizione: map['descrizione'] as String?,
      dataCaricamento: DateTime.parse(map['data_caricamento'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Converte l'istanza in una mappa (per database SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'persona_id': personaId,
      'tipo': tipo,
      'nome_file': nomeFile,
      'percorso': percorso,
      'dimensione': dimensione,
      'mime_type': mimeType,
      'descrizione': descrizione,
      'data_caricamento': dataCaricamento.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MediaModel(id: $id, tipo: $tipo, nomeFile: $nomeFile)';
  }
}

