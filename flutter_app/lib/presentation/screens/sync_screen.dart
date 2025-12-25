import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../services/sync_service.dart';
import '../../services/api_client.dart';

/// Schermata per la sincronizzazione bidirezionale con il server
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _syncService = SyncService();
  final ApiClient _apiClient = ApiClient();

  String _syncMode = 'http'; // 'http' o 'adb'
  bool _loading = false;
  bool _syncing = false;
  String? _syncType; // 'push', 'pull', 'merge'
  double _syncProgress = 0.0;
  Map<String, dynamic>? _diff;
  Map<String, dynamic>? _syncStatus;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    // Non caricare lo stato se è selezionata modalità ADB
    if (_syncMode == 'adb') {
      return;
    }
    
    try {
      final status = await _syncService.getStatus();
      setState(() {
        _syncStatus = status;
      });
    } catch (e) {
      // Ignora errori di rete se non è critico
      if (_syncMode == 'http') {
        setState(() {
          _errorMessage = 'Errore nel caricamento stato: $e';
        });
      }
    }
  }

  Future<void> _calculateDiff() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _diff = null;
    });

    try {
      DateTime? lastSyncTimestamp;
      if (_syncStatus?['last_sync'] != null) {
        final completedAt = _syncStatus!['last_sync']['completed_at'];
        if (completedAt != null) {
          lastSyncTimestamp = DateTime.parse(completedAt);
        }
      }

      final diff = await _syncService.calculateDiff(lastSyncTimestamp, syncMode: _syncMode);
      setState(() {
        _diff = diff;
        _loading = false;
        if (_syncMode == 'adb') {
          _successMessage = 'Dati esportati. Esegui: ./sync_via_adb.sh diff';
        } else {
          _successMessage = 'Differenze calcolate con successo';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        if (_syncMode == 'adb' && e.toString().contains('sync_via_adb.sh')) {
          _successMessage = 'Dati esportati. Esegui sul server: ./sync_via_adb.sh diff';
        } else {
          _errorMessage = 'Errore nel calcolo delle differenze: $e';
        }
      });
    }
  }

  Future<void> _syncPush() async {
    DateTime? lastSyncTimestamp;
    if (_syncStatus?['last_sync'] != null) {
      final completedAt = _syncStatus!['last_sync']['completed_at'];
      if (completedAt != null) {
        lastSyncTimestamp = DateTime.parse(completedAt);
      }
    }
    
    if (_syncMode == 'adb') {
      await _performSync('push', () async {
        await _syncService.pushToServer(_syncMode);
        return {'success': true, 'message': 'Esegui sul server: ./sync_via_adb.sh push'};
      });
    } else {
      await _performSync('push', () => _syncService.pushToServer(_syncMode));
    }
  }

  Future<void> _syncPull() async {
    DateTime? lastSyncTimestamp;
    if (_syncStatus?['last_sync'] != null) {
      final completedAt = _syncStatus!['last_sync']['completed_at'];
      if (completedAt != null) {
        lastSyncTimestamp = DateTime.parse(completedAt);
      }
    }
    
    if (_syncMode == 'adb') {
      await _performSync('pull', () => _syncService.pullFromServer(lastSyncTimestamp, syncMode: _syncMode));
    } else {
      await _performSync('pull', () => _syncService.pullFromServer(lastSyncTimestamp));
    }
  }

  Future<void> _syncMerge() async {
    DateTime? lastSyncTimestamp;
    if (_syncStatus?['last_sync'] != null) {
      final completedAt = _syncStatus!['last_sync']['completed_at'];
      if (completedAt != null) {
        lastSyncTimestamp = DateTime.parse(completedAt);
      }
    }
    
    await _performSync('merge', () => _syncService.merge(lastSyncTimestamp, _syncMode));
  }

  Future<void> _performSync(String type, Future<Map<String, dynamic>> Function() syncFunction) async {
    setState(() {
      _syncing = true;
      _syncType = type;
      _syncProgress = 0.0;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Simula progresso
      _updateProgress();

      final result = await syncFunction();

      // Costruisci messaggio di successo dettagliato
      String successMsg = 'Sincronizzazione $type completata con successo';
      if (result.containsKey('summary')) {
        final summary = result['summary'] as Map<String, dynamic>;
        final recordsSynced = result['records_synced'] ?? 0;
        final conflictsFound = result['conflicts_found'] ?? 0;
        
        if (recordsSynced > 0 || conflictsFound > 0) {
          successMsg = 'Sincronizzazione completata:\n';
          successMsg += '• Record sincronizzati: $recordsSynced\n';
          if (conflictsFound > 0) {
            successMsg += '• Conflitti trovati: $conflictsFound';
          }
        }
      }

      setState(() {
        _syncProgress = 100.0;
        _syncing = false;
        _syncType = null;
        _successMessage = successMsg;
      });

      // Mostra anche uno SnackBar per maggiore visibilità
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Ricarica stato e differenze (solo se modalità HTTP)
      await _loadSyncStatus();
      if (_syncMode == 'http') {
        // Ricarica le differenze dopo la sincronizzazione
        await _calculateDiff();
      }
    } catch (e) {
      setState(() {
        _syncing = false;
        _syncType = null;
        _syncProgress = 0.0;
        _errorMessage = 'Errore durante la sincronizzazione $type: $e';
      });
    }
  }

  void _updateProgress() {
    if (_syncing && _syncProgress < 90) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _syncing) {
          setState(() {
            _syncProgress += 10;
          });
          _updateProgress();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizzazione Database'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selezione Modalità
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modalità Sincronizzazione',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Rete HTTP'),
                            value: 'http',
                            groupValue: _syncMode,
                            onChanged: (value) {
                              setState(() {
                                _syncMode = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('USB ADB'),
                            value: 'adb',
                            groupValue: _syncMode,
                            onChanged: (value) {
                              setState(() {
                                _syncMode = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stato Sincronizzazione
            if (_syncStatus != null)
              Card(
                color: _syncStatus!['pending_conflicts'] > 0
                    ? Colors.yellow.shade50
                    : Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ultima Sincronizzazione',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_syncStatus!['last_sync'] != null)
                        Text(
                          'Tipo: ${_syncStatus!['last_sync']['sync_type']} | '
                          'Modalità: ${_syncStatus!['last_sync']['sync_mode']} | '
                          'Completata: ${_formatDate(_syncStatus!['last_sync']['completed_at'])} | '
                          'Record sincronizzati: ${_syncStatus!['last_sync']['records_synced']}',
                          style: const TextStyle(fontSize: 12),
                        )
                      else
                        const Text(
                          'Nessuna sincronizzazione effettuata',
                          style: TextStyle(fontSize: 12),
                        ),
                      if (_syncStatus!['pending_conflicts'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '⚠️ ${_syncStatus!['pending_conflicts']} conflitti in attesa di risoluzione',
                            style: TextStyle(color: Colors.yellow.shade900),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Bottone Calcola Differenze
            ElevatedButton.icon(
              onPressed: _loading || _syncing ? null : _calculateDiff,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.compare_arrows),
              label: Text(_loading ? 'Calcolo differenze...' : 'Calcola Differenze'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Visualizzazione Differenze
            if (_diff != null) ...[
              const Text(
                'Differenze Trovate',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Riepilogo
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Nuovi sul Server',
                      _diff!['summary']?['server_new'] ?? 0,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Nuovi sull\'App',
                      _diff!['summary']?['app_new'] ?? 0,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Modificati',
                      _diff!['summary']?['modified'] ?? 0,
                      Colors.yellow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Conflitti',
                      _diff!['summary']?['conflicts'] ?? 0,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottoni Azioni
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _syncing || _diff == null
                          ? null
                          : _syncPush,
                      icon: _syncing && _syncType == 'push'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward),
                      label: Text(_syncing && _syncType == 'push'
                          ? 'Sincronizzazione...'
                          : 'Copia App → Server'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _syncing || _diff == null
                          ? null
                          : _syncPull,
                      icon: _syncing && _syncType == 'pull'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_downward),
                      label: Text(_syncing && _syncType == 'pull'
                          ? 'Sincronizzazione...'
                          : 'Copia Server → App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _syncing || _diff == null ? null : _syncMerge,
                  icon: _syncing && _syncType == 'merge'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.merge_type),
                  label: Text(_syncing && _syncType == 'merge'
                      ? 'Merge in corso...'
                      : 'Merge Tutto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              // Progress Bar
              if (_syncing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _syncProgress / 100),
                const SizedBox(height: 8),
                Text(
                  '${_syncProgress.toInt()}% completato',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],

            // Messaggi
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, MaterialColor color) {
    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

