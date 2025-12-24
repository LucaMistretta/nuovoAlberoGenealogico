/// Modello per la tabella persone
class PersonaModel {
  final int id;
  final String? nome;
  final String? cognome;
  final String? natoA;
  final DateTime? natoIl;
  final String? decedutoA;
  final DateTime? decedutoIl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonaModel({
    required this.id,
    this.nome,
    this.cognome,
    this.natoA,
    this.natoIl,
    this.decedutoA,
    this.decedutoIl,
    this.createdAt,
    this.updatedAt,
  });

  /// Nome completo della persona
  String get nomeCompleto {
    final parts = <String>[];
    if (nome != null && nome!.isNotEmpty) parts.add(nome!);
    if (cognome != null && cognome!.isNotEmpty) parts.add(cognome!);
    return parts.join(' ').isEmpty ? 'Senza nome' : parts.join(' ');
  }

  /// Crea un'istanza da una mappa (da database SQLite)
  factory PersonaModel.fromMap(Map<String, dynamic> map) {
    return PersonaModel(
      id: map['id'] as int,
      nome: map['nome'] as String?,
      cognome: map['cognome'] as String?,
      natoA: map['nato_a'] as String?,
      natoIl: map['nato_il'] != null
          ? DateTime.parse(map['nato_il'] as String)
          : null,
      decedutoA: map['deceduto_a'] as String?,
      decedutoIl: map['deceduto_il'] != null
          ? DateTime.parse(map['deceduto_il'] as String)
          : null,
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
      'cognome': cognome,
      'nato_a': natoA,
      'nato_il': natoIl?.toIso8601String().split('T')[0],
      'deceduto_a': decedutoA,
      'deceduto_il': decedutoIl?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea una copia con valori aggiornati
  PersonaModel copyWith({
    int? id,
    String? nome,
    String? cognome,
    String? natoA,
    DateTime? natoIl,
    String? decedutoA,
    DateTime? decedutoIl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      natoA: natoA ?? this.natoA,
      natoIl: natoIl ?? this.natoIl,
      decedutoA: decedutoA ?? this.decedutoA,
      decedutoIl: decedutoIl ?? this.decedutoIl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PersonaModel(id: $id, nomeCompleto: $nomeCompleto)';
  }
}

