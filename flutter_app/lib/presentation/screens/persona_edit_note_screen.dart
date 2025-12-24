import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/nota_model.dart';
import '../../data/local/nota_dao.dart';

/// Schermata per gestire le note di una persona
class PersonaEditNoteScreen extends StatefulWidget {
  final int personaId;
  final String personaNome;

  const PersonaEditNoteScreen({
    super.key,
    required this.personaId,
    required this.personaNome,
  });

  @override
  State<PersonaEditNoteScreen> createState() => _PersonaEditNoteScreenState();
}

class _PersonaEditNoteScreenState extends State<PersonaEditNoteScreen> {
  final NotaDao _notaDao = NotaDao();
  List<NotaModel> _note = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteMaps = await _notaDao.getNoteByPersonaId(widget.personaId);
      setState(() {
        _note = noteMaps.map((map) => NotaModel.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNota() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NotaDialog(),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _notaDao.insertNota(
          personaId: widget.personaId,
          contenuto: result,
        );
        _loadNote();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nota aggiunta con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'aggiunta della nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editNota(NotaModel nota) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NotaDialog(contenutoIniziale: nota.contenuto),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _notaDao.updateNota(
          id: nota.id,
          contenuto: result,
        );
        _loadNote();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nota aggiornata con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'aggiornamento della nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteNota(NotaModel nota) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Nota'),
        content: const Text('Sei sicuro di voler eliminare questa nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _notaDao.deleteNota(nota.id);
        _loadNote();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nota eliminata con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nell\'eliminazione della nota: $e'),
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
      appBar: AppBar(
        title: Text('Note - ${widget.personaNome}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNote,
              child: _note.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna nota presente',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _note.length,
                      itemBuilder: (context, index) {
                        final nota = _note[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              nota.contenuto,
                              style: const TextStyle(fontSize: 16),
                            ),
                            subtitle: nota.createdAt != null
                                ? Text(
                                    'Creata il ${DateFormat('dd/MM/yyyy HH:mm').format(nota.createdAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editNota(nota),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteNota(nota),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNota,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Dialog per inserire/modificare una nota
class _NotaDialog extends StatefulWidget {
  final String? contenutoIniziale;

  const _NotaDialog({this.contenutoIniziale});

  @override
  State<_NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<_NotaDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contenutoIniziale != null) {
      _controller.text = widget.contenutoIniziale!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contenutoIniziale == null ? 'Nuova Nota' : 'Modifica Nota'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Inserisci il contenuto della nota...',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

