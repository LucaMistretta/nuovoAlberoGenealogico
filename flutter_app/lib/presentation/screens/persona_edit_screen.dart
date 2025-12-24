import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/persona_model.dart';
import '../../data/repositories/persona_repository.dart';
import '../../data/repositories/local_persona_repository.dart';

/// Schermata per modificare una persona
class PersonaEditScreen extends StatefulWidget {
  final PersonaModel? persona;
  final int? personaId;

  const PersonaEditScreen({
    super.key,
    this.persona,
    this.personaId,
  });

  @override
  State<PersonaEditScreen> createState() => _PersonaEditScreenState();
}

class _PersonaEditScreenState extends State<PersonaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final PersonaRepository _repository = LocalPersonaRepository();

  late TextEditingController _nomeController;
  late TextEditingController _cognomeController;
  late TextEditingController _natoAController;
  late TextEditingController _decedutoAController;
  DateTime? _natoIl;
  DateTime? _decedutoIl;
  bool _isLoading = false;
  PersonaModel? _persona;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _cognomeController = TextEditingController();
    _natoAController = TextEditingController();
    _decedutoAController = TextEditingController();

    if (widget.persona != null) {
      _loadPersonaData(widget.persona!);
    } else if (widget.personaId != null) {
      _loadPersonaFromId();
    }
  }

  Future<void> _loadPersonaFromId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final persona = await _repository.getPersonaById(widget.personaId!);
      if (persona != null) {
        _loadPersonaData(persona);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadPersonaData(PersonaModel persona) {
    setState(() {
      _persona = persona;
      _nomeController.text = persona.nome ?? '';
      _cognomeController.text = persona.cognome ?? '';
      _natoAController.text = persona.natoA ?? '';
      _decedutoAController.text = persona.decedutoA ?? '';
      _natoIl = persona.natoIl;
      _decedutoIl = persona.decedutoIl;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isNato) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isNato ? (_natoIl ?? DateTime.now()) : (_decedutoIl ?? DateTime.now()),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
    );

    if (picked != null) {
      setState(() {
        if (isNato) {
          _natoIl = picked;
        } else {
          _decedutoIl = picked;
        }
      });
    }
  }

  Future<void> _savePersona() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPersona = PersonaModel(
        id: _persona!.id,
        nome: _nomeController.text.trim(),
        cognome: _cognomeController.text.trim(),
        natoA: _natoAController.text.trim().isEmpty ? null : _natoAController.text.trim(),
        natoIl: _natoIl,
        decedutoA: _decedutoAController.text.trim().isEmpty ? null : _decedutoAController.text.trim(),
        decedutoIl: _decedutoIl,
        createdAt: _persona!.createdAt,
        updatedAt: DateTime.now(),
      );

      final success = await _repository.updatePersona(_persona!.id, updatedPersona);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona aggiornata con successo'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Restituisce true per indicare che è stato salvato
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nel salvataggio'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_persona == null ? 'Nuova Persona' : 'Modifica Persona'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePersona,
            ),
        ],
      ),
      body: _isLoading && _persona == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cognome
                    TextFormField(
                      controller: _cognomeController,
                      decoration: const InputDecoration(
                        labelText: 'Cognome *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il cognome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nato il
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data di nascita',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          _natoIl != null
                              ? dateFormat.format(_natoIl!)
                              : 'Seleziona data',
                          style: TextStyle(
                            color: _natoIl != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nato a
                    TextFormField(
                      controller: _natoAController,
                      decoration: const InputDecoration(
                        labelText: 'Luogo di nascita',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deceduto il
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data di morte',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                        child: Text(
                          _decedutoIl != null
                              ? dateFormat.format(_decedutoIl!)
                              : 'Seleziona data',
                          style: TextStyle(
                            color: _decedutoIl != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deceduto a
                    TextFormField(
                      controller: _decedutoAController,
                      decoration: const InputDecoration(
                        labelText: 'Luogo di morte',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pulsante salva con padding bottom per evitare che venga coperto dalle icone di navigazione
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePersona,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Salva'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _natoAController.dispose();
    _decedutoAController.dispose();
    super.dispose();
  }
}

