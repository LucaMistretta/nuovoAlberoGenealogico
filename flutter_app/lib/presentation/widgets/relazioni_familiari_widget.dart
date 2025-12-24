import 'package:flutter/material.dart';
import '../../data/models/persona_model.dart';
import '../../data/models/tipo_legame_model.dart';
import '../../data/local/persona_legame_dao.dart';
import '../../data/local/persona_dao.dart';
import '../../data/local/tipo_legame_dao.dart';
import '../screens/persona_detail_screen.dart';

/// Widget per visualizzare le relazioni familiari di una persona
class RelazioniFamiliariWidget extends StatefulWidget {
  final int personaId;

  const RelazioniFamiliariWidget({
    super.key,
    required this.personaId,
  });

  @override
  State<RelazioniFamiliariWidget> createState() =>
      _RelazioniFamiliariWidgetState();
}

class _RelazioniFamiliariWidgetState extends State<RelazioniFamiliariWidget> {
  final PersonaLegameDao _legameDao = PersonaLegameDao();
  final PersonaDao _personaDao = PersonaDao();
  final TipoLegameDao _tipoLegameDao = TipoLegameDao();

  List<Map<String, dynamic>> _relazioni = [];
  Map<int, PersonaModel> _personeCache = {};
  Map<int, TipoLegameModel> _tipiLegameCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelazioni();
  }

  /// Carica tutte le relazioni familiari
  Future<void> _loadRelazioni() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica tutti i tipi di legame
      final tipiLegame = await _tipoLegameDao.getAllTipiLegame();
      _tipiLegameCache = {
        for (var tipo in tipiLegame) tipo.id: tipo
      };

      // Carica tutti i legami della persona
      final legami = await _legameDao.getLegamiByPersonaId(widget.personaId);

      // Identifica i coniugi per caricare anche i loro figli
      final coniugiIds = <int>{};
      TipoLegameModel? tipoConiuge;
      try {
        tipoConiuge = _tipiLegameCache.values
            .firstWhere((t) => t.nome.toLowerCase() == 'coniuge');
      } catch (e) {
        tipoConiuge = null;
      }
      final tipoConiugeId = tipoConiuge?.id;
      
      if (tipoConiugeId != null) {
        for (final legame in legami) {
          final tipoLegameId = legame['tipo_legame_id'] as int;
          if (tipoLegameId == tipoConiugeId) {
            final personaId = legame['persona_id'] as int;
            final personaCollegataId = legame['persona_collegata_id'] as int;
            if (personaId == widget.personaId) {
              coniugiIds.add(personaCollegataId);
            } else if (personaCollegataId == widget.personaId) {
              coniugiIds.add(personaId);
            }
          }
        }
      }

      // Carica anche i legami dei coniugi (per trovare i figli dei coniugi)
      final legamiConiugi = <Map<String, dynamic>>[];
      for (final coniugeId in coniugiIds) {
        final legamiConiuge = await _legameDao.getLegamiByPersonaId(coniugeId);
        legamiConiugi.addAll(legamiConiuge);
      }

      // Combina tutti i legami
      final tuttiLegami = <Map<String, dynamic>>[...legami, ...legamiConiugi];

      // Carica tutte le persone collegate
      final personaIds = <int>{};
      for (final legame in tuttiLegami) {
        final personaId = legame['persona_id'] as int;
        final personaCollegataId = legame['persona_collegata_id'] as int;
        if (personaId != widget.personaId) personaIds.add(personaId);
        if (personaCollegataId != widget.personaId) {
          personaIds.add(personaCollegataId);
        }
      }

      // Carica tutte le persone necessarie
      for (final id in personaIds) {
        final personaMap = await _personaDao.getPersonaById(id);
        if (personaMap != null) {
          _personeCache[id] = PersonaModel.fromMap(personaMap);
        }
      }

      setState(() {
        _relazioni = tuttiLegami;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Ottiene la persona collegata da un legame
  PersonaModel? _getPersonaCollegata(Map<String, dynamic> legame) {
    final personaId = legame['persona_id'] as int;
    final personaCollegataId = legame['persona_collegata_id'] as int;

    // Se la persona principale è quella corrente, restituisci la collegata
    if (personaId == widget.personaId) {
      return _personeCache[personaCollegataId];
    }
    // Altrimenti restituisci la persona principale
    return _personeCache[personaId];
  }

  /// Ottiene il tipo di legame da un legame
  TipoLegameModel? _getTipoLegame(Map<String, dynamic> legame) {
    final tipoLegameId = legame['tipo_legame_id'] as int;
    return _tipiLegameCache[tipoLegameId];
  }

  /// Ottiene l'icona per il tipo di relazione
  IconData _getIconaRelazione(String nomeRelazione) {
    switch (nomeRelazione.toLowerCase()) {
      case 'padre':
        return Icons.man;
      case 'madre':
        return Icons.woman;
      case 'figlio':
      case 'figlia':
        return Icons.child_care;
      case 'coniuge':
        return Icons.favorite;
      default:
        return Icons.people;
    }
  }

  /// Ottiene le iniziali di un nome completo
  String _getInitials(String nomeCompleto) {
    final parts = nomeCompleto.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Raggruppa le relazioni per tipo, separando padre, madre, figli e coniugi
  /// Logica basata sul modello Laravel:
  /// - Padre: persona_collegata_id = persona corrente AND tipo_legame_id = padre
  /// - Madre: persona_collegata_id = persona corrente AND tipo_legame_id = madre
  /// - Figli: persona_id = persona corrente AND (tipo_legame_id = padre OR tipo_legame_id = madre)
  /// - Coniugi: (persona_id = persona corrente OR persona_collegata_id = persona corrente) AND tipo_legame_id = coniuge
  Map<String, List<Map<String, dynamic>>> _raggruppaRelazioni() {
    final gruppi = <String, List<Map<String, dynamic>>>{
      'padre': [],
      'madre': [],
      'figlio': [],
      'coniuge': [],
    };

    final coniugiIds = <int>{}; // Per evitare duplicati nei coniugi
    final figliIds = <int>{}; // Per evitare duplicati nei figli

    // Prima passata: identifica coniugi e relazioni dirette
    for (final legame in _relazioni) {
      final personaId = legame['persona_id'] as int;
      final personaCollegataId = legame['persona_collegata_id'] as int;
      final tipoLegame = _getTipoLegame(legame);
      if (tipoLegame == null) continue;

      final nomeTipo = tipoLegame.nome.toLowerCase();

      // Gestione coniuge (bidirezionale, evita duplicati)
      if (nomeTipo == 'coniuge') {
        int? coniugeId;
        if (personaId == widget.personaId) {
          coniugeId = personaCollegataId;
        } else if (personaCollegataId == widget.personaId) {
          coniugeId = personaId;
        }
        
        if (coniugeId != null && !coniugiIds.contains(coniugeId)) {
          coniugiIds.add(coniugeId);
          gruppi['coniuge']!.add(legame);
        }
        continue;
      }

      // PADRE: persona_collegata_id = persona corrente AND tipo = padre
      if (personaCollegataId == widget.personaId && nomeTipo == 'padre') {
        gruppi['padre']!.add(legame);
        continue;
      }

      // MADRE: persona_collegata_id = persona corrente AND tipo = madre
      if (personaCollegataId == widget.personaId && nomeTipo == 'madre') {
        gruppi['madre']!.add(legame);
        continue;
      }

      // FIGLI: persona_id = persona corrente AND (tipo = padre OR tipo = madre)
      // Questo significa che la persona corrente è genitore, quindi la collegata è figlio
      if (personaId == widget.personaId && (nomeTipo == 'padre' || nomeTipo == 'madre')) {
        gruppi['figlio']!.add(legame);
        continue;
      }

      // Gestione tipo "figlio" (se esiste nel database)
      // Se tipo = figlio e persona_id = corrente, allora la collegata è genitore
      // Se tipo = figlio e persona_collegata_id = corrente, allora la principale è genitore
      if (nomeTipo == 'figlio') {
        if (personaId == widget.personaId) {
          // persona_id = corrente con tipo figlio, quindi la collegata è genitore
          // Non possiamo distinguere padre/madre, ma aggiungiamo comunque come genitore
          // Per ora lo ignoriamo perché non abbiamo una categoria "genitore"
        } else if (personaCollegataId == widget.personaId) {
          // persona_collegata_id = corrente con tipo figlio, quindi la principale è genitore
          // Questo significa che la persona corrente è figlio della principale
          // Quindi la principale è un figlio della corrente? No, è il contrario
          // In realtà se tipo=figlio e persona_collegata_id=corrente, significa che
          // la persona principale ha questa come figlio, quindi aggiungiamo come figlio
          gruppi['figlio']!.add(legame);
        }
      }
    }

    // Rimuovi gruppi vuoti
    gruppi.removeWhere((key, value) => value.isEmpty);

    return gruppi;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final gruppi = _raggruppaRelazioni();

    if (gruppi.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nessuna relazione familiare registrata'),
        ),
      );
    }

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gruppi.length,
        itemBuilder: (context, index) {
          final entry = gruppi.entries.elementAt(index);
          final nomeRelazione = entry.key;
          final legami = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _getIconaRelazione(nomeRelazione),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nomeRelazione.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${legami.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ...legami.map((legame) {
                final personaCollegata = _getPersonaCollegata(legame);
                if (personaCollegata == null) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      _getInitials(personaCollegata.nomeCompleto),
                    ),
                  ),
                  title: Text(personaCollegata.nomeCompleto),
                  subtitle: personaCollegata.natoIl != null
                      ? Text(
                          'Nato il ${personaCollegata.natoIl!.day}/${personaCollegata.natoIl!.month}/${personaCollegata.natoIl!.year}')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonaDetailScreen(
                          personaId: personaCollegata.id,
                        ),
                      ),
                    );
                  },
                );
              }),
              if (index < gruppi.length - 1)
                const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

