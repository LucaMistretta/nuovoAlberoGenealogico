import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/models/persona_model.dart';
import '../../services/image_service.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/media_model.dart';
import '../../data/models/tipo_legame_model.dart';
import '../../data/local/evento_dao.dart';
import '../../data/local/media_dao.dart';
import '../../data/local/persona_legame_dao.dart';
import '../../data/local/persona_dao.dart';
import '../../data/local/tipo_legame_dao.dart';
import '../widgets/persona_avatar.dart';
import '../widgets/relazioni_familiari_widget.dart';
import '../providers/persone_provider.dart';
import 'eventi_list_screen.dart';
import 'media_gallery_screen.dart';
import 'persona_edit_complete_screen.dart';

/// Schermata dettaglio persona con tutte le informazioni
class PersonaDetailScreen extends StatefulWidget {
  final int personaId;

  const PersonaDetailScreen({
    super.key,
    required this.personaId,
  });

  @override
  State<PersonaDetailScreen> createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  PersonaModel? _persona;
  List<EventoModel> _eventi = [];
  List<MediaModel> _media = [];
  bool _isLoading = true;
  String? _error;

  final EventoDao _eventoDao = EventoDao();
  final MediaDao _mediaDao = MediaDao();
  final PersonaLegameDao _legameDao = PersonaLegameDao();
  final PersonaDao _personaDao = PersonaDao();
  final TipoLegameDao _tipoLegameDao = TipoLegameDao();

  @override
  void initState() {
    super.initState();
    _loadPersonaData();
  }

  /// Carica tutti i dati della persona
  Future<void> _loadPersonaData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<PersoneProvider>();
      _persona = await provider.getPersonaById(widget.personaId);

      if (_persona != null) {
        // Carica eventi
        final eventiMaps = await _eventoDao.getEventiByPersonaId(_persona!.id);
        _eventi = eventiMaps.map((map) => EventoModel.fromMap(map)).toList();

        // Aggiungi eventi fissi (nascita, morte, matrimonio)
        await _addEventiFissi();
        
        // Ordina gli eventi per data (dal più recente al più vecchio)
        _eventi.sort((a, b) {
          if (a.dataEvento == null && b.dataEvento == null) return 0;
          if (a.dataEvento == null) return 1;
          if (b.dataEvento == null) return -1;
          return b.dataEvento!.compareTo(a.dataEvento!);
        });
        
        debugPrint('Eventi dopo ordinamento (primi 5):');
        for (int i = 0; i < _eventi.length && i < 5; i++) {
          final evento = _eventi[i];
          debugPrint('  [$i] ${evento.titolo} - ${evento.dataEvento} - tipo: ${evento.tipoEvento}');
        }

        // Carica media
        final mediaMaps = await _mediaDao.getMediaByPersonaId(_persona!.id);
        _media = mediaMaps.map((map) => MediaModel.fromMap(map)).toList();
      }
    } catch (e) {
      _error = 'Errore nel caricamento dei dati: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _persona == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dettaglio Persona')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Persona non trovata'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Indietro'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_persona!.nomeCompleto),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade700,
                    ],
                  ),
                ),
                child: Center(
                  child: PersonaAvatar(
                    nomeCompleto: _persona!.nomeCompleto,
                    radius: 60,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonaEditCompleteScreen(persona: _persona!),
                    ),
                  );
                  // Ricarica i dati se è stato salvato qualcosa
                  if (result == true) {
                    _loadPersonaData();
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informazioni base
                  _buildSectionTitle('Informazioni'),
                  _buildInfoCard([
                    if (_persona!.natoIl != null)
                      _buildInfoRow(
                        Icons.cake,
                        'Nato il',
                        dateFormat.format(_persona!.natoIl!),
                      ),
                    if (_persona!.natoA != null)
                      _buildInfoRow(
                        Icons.place,
                        'Nato a',
                        _persona!.natoA!,
                      ),
                    if (_persona!.decedutoIl != null)
                      _buildInfoRow(
                        Icons.place,
                        'Deceduto il',
                        dateFormat.format(_persona!.decedutoIl!),
                        color: Colors.red,
                      ),
                    if (_persona!.decedutoA != null)
                      _buildInfoRow(
                        Icons.place,
                        'Deceduto a',
                        _persona!.decedutoA!,
                      ),
                  ]),

                  const SizedBox(height: 16),

                  // Eventi
                  _buildSectionTitle('Eventi (${_eventi.length})'),
                  if (_eventi.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nessun evento registrato'),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: _eventi.take(3).map((evento) {
                          return ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(evento.titolo),
                            subtitle: evento.dataEvento != null
                                ? Text(dateFormat.format(evento.dataEvento!))
                                : null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventiListScreen(
                                    personaId: _persona!.id,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  if (_eventi.length > 3)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventiListScreen(
                              personaId: _persona!.id,
                            ),
                          ),
                        );
                      },
                      child: const Text('Vedi tutti gli eventi'),
                    ),

                  const SizedBox(height: 16),

                  // Media
                  _buildSectionTitle('Media (${_media.length})'),
                  if (_media.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nessun media disponibile'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _media.length,
                        itemBuilder: (context, index) {
                          final media = _media[index];
                          final imageService = ImageService();
                          final relativePath = imageService.getRelativePathFromLaravelPath(media.percorso);
                          final nomeFilePath = 'media/persona_${media.personaId}/${media.nomeFile}';
                          
                          // Prova prima con il percorso dal database, poi con il nome file originale
                          Future<File?> getImageFile() async {
                            var file = await imageService.getImageFile(relativePath);
                            if (file != null) return file;
                            return await imageService.getImageFile(nomeFilePath);
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Card(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MediaGalleryScreen(
                                        personaId: _persona!.id,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  child: FutureBuilder<File?>(
                                    future: getImageFile(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return Image.file(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  media.isFoto
                                                      ? Icons.photo
                                                      : Icons.description,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  media.nomeFile,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            media.isFoto
                                                ? Icons.photo
                                                : Icons.description,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            media.nomeFile,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Relazioni familiari
                  _buildSectionTitle('Relazioni Familiari'),
                  RelazioniFamiliariWidget(personaId: _persona!.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aggiunge eventi fissi (nascita, morte, matrimonio) alla lista
  Future<void> _addEventiFissi() async {
    if (_persona == null) {
      debugPrint('_addEventiFissi: _persona è null');
      return;
    }

    debugPrint('_addEventiFissi: Inizio per persona ${_persona!.id} (${_persona!.nomeCompleto})');
    debugPrint('Eventi prima di aggiungere fissi: ${_eventi.length}');

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
      debugPrint('Aggiunto evento nascita');
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
      debugPrint('Aggiunto evento morte');
    }

    // Evento matrimonio (cerca nei legami)
    debugPrint('Chiamando _addEventiMatrimonio...');
    await _addEventiMatrimonio();
    debugPrint('_addEventiMatrimonio completato. Totale eventi: ${_eventi.length}');
    debugPrint('Eventi matrimonio: ${_eventi.where((e) => e.tipoEvento == 'matrimonio').map((e) => e.titolo).join(', ')}');
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
        debugPrint('Tipo coniuge non trovato');
        return; // Tipo coniuge non trovato
      }

      debugPrint('Cercando legami coniuge per persona ${_persona!.id}, tipo ${tipoConiuge.id}');
      final legami = await _legameDao.getLegamiByTipo(
        _persona!.id,
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
        if (personaId == _persona!.id) {
          coniugeId = personaCollegataId;
        } else if (personaCollegataId == _persona!.id) {
          coniugeId = personaId;
        }

        debugPrint('Coniuge determinato: $coniugeId (persona corrente: ${_persona!.id})');

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
}

