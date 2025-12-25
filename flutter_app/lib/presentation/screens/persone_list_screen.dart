import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/persone_provider.dart';
import '../widgets/persona_card.dart';
import 'login_screen.dart';
import 'persona_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/image_initializer.dart';
import '../../core/utils/setup_images.dart';
import 'sync_screen.dart';
import '../../services/connection_service.dart';

/// Schermata principale con la lista delle persone
class PersoneListScreen extends StatefulWidget {
  const PersoneListScreen({super.key});

  @override
  State<PersoneListScreen> createState() => _PersoneListScreenState();
}

class _PersoneListScreenState extends State<PersoneListScreen> {
  final _searchController = TextEditingController();
  final _connectionService = ConnectionService();
  bool _isConnected = false;
  bool _isCheckingConnection = false;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    // Carica le persone quando la schermata viene inizializzata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
      _checkConnection();
      // Controlla la connessione ogni 30 secondi
      _connectionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _checkConnection();
      });
    });
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Verifica la connessione al server
  Future<void> _checkConnection() async {
    if (_isCheckingConnection) return;
    
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isConnected = await _connectionService.pingServer();
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  /// Inizializza l'app e sincronizza le immagini
  Future<void> _initializeApp() async {
    // Carica le persone
    context.read<PersoneProvider>().loadPersone();
    
    // Copia le immagini dalla SD card alla directory dell'app (se disponibili)
    final setupImages = SetupImages();
    setupImages.copyImagesFromSDCard().then((count) {
      if (count > 0 && mounted) {
        debugPrint('Immagini copiate dalla SD card: $count file');
      }
    });
    
    // Inizializza le immagini in background (copia dagli assets alla directory locale)
    final imageInitializer = ImageInitializer();
    imageInitializer.initializeImagesFromAssets().then((count) {
      if (count > 0 && mounted) {
        debugPrint('Immagini inizializzate dagli assets: $count file copiati');
      }
    });
  }

  /// Gestisce il logout
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Mostra il dialog di conferma logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persone'),
        actions: [
          // Icona stato connessione server
          IconButton(
            icon: _isCheckingConnection
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
            onPressed: _checkConnection,
            tooltip: _isConnected
                ? 'Collegato al server'
                : 'Non collegato al server',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              );
            },
            tooltip: 'Sincronizza',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca per nome o cognome...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PersoneProvider>().searchPersone('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                context.read<PersoneProvider>().searchPersone(value);
              },
            ),
          ),
          // Lista persone
          Expanded(
            child: Consumer<PersoneProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.persone.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadPersone(),
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.persone.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nessuna persona trovata',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    itemCount: provider.persone.length,
                    itemBuilder: (context, index) {
                      final persona = provider.persone[index];
                      return PersonaCard(
                        persona: persona,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonaDetailScreen(
                                personaId: persona.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
