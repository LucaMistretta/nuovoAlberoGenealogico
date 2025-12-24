import '../models/persona_model.dart';
import '../local/persona_dao.dart';
import 'persona_repository.dart';

/// Implementazione locale del repository delle persone (SQLite)
class LocalPersonaRepository implements PersonaRepository {
  final PersonaDao _personaDao = PersonaDao();

  @override
  Future<List<PersonaModel>> getAllPersone() async {
    final maps = await _personaDao.getAllPersone();
    return maps.map((map) => PersonaModel.fromMap(map)).toList();
  }

  @override
  Future<PersonaModel?> getPersonaById(int id) async {
    final map = await _personaDao.getPersonaById(id);
    return map != null ? PersonaModel.fromMap(map) : null;
  }

  @override
  Future<List<PersonaModel>> searchPersone(String query) async {
    final maps = await _personaDao.searchPersone(query);
    return maps.map((map) => PersonaModel.fromMap(map)).toList();
  }

  @override
  Future<List<PersonaModel>> getPersoneWithFilters({
    String? nome,
    String? cognome,
    DateTime? natoDa,
    DateTime? natoA,
    DateTime? decedutoDa,
    DateTime? decedutoA,
    int? limit,
    int? offset,
  }) async {
    final maps = await _personaDao.getPersoneWithFilters(
      nome: nome,
      cognome: cognome,
      natoDa: natoDa,
      natoA: natoA,
      decedutoDa: decedutoDa,
      decedutoA: decedutoA,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => PersonaModel.fromMap(map)).toList();
  }

  @override
  Future<int> countPersone() async {
    return await _personaDao.countPersone();
  }

  @override
  Future<bool> updatePersona(int id, PersonaModel persona) async {
    final data = persona.toMap();
    // Rimuovi l'id dalla mappa per l'update
    data.remove('id');
    return await _personaDao.updatePersona(id, data);
  }

  @override
  Future<PersonaModel?> createPersona(PersonaModel persona) async {
    final data = persona.toMap();
    // Rimuovi l'id per la creazione
    data.remove('id');
    final newId = await _personaDao.insertPersona(data);
    if (newId != null) {
      return await getPersonaById(newId);
    }
    return null;
  }
}

