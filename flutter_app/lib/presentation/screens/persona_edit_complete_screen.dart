import 'package:flutter/material.dart';
import '../../data/models/persona_model.dart';
import 'persona_edit_screen.dart';
import 'persona_edit_relazioni_screen.dart';
import 'persona_edit_eventi_screen.dart';
import 'persona_edit_media_screen.dart';
import 'persona_edit_note_screen.dart';
import 'persona_edit_tag_screen.dart';

/// Schermata completa di modifica persona con tabs per tutte le sezioni
class PersonaEditCompleteScreen extends StatefulWidget {
  final PersonaModel persona;

  const PersonaEditCompleteScreen({
    super.key,
    required this.persona,
  });

  @override
  State<PersonaEditCompleteScreen> createState() =>
      _PersonaEditCompleteScreenState();
}

class _PersonaEditCompleteScreenState extends State<PersonaEditCompleteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PersonaModel? _persona;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _persona = widget.persona;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_persona == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica: ${_persona!.nomeCompleto}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Informazioni'),
                Tab(icon: Icon(Icons.people), text: 'Relazioni'),
                Tab(icon: Icon(Icons.event), text: 'Eventi'),
                Tab(icon: Icon(Icons.photo_library), text: 'Media'),
                Tab(icon: Icon(Icons.note), text: 'Note'),
                Tab(icon: Icon(Icons.label), text: 'Tag'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Informazioni
          PersonaEditScreen(
            persona: _persona,
          ),
          // Tab Relazioni
          PersonaEditRelazioniScreen(
            personaId: _persona!.id,
          ),
          // Tab Eventi
          PersonaEditEventiScreen(
            personaId: _persona!.id,
          ),
          // Tab Media
          PersonaEditMediaScreen(
            personaId: _persona!.id,
          ),
          // Tab Note
          PersonaEditNoteScreen(
            personaId: _persona!.id,
            personaNome: _persona!.nomeCompleto,
          ),
          // Tab Tag
          PersonaEditTagScreen(
            personaId: _persona!.id,
            personaNome: _persona!.nomeCompleto,
          ),
        ],
      ),
    );
  }
}

