/// Modello per la tabella eventi
class EventoModel {
  final int id;
  final int personaId;
  final String tipoEvento;
  final String titolo;
  final String? descrizione;
  final DateTime? dataEvento;
  final String? luogo;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventoModel({
    required this.id,
    required this.personaId,
    required this.tipoEvento,
    required this.titolo,
    this.descrizione,
    this.dataEvento,
    this.luogo,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un'istanza da una mappa (da database SQLite)
  factory EventoModel.fromMap(Map<String, dynamic> map) {
    return EventoModel(
      id: map['id'] as int,
      personaId: map['persona_id'] as int,
      tipoEvento: map['tipo_evento'] as String,
      titolo: map['titolo'] as String,
      descrizione: map['descrizione'] as String?,
      dataEvento: map['data_evento'] != null
          ? DateTime.parse(map['data_evento'] as String)
          : null,
      luogo: map['luogo'] as String?,
      note: map['note'] as String?,
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
      'tipo_evento': tipoEvento,
      'titolo': titolo,
      'descrizione': descrizione,
      'data_evento': dataEvento?.toIso8601String().split('T')[0],
      'luogo': luogo,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'EventoModel(id: $id, tipoEvento: $tipoEvento, titolo: $titolo)';
  }
}

