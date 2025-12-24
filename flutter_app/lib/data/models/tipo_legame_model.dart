/// Modello per la tabella tipi_di_legame
class TipoLegameModel {
  final int id;
  final String nome;
  final String? descrizione;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TipoLegameModel({
    required this.id,
    required this.nome,
    this.descrizione,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un'istanza da una mappa (da database SQLite)
  factory TipoLegameModel.fromMap(Map<String, dynamic> map) {
    return TipoLegameModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
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
      'descrizione': descrizione,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

