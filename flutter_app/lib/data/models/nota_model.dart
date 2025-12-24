/// Modello per la tabella note
class NotaModel {
  final int id;
  final int personaId;
  final int? userId;
  final String contenuto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotaModel({
    required this.id,
    required this.personaId,
    this.userId,
    required this.contenuto,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un'istanza da una mappa (da database SQLite)
  factory NotaModel.fromMap(Map<String, dynamic> map) {
    return NotaModel(
      id: map['id'] as int,
      personaId: map['persona_id'] as int,
      userId: map['user_id'] as int?,
      contenuto: map['contenuto'] as String,
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
      'user_id': userId,
      'contenuto': contenuto,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'NotaModel(id: $id, personaId: $personaId)';
  }
}

