import '../models/persona_model.dart';

/// Interfaccia per il repository delle persone
abstract class PersonaRepository {
  /// Ottiene tutte le persone
  Future<List<PersonaModel>> getAllPersone();

  /// Ottiene una persona per ID
  Future<PersonaModel?> getPersonaById(int id);

  /// Cerca persone per nome o cognome
  Future<List<PersonaModel>> searchPersone(String query);

  /// Ottiene le persone con filtri opzionali
  Future<List<PersonaModel>> getPersoneWithFilters({
    String? nome,
    String? cognome,
    DateTime? natoDa,
    DateTime? natoA,
    DateTime? decedutoDa,
    DateTime? decedutoA,
    int? limit,
    int? offset,
  });

  /// Conta il numero totale di persone
  Future<int> countPersone();

  /// Aggiorna una persona
  Future<bool> updatePersona(int id, PersonaModel persona);

  /// Crea una nuova persona
  Future<PersonaModel?> createPersona(PersonaModel persona);
}

