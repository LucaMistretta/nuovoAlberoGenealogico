import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/tag_model.dart';
import '../../data/local/tag_dao.dart';

/// Schermata per gestire i tag di una persona
class PersonaEditTagScreen extends StatefulWidget {
  final int personaId;
  final String personaNome;

  const PersonaEditTagScreen({
    super.key,
    required this.personaId,
    required this.personaNome,
  });

  @override
  State<PersonaEditTagScreen> createState() => _PersonaEditTagScreenState();
}

class _PersonaEditTagScreenState extends State<PersonaEditTagScreen> {
  final TagDao _tagDao = TagDao();
  List<TagModel> _allTags = [];
  List<TagModel> _personaTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allTagsMaps = await _tagDao.getAllTags();
      final personaTagsMaps = await _tagDao.getTagsByPersonaId(widget.personaId);
      
      setState(() {
        _allTags = allTagsMaps.map((map) => TagModel.fromMap(map)).toList();
        _personaTags = personaTagsMaps.map((map) => TagModel.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento dei tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTag() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _TagDialog(),
    );

    if (result != null) {
      try {
        await _tagDao.insertTag(
          nome: result['nome']!,
          colore: result['colore'],
          descrizione: result['descrizione'],
        );
        _loadTags();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag creato con successo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nella creazione del tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _attachTag(TagModel tag) async {
    try {
      await _tagDao.attachToPersona(widget.personaId, tag.id);
      _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "${tag.nome}" associato'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'associazione del tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _detachTag(TagModel tag) async {
    try {
      await _tagDao.detachFromPersona(widget.personaId, tag.id);
      _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "${tag.nome}" rimosso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella rimozione del tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final personaTagIds = _personaTags.map((t) => t.id).toSet();
    final availableTags = _allTags.where((t) => !personaTagIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tag - ${widget.personaNome}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTags,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag associati alla persona
                    if (_personaTags.isNotEmpty) ...[
                      const Text(
                        'Tag Associati',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _personaTags.map((tag) {
                          return Chip(
                            label: Text(tag.nome),
                            backgroundColor: _parseColor(tag.colore).withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _detachTag(tag),
                            labelStyle: TextStyle(
                              color: _parseColor(tag.colore),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Tag disponibili
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tag Disponibili',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _createTag,
                          icon: const Icon(Icons.add),
                          label: const Text('Crea Tag'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (availableTags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Nessun tag disponibile. Crea un nuovo tag per iniziare.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTags.map((tag) {
                          return ActionChip(
                            label: Text(tag.nome),
                            backgroundColor: _parseColor(tag.colore).withOpacity(0.1),
                            onPressed: () => _attachTag(tag),
                            labelStyle: TextStyle(
                              color: _parseColor(tag.colore),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Dialog per creare un nuovo tag
class _TagDialog extends StatefulWidget {
  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final _nomeController = TextEditingController();
  final _descrizioneController = TextEditingController();
  String _colore = '#3b82f6';

  final List<String> _coloriPredefiniti = [
    '#3b82f6', // blue
    '#10b981', // green
    '#f59e0b', // amber
    '#ef4444', // red
    '#8b5cf6', // purple
    '#ec4899', // pink
    '#06b6d4', // cyan
    '#84cc16', // lime
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crea Nuovo Tag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome Tag',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descrizioneController,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Colore:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _coloriPredefiniti.map((colore) {
                final isSelected = _colore == colore;
                return GestureDetector(
                  onTap: () => setState(() => _colore = colore),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(colore.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
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
          onPressed: _nomeController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop({
                    'nome': _nomeController.text.trim(),
                    'colore': _colore,
                    'descrizione': _descrizioneController.text.trim().isEmpty
                        ? null
                        : _descrizioneController.text.trim(),
                  }),
          child: const Text('Crea'),
        ),
      ],
    );
  }
}

