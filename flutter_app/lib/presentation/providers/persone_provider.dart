import 'package:flutter/foundation.dart';
import '../../data/models/persona_model.dart';
import '../../data/repositories/persona_repository.dart';
import '../../data/repositories/local_persona_repository.dart';

/// Provider per la gestione della lista delle persone
class PersoneProvider with ChangeNotifier {
  final PersonaRepository _repository = LocalPersonaRepository();

  List<PersonaModel> _persone = [];
  List<PersonaModel> _filteredPersone = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<PersonaModel> get persone => _filteredPersone;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get count => _filteredPersone.length;

  /// Carica tutte le persone
  Future<void> loadPersone() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _persone = await _repository.getAllPersone();
      _applySearch();
    } catch (e) {
      _error = 'Errore nel caricamento delle persone: $e';
      _persone = [];
      _filteredPersone = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cerca persone
  void searchPersone(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Applica il filtro di ricerca
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredPersone = List.from(_persone);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredPersone = _persone.where((persona) {
        final nome = persona.nome?.toLowerCase() ?? '';
        final cognome = persona.cognome?.toLowerCase() ?? '';
        final nomeCompleto = persona.nomeCompleto.toLowerCase();
        return nome.contains(query) ||
            cognome.contains(query) ||
            nomeCompleto.contains(query);
      }).toList();
    }
  }

  /// Aggiorna la lista (pull-to-refresh)
  Future<void> refresh() async {
    await loadPersone();
  }

  /// Ottiene una persona per ID
  Future<PersonaModel?> getPersonaById(int id) async {
    try {
      return await _repository.getPersonaById(id);
    } catch (e) {
      _error = 'Errore nel caricamento della persona: $e';
      notifyListeners();
      return null;
    }
  }
}

