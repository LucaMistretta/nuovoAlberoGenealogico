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
import '../../core/database/database_helper.dart';

/// Schermata per gestire gli eventi di una persona
class PersonaEditEventiScreen extends StatefulWidget {
  final int personaId;

  const PersonaEditEventiScreen({
    super.key,
    required this.personaId,
  });

  @override
  State<PersonaEditEventiScreen> createState() =>
      _PersonaEditEventiScreenState();
}

class _PersonaEditEventiScreenState extends State<PersonaEditEventiScreen> {
  final EventoDao _eventoDao = EventoDao();
  final PersonaDao _personaDao = PersonaDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();
  final TipoLegameDao _tipoLegameDao = TipoLegameDao();
  List<EventoModel> _eventi = [];
  PersonaModel? _persona;
  bool _isLoading = true;

  final List<String> _tipiEvento = [
    'nascita',
    'battesimo',
    'comunione',
    'cresima',
    'primo_giorno_asilo',
    'primo_giorno_scuola',
    'licenza_elementare',
    'licenza_media',
    'diploma_superiore',
    'laurea',
    'matrimonio',
    'divorzio',
    'lavoro',
    'cambio_lavoro',
    'militare',
    'guerra',
    'trasloco',
    'emigrazione',
    'immigrazione',
    'malattia',
    'guarigione',
    'pensione',
    'morte',
    'sepoltura',
    'altro',
  ];

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

      // Aggiungi eventi fissi (nascita, morte, matrimonio)
      if (_persona != null) {
        await _addEventiFissi();
        
        // Ordina gli eventi per data (dal più recente al più vecchio)
        _eventi.sort((a, b) {
          if (a.dataEvento == null && b.dataEvento == null) return 0;
          if (a.dataEvento == null) return 1;
          if (b.dataEvento == null) return -1;
          return b.dataEvento!.compareTo(a.dataEvento!);
        });
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
  }

  /// Aggiunge eventi matrimonio dai legami di tipo coniuge
  Future<void> _addEventiMatrimonio() async {
    if (_persona == null) return;

    try {
      final tipiLegame = await _tipoLegameDao.getAllTipiLegame();
      TipoLegameModel? tipoConiuge;
      try {
        tipoConiuge = tipiLegame.firstWhere(
          (tipo) => tipo.nome.toLowerCase() == 'coniuge',
        );
      } catch (e) {
        return; // Tipo coniuge non trovato
      }

      final legami = await _legameDao.getLegamiByTipo(
        _persona!.id,
        tipoConiuge.id,
      );

      // Usa un Set per evitare duplicati (ci possono essere relazioni bidirezionali)
      final coniugiProcessati = <int>{};

      for (final legame in legami) {
        final personaId = legame['persona_id'] as int;
        final personaCollegataId = legame['persona_collegata_id'] as int;
        final dataLegame = legame['data_legame'] as String?;
        
        // Determina chi è il coniuge
        int? coniugeId;
        if (personaId == _persona!.id) {
          coniugeId = personaCollegataId;
        } else if (personaCollegataId == _persona!.id) {
          coniugeId = personaId;
        }

        // Evita duplicati: se abbiamo già processato questo coniuge, salta
        if (coniugeId != null && !coniugiProcessati.contains(coniugeId)) {
          coniugiProcessati.add(coniugeId);
          
          final coniugeMap = await _personaDao.getPersonaById(coniugeId);
          if (coniugeMap != null) {
            final coniuge = PersonaModel.fromMap(coniugeMap);
            final luogoLegame = legame['luogo_legame'] as String?;

            // Aggiungi solo se c'è una data di matrimonio
            if (dataLegame != null && dataLegame.isNotEmpty && dataLegame != '0') {
              try {
                // Pulisci la data rimuovendo eventuali spazi e caratteri extra
                final dataPulita = dataLegame.trim().split(' ').first;
                
                final eventoMatrimonio = EventoModel(
                  id: -1000 - coniugeId, // ID negativo univoco
                  personaId: _persona!.id,
                  tipoEvento: 'matrimonio',
                  titolo: 'Matrimonio con ${coniuge.nomeCompleto}',
                  descrizione: luogoLegame != null && luogoLegame.isNotEmpty && luogoLegame != '0'
                      ? 'A ${luogoLegame}'
                      : null,
                  dataEvento: DateTime.parse(dataPulita),
                  luogo: luogoLegame != null && luogoLegame != '0' ? luogoLegame : null,
                );
                _eventi.add(eventoMatrimonio);
              } catch (e) {
                // Se il parsing della data fallisce, ignora questo evento
                debugPrint('Errore nel parsing della data matrimonio: $dataLegame - $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Errore in _addEventiMatrimonio: $e');
    }
  }

  Future<void> _addEvento() async {
    final result = await Navigator.push<EventoModel>(
      context,
      MaterialPageRoute(
        builder: (_) => _EventoEditDialog(
          personaId: widget.personaId,
          tipiEvento: _tipiEvento,
        ),
      ),
    );

    if (result != null) {
      await _loadEventi();
    }
  }

  Future<void> _editEvento(EventoModel evento) async {
    // Gli eventi fissi (con ID negativo) non possono essere modificati
    if (evento.id < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gli eventi fissi (nascita, morte, matrimonio) non possono essere modificati qui. Modificali dalla sezione Informazioni.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push<EventoModel>(
      context,
      MaterialPageRoute(
        builder: (_) => _EventoEditDialog(
          personaId: widget.personaId,
          tipiEvento: _tipiEvento,
          evento: evento,
        ),
      ),
    );

    if (result != null) {
      await _loadEventi();
    }
  }

  Future<void> _deleteEvento(EventoModel evento) async {
    // Gli eventi fissi (con ID negativo) non possono essere eliminati
    if (evento.id < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gli eventi fissi (nascita, morte, matrimonio) non possono essere eliminati.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Evento'),
        content: const Text('Sei sicuro di voler eliminare questo evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete(
          'eventi',
          where: 'id = ?',
          whereArgs: [evento.id],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento eliminato con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadEventi();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'eliminazione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _eventi.isEmpty
                      ? const Center(
                          child: Text('Nessun evento registrato'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _eventi.length,
                          itemBuilder: (context, index) {
                            final evento = _eventi[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(_getIconaEvento(evento.tipoEvento)),
                                title: Text(
                                  evento.titolo,
                                  style: TextStyle(
                                    fontWeight: evento.id < 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (evento.dataEvento != null)
                                      Text('Data: ${dateFormat.format(evento.dataEvento!)}'),
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
                                    if (evento.id < 0)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Evento fisso - Modifica dalla sezione Informazioni',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: evento.id < 0
                                    ? const Chip(
                                        label: Text('Fisso'),
                                        backgroundColor: Colors.blue,
                                        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _editEvento(evento),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteEvento(evento),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _addEvento,
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi Evento'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  IconData _getIconaEvento(String tipoEvento) {
    switch (tipoEvento.toLowerCase()) {
      case 'nascita':
        return Icons.child_care;
      case 'morte':
        return Icons.place;
      case 'matrimonio':
        return Icons.favorite;
      default:
        return Icons.event;
    }
  }
}

/// Dialog per aggiungere/modificare un evento
class _EventoEditDialog extends StatefulWidget {
  final int personaId;
  final List<String> tipiEvento;
  final EventoModel? evento;

  const _EventoEditDialog({
    required this.personaId,
    required this.tipiEvento,
    this.evento,
  });

  @override
  State<_EventoEditDialog> createState() => _EventoEditDialogState();
}

class _EventoEditDialogState extends State<_EventoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titoloController;
  late TextEditingController _descrizioneController;
  late TextEditingController _luogoController;
  late TextEditingController _noteController;
  String? _tipoEvento;
  DateTime? _dataEvento;

  @override
  void initState() {
    super.initState();
    _titoloController = TextEditingController(text: widget.evento?.titolo ?? '');
    _descrizioneController =
        TextEditingController(text: widget.evento?.descrizione ?? '');
    _luogoController = TextEditingController(text: widget.evento?.luogo ?? '');
    _noteController = TextEditingController(text: widget.evento?.note ?? '');
    _tipoEvento = widget.evento?.tipoEvento;
    _dataEvento = widget.evento?.dataEvento;
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _descrizioneController.dispose();
    _luogoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona un tipo di evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      final eventoData = {
        'persona_id': widget.personaId,
        'tipo_evento': _tipoEvento!,
        'titolo': _titoloController.text.trim(),
        'descrizione': _descrizioneController.text.trim().isEmpty
            ? null
            : _descrizioneController.text.trim(),
        'data_evento': _dataEvento?.toIso8601String().split('T')[0],
        'luogo': _luogoController.text.trim().isEmpty
            ? null
            : _luogoController.text.trim(),
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'updated_at': now,
      };

      if (widget.evento != null) {
        // Aggiorna evento esistente
        await db.update(
          'eventi',
          eventoData,
          where: 'id = ?',
          whereArgs: [widget.evento!.id],
        );
      } else {
        // Crea nuovo evento
        eventoData['created_at'] = now;
        await db.insert('eventi', eventoData);
      }

      if (mounted) {
        Navigator.of(context).pop(EventoModel(
          id: widget.evento?.id ?? 0,
          personaId: widget.personaId,
          tipoEvento: _tipoEvento!,
          titolo: _titoloController.text.trim(),
          descrizione: _descrizioneController.text.trim().isEmpty
              ? null
              : _descrizioneController.text.trim(),
          dataEvento: _dataEvento,
          luogo: _luogoController.text.trim().isEmpty
              ? null
              : _luogoController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.evento == null ? 'Nuovo Evento' : 'Modifica Evento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo evento
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo Evento *',
                  border: OutlineInputBorder(),
                ),
                value: _tipoEvento,
                items: widget.tipiEvento.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTipoEventoLabel(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoEvento = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleziona un tipo di evento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Titolo
              TextFormField(
                controller: _titoloController,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Data evento
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataEvento ?? DateTime.now(),
                    firstDate: DateTime(1800),
                    lastDate: DateTime.now(),
                    locale: const Locale('it', 'IT'),
                  );
                  if (picked != null) {
                    setState(() {
                      _dataEvento = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Evento',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dataEvento != null
                        ? dateFormat.format(_dataEvento!)
                        : 'Seleziona data',
                    style: TextStyle(
                      color: _dataEvento != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Luogo
              TextFormField(
                controller: _luogoController,
                decoration: const InputDecoration(
                  labelText: 'Luogo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Descrizione
              TextFormField(
                controller: _descrizioneController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  String _getTipoEventoLabel(String tipo) {
    final labels = {
      'nascita': 'Nascita',
      'battesimo': 'Battesimo',
      'comunione': 'Comunione',
      'cresima': 'Cresima',
      'primo_giorno_asilo': 'Primo Giorno di Asilo',
      'primo_giorno_scuola': 'Primo Giorno di Scuola',
      'licenza_elementare': 'Licenza Elementare',
      'licenza_media': 'Licenza Media',
      'diploma_superiore': 'Diploma Superiore',
      'laurea': 'Laurea',
      'matrimonio': 'Matrimonio',
      'divorzio': 'Divorzio',
      'lavoro': 'Lavoro',
      'cambio_lavoro': 'Cambio Lavoro',
      'militare': 'Servizio Militare',
      'guerra': 'Guerra',
      'trasloco': 'Trasloco',
      'emigrazione': 'Emigrazione',
      'immigrazione': 'Immigrazione',
      'malattia': 'Malattia',
      'guarigione': 'Guarigione',
      'pensione': 'Pensione',
      'morte': 'Morte',
      'sepoltura': 'Sepoltura',
      'altro': 'Altro',
    };
    return labels[tipo] ?? tipo;
  }
}

