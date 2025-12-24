/// Modello per la tabella tags
class TagModel {
  final int id;
  final String nome;
  final String colore;
  final String? descrizione;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TagModel({
    required this.id,
    required this.nome,
    required this.colore,
    this.descrizione,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un'istanza da una mappa (da database SQLite)
  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      colore: map['colore'] as String,
      descrizione: map['descrizione'] as String?,
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
      'nome': nome,
      'colore': colore,
      'descrizione': descrizione,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TagModel(id: $id, nome: $nome, colore: $colore)';
  }
}

