import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/persona_model.dart';
import '../../data/models/tipo_legame_model.dart';
import '../../data/local/persona_dao.dart';
import '../../data/local/persona_legame_dao.dart';
import '../../data/local/tipo_legame_dao.dart';
import '../../core/database/database_helper.dart';
import '../widgets/relazioni_familiari_widget.dart';

/// Schermata per gestire le relazioni familiari di una persona
class PersonaEditRelazioniScreen extends StatefulWidget {
  final int personaId;

  const PersonaEditRelazioniScreen({
    super.key,
    required this.personaId,
  });

  @override
  State<PersonaEditRelazioniScreen> createState() =>
      _PersonaEditRelazioniScreenState();
}

class _PersonaEditRelazioniScreenState
    extends State<PersonaEditRelazioniScreen> {
  final PersonaDao _personaDao = PersonaDao();
  final TipoLegameDao _tipoLegameDao = TipoLegameDao();

  List<PersonaModel> _persone = [];
  List<TipoLegameModel> _tipiLegame = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica tutte le persone
      final personeMaps = await _personaDao.getAllPersone();
      _persone = personeMaps.map((map) => PersonaModel.fromMap(map)).toList();

      // Carica tutti i tipi di legame
      _tipiLegame = await _tipoLegameDao.getAllTipiLegame();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addRelazione() async {
    // Mostra dialog per selezionare persona e tipo di relazione
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RelazioneDialog(
        persone: _persone,
        tipiLegame: _tipiLegame,
        personaId: widget.personaId,
      ),
    );

    if (result != null) {
      // Aggiungi la relazione
      try {
        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;
        await db.insert(
          'persona_legami',
          {
            'persona_id': result['persona_id'] as int,
            'persona_collegata_id': result['persona_collegata_id'] as int,
            'tipo_legame_id': result['tipo_legame_id'] as int,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        
        // Ricarica i dati
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Relazione aggiunta con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'aggiunta della relazione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista relazioni esistenti
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: SingleChildScrollView(
                      child: RelazioniFamiliariWidget(
                        personaId: widget.personaId,
                        key: ValueKey(widget.personaId),
                      ),
                    ),
                  ),
                ),
                // Bottone aggiungi relazione
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _addRelazione,
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi Relazione'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Dialog per selezionare persona e tipo di relazione
class _RelazioneDialog extends StatefulWidget {
  final List<PersonaModel> persone;
  final List<TipoLegameModel> tipiLegame;
  final int personaId;

  const _RelazioneDialog({
    required this.persone,
    required this.tipiLegame,
    required this.personaId,
  });

  @override
  State<_RelazioneDialog> createState() => _RelazioneDialogState();
}

class _RelazioneDialogState extends State<_RelazioneDialog> {
  PersonaModel? _personaSelezionata;
  TipoLegameModel? _tipoSelezionato;
  bool _personaIsMain = true; // true = persona_id, false = persona_collegata_id

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi Relazione'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selezione persona
            DropdownButtonFormField<PersonaModel>(
              decoration: const InputDecoration(
                labelText: 'Persona',
                border: OutlineInputBorder(),
              ),
              items: widget.persone
                  .where((p) => p.id != widget.personaId)
                  .map((persona) {
                return DropdownMenuItem(
                  value: persona,
                  child: Text(persona.nomeCompleto),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _personaSelezionata = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Selezione tipo relazione
            DropdownButtonFormField<TipoLegameModel>(
              decoration: const InputDecoration(
                labelText: 'Tipo di Relazione',
                border: OutlineInputBorder(),
              ),
              items: widget.tipiLegame.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo.nome),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoSelezionato = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Checkbox per direzione relazione
            CheckboxListTile(
              title: const Text('Persona corrente è principale'),
              subtitle: const Text(
                  'Se deselezionato, la persona corrente sarà quella collegata'),
              value: _personaIsMain,
              onChanged: (value) {
                setState(() {
                  _personaIsMain = value ?? true;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _personaSelezionata != null && _tipoSelezionato != null
              ? () {
                  Navigator.of(context).pop({
                    'persona_id': _personaIsMain
                        ? widget.personaId
                        : _personaSelezionata!.id,
                    'persona_collegata_id': _personaIsMain
                        ? _personaSelezionata!.id
                        : widget.personaId,
                    'tipo_legame_id': _tipoSelezionato!.id,
                  });
                }
              : null,
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

