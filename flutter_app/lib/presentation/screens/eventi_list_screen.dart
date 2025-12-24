import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/persona_model.dart';
import '../../data/models/tipo_legame_model.dart';
import '../../data/local/evento_dao.dart';
import '../../data/local/persona_dao.dart';
import '../../data/local/persona_legame_dao.dart';
import '../../data/local/tipo_legame_dao.dart';

/// Schermata lista eventi di una persona
class EventiListScreen extends StatefulWidget {
  final int personaId;

  const EventiListScreen({
    super.key,
    required this.personaId,
  });

  @override
  State<EventiListScreen> createState() => _EventiListScreenState();
}

class _EventiListScreenState extends State<EventiListScreen> {
  final EventoDao _eventoDao = EventoDao();
  final PersonaDao _personaDao = PersonaDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();
  final TipoLegameDao _tipoLegameDao = TipoLegameDao();
  
  List<EventoModel> _eventi = [];
  PersonaModel? _persona;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventi();
  }

  Future<void> _loadEventi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica la persona
      final personaMap = await _personaDao.getPersonaById(widget.personaId);
      if (personaMap != null) {
        _persona = PersonaModel.fromMap(personaMap);
      }

      // Carica gli eventi dal database
      final eventiMaps = await _eventoDao.getEventiByPersonaId(widget.personaId);
      _eventi = eventiMaps.map((map) => EventoModel.fromMap(map)).toList();

      // Aggiungi eventi fissi se la persona esiste
      if (_persona != null) {
        await _addEventiFissi();
        
        // Ordina gli eventi per data (dal più recente al più vecchio)
        _eventi.sort((a, b) {
          if (a.dataEvento == null && b.dataEvento == null) return 0;
          if (a.dataEvento == null) return 1;
          if (b.dataEvento == null) return -1;
          return b.dataEvento!.compareTo(a.dataEvento!);
        });
        
        debugPrint('Eventi dopo ordinamento (primi 10):');
        for (int i = 0; i < _eventi.length && i < 10; i++) {
          final evento = _eventi[i];
          debugPrint('  [$i] ${evento.titolo} - ${evento.dataEvento} - tipo: ${evento.tipoEvento} - id: ${evento.id}');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Aggiunge eventi fissi (nascita, morte, matrimonio) alla lista
  Future<void> _addEventiFissi() async {
    if (_persona == null) return;

    // Evento nascita
    if (_persona!.natoIl != null) {
      final eventoNascita = EventoModel(
        id: -1, // ID negativo per distinguere dagli eventi reali
        personaId: _persona!.id,
        tipoEvento: 'nascita',
        titolo: 'Nascita',
        descrizione: _persona!.natoA != null ? 'Nato a ${_persona!.natoA!}' : null,
        dataEvento: _persona!.natoIl,
        luogo: _persona!.natoA,
      );
      _eventi.insert(0, eventoNascita);
    }

    // Evento morte
    if (_persona!.decedutoIl != null) {
      final eventoMorte = EventoModel(
        id: -2,
        personaId: _persona!.id,
        tipoEvento: 'morte',
        titolo: 'Morte',
        descrizione: _persona!.decedutoA != null ? 'Deceduto a ${_persona!.decedutoA!}' : null,
        dataEvento: _persona!.decedutoIl,
        luogo: _persona!.decedutoA,
      );
      _eventi.add(eventoMorte);
    }

    // Evento matrimonio (cerca nei legami)
    await _addEventiMatrimonio();
    
    debugPrint('_addEventiMatrimonio completato. Totale eventi: ${_eventi.length}');
    debugPrint('Eventi matrimonio: ${_eventi.where((e) => e.tipoEvento == 'matrimonio').map((e) => e.titolo).join(', ')}');
  }

  /// Aggiunge eventi matrimonio dai legami di tipo coniuge
  Future<void> _addEventiMatrimonio() async {
    try {
      final tipiLegame = await _tipoLegameDao.getAllTipiLegame();
      TipoLegameModel? tipoConiuge;
      try {
        tipoConiuge = tipiLegame.firstWhere(
          (tipo) => tipo.nome.toLowerCase() == 'coniuge',
        );
      } catch (e) {
        debugPrint('Tipo coniuge non trovato');
        return;
      }

      debugPrint('Cercando legami coniuge per persona ${widget.personaId}, tipo ${tipoConiuge.id}');
      final legami = await _legameDao.getLegamiByTipo(
        widget.personaId,
        tipoConiuge.id,
      );
      debugPrint('Trovati ${legami.length} legami coniuge');

      // Usa un Set per evitare duplicati (ci possono essere relazioni bidirezionali)
      final coniugiProcessati = <int>{};

      for (final legame in legami) {
        final personaId = legame['persona_id'] as int;
        final personaCollegataId = legame['persona_collegata_id'] as int;
        final dataLegame = legame['data_legame'] as String?;
        
        debugPrint('Legame: persona_id=$personaId, persona_collegata_id=$personaCollegataId, data_legame=$dataLegame');
        
        // Determina chi è il coniuge
        int? coniugeId;
        if (personaId == widget.personaId) {
          coniugeId = personaCollegataId;
        } else if (personaCollegataId == widget.personaId) {
          coniugeId = personaId;
        }

        debugPrint('Coniuge determinato: $coniugeId (persona corrente: ${widget.personaId})');

        // Evita duplicati: se abbiamo già processato questo coniuge, salta
        if (coniugeId != null && !coniugiProcessati.contains(coniugeId)) {
          coniugiProcessati.add(coniugeId);
          
          final coniugeMap = await _personaDao.getPersonaById(coniugeId);
          if (coniugeMap != null) {
            final coniuge = PersonaModel.fromMap(coniugeMap);
            final luogoLegame = legame['luogo_legame'] as String?;

            debugPrint('Processando matrimonio con ${coniuge.nomeCompleto}, data: $dataLegame');

            // Aggiungi solo se c'è una data di matrimonio
            if (dataLegame != null && dataLegame.isNotEmpty && dataLegame != '0') {
              try {
                // Pulisci la data rimuovendo eventuali spazi e caratteri extra
                final dataPulita = dataLegame.trim().split(' ').first;
                debugPrint('Data pulita: $dataPulita');
                
                final eventoMatrimonio = EventoModel(
                  id: -1000 - coniugeId, // ID negativo univoco
                  personaId: widget.personaId,
                  tipoEvento: 'matrimonio',
                  titolo: 'Matrimonio con ${coniuge.nomeCompleto}',
                  descrizione: luogoLegame != null && luogoLegame.isNotEmpty && luogoLegame != '0'
                      ? 'A ${luogoLegame}'
                      : null,
                  dataEvento: DateTime.parse(dataPulita),
                  luogo: luogoLegame != null && luogoLegame != '0' ? luogoLegame : null,
                );
                _eventi.add(eventoMatrimonio);
                debugPrint('Evento matrimonio aggiunto: ${eventoMatrimonio.titolo}');
              } catch (e) {
                // Se il parsing della data fallisce, ignora questo evento
                debugPrint('Errore nel parsing della data matrimonio: $dataLegame - $e');
              }
            } else {
              debugPrint('Data matrimonio non valida: $dataLegame');
            }
          } else {
            debugPrint('Coniuge con ID $coniugeId non trovato nel database');
          }
        } else {
          debugPrint('Coniuge $coniugeId già processato o null');
        }
      }
      
      debugPrint('Totale eventi matrimonio aggiunti: ${_eventi.where((e) => e.tipoEvento == 'matrimonio').length}');
    } catch (e) {
      debugPrint('Errore in _addEventiMatrimonio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eventi.isEmpty
              ? const Center(
                  child: Text('Nessun evento registrato'),
                )
              : ListView.builder(
                  itemCount: _eventi.length,
                  itemBuilder: (context, index) {
                    final evento = _eventi[index];
                    final isEventoFisso = evento.id < 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getIconaEvento(evento.tipoEvento),
                          color: isEventoFisso ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          evento.titolo,
                          style: TextStyle(
                            fontWeight: isEventoFisso ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (evento.dataEvento != null)
                              Text(
                                'Data: ${dateFormat.format(evento.dataEvento!)}',
                              ),
                            if (evento.luogo != null)
                              Text('Luogo: ${evento.luogo}'),
                            if (evento.descrizione != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  evento.descrizione!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (isEventoFisso)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Evento fisso',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isEventoFisso
                            ? null
                            : const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
    );
  }

  /// Ottiene l'icona per il tipo di evento
  IconData _getIconaEvento(String tipoEvento) {
    switch (tipoEvento.toLowerCase()) {
      case 'nascita':
        return Icons.child_care;
      case 'morte':
        return Icons.place;
      case 'matrimonio':
        return Icons.favorite;
      case 'battesimo':
        return Icons.water_drop;
      case 'comunione':
      case 'cresima':
        return Icons.church;
      case 'laurea':
        return Icons.school;
      case 'lavoro':
      case 'cambio_lavoro':
        return Icons.work;
      case 'militare':
        return Icons.military_tech;
      case 'guerra':
        return Icons.warning;
      case 'trasloco':
        return Icons.home;
      case 'emigrazione':
      case 'immigrazione':
        return Icons.flight;
      case 'malattia':
        return Icons.local_hospital;
      case 'guarigione':
        return Icons.healing;
      case 'pensione':
        return Icons.work_off;
      case 'sepoltura':
        return Icons.place;
      default:
        return Icons.event;
    }
  }
}

