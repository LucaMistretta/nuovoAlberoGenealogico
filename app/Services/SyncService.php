<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\SyncLog;
use App\Models\SyncConflict;
use App\Models\Persona;
use App\Models\Evento;
use App\Models\Media;
use App\Models\Nota;
use App\Models\Tag;
use App\Models\PersonaLegame;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class SyncService
{
    protected DiffService $diffService;

    public function __construct(DiffService $diffService)
    {
        $this->diffService = $diffService;
    }

    /**
     * Calcola e restituisce le differenze tra server e app
     */
    public function getDiff(array $appData, ?\DateTime $lastSyncTimestamp = null): array
    {
        return $this->diffService->calculateDiff($appData, $lastSyncTimestamp);
    }

    /**
     * Push: copia dati dall'app al server (App → Server)
     */
    public function pushFromApp(array $appData, string $syncMode = 'http', ?string $deviceId = null, array $mediaFiles = []): array
    {
        $syncLog = SyncLog::create([
            'sync_type' => 'push',
            'sync_mode' => $syncMode,
            'device_id' => $deviceId,
            'user_id' => auth()->check() ? auth()->id() : null,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        try {
            $summary = [
                'persone' => 0,
                'eventi' => 0,
                'media' => 0,
                'note' => 0,
                'tags' => 0,
                'persona_legami' => 0,
            ];

            DB::transaction(function () use ($appData, &$summary, $mediaFiles) {
                // Sincronizza persone
                if (isset($appData['persone'])) {
                    $summary['persone'] = $this->syncTable('persone', Persona::class, $appData['persone'], false, []);
                }

                // Sincronizza eventi
                if (isset($appData['eventi'])) {
                    $summary['eventi'] = $this->syncTable('eventi', Evento::class, $appData['eventi'], false, []);
                }

                // Sincronizza media
                if (isset($appData['media'])) {
                    $summary['media'] = $this->syncTable('media', Media::class, $appData['media'], false, $mediaFiles);
                }

                // Sincronizza note
                if (isset($appData['note'])) {
                    $summary['note'] = $this->syncTable('note', Nota::class, $appData['note'], false, []);
                }

                // Sincronizza tags
                if (isset($appData['tags'])) {
                    $summary['tags'] = $this->syncTable('tags', Tag::class, $appData['tags'], false, []);
                }

                // Sincronizza persona_legami
                if (isset($appData['persona_legami'])) {
                    $summary['persona_legami'] = $this->syncTable('persona_legami', PersonaLegame::class, $appData['persona_legami'], false, []);
                }
            });

            $totalSynced = array_sum($summary);
            
            $syncLog->update([
                'status' => 'completed',
                'summary' => $summary,
                'records_synced' => $totalSynced,
                'completed_at' => now(),
            ]);

            return [
                'success' => true,
                'sync_log_id' => $syncLog->id,
                'summary' => $summary,
                'records_synced' => $totalSynced,
            ];
        } catch (\Exception $e) {
            Log::error('Sync push failed', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            
            $syncLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
                'completed_at' => now(),
            ]);

            throw $e;
        }
    }

    /**
     * Pull: invia dati dal server all'app (Server → App)
     */
    public function pullToApp(?\DateTime $lastSyncTimestamp = null): array
    {
        $data = [
            'persone' => $this->getTableData('persone', Persona::class, $lastSyncTimestamp),
            'eventi' => $this->getTableData('eventi', Evento::class, $lastSyncTimestamp),
            'media' => $this->getTableData('media', Media::class, $lastSyncTimestamp),
            'note' => $this->getTableData('note', Nota::class, $lastSyncTimestamp),
            'tags' => $this->getTableData('tags', Tag::class, $lastSyncTimestamp),
            'persona_legami' => $this->getTableData('persona_legami', PersonaLegame::class, $lastSyncTimestamp),
        ];

        $summary = [
            'persone' => count($data['persone']),
            'eventi' => count($data['eventi']),
            'media' => count($data['media']),
            'note' => count($data['note']),
            'tags' => count($data['tags']),
            'persona_legami' => count($data['persona_legami']),
        ];

        return [
            'data' => $data,
            'summary' => $summary,
            'total_records' => array_sum($summary),
            'sync_timestamp' => now()->toIso8601String(),
        ];
    }

    /**
     * Merge: unisce dati da entrambi i lati
     */
    public function merge(array $appData, ?\DateTime $lastSyncTimestamp = null, array $mediaFiles = []): array
    {
        $syncLog = SyncLog::create([
            'sync_type' => 'merge',
            'sync_mode' => 'http',
            'user_id' => auth()->check() ? auth()->id() : null,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        // Inizializza variabili fuori dal try per sicurezza
        $summary = [
            'persone' => 0,
            'eventi' => 0,
            'media' => 0,
            'note' => 0,
            'tags' => 0,
            'persona_legami' => 0,
        ];
        $conflictsCount = 0;

        try {
            // Calcola differenze
            $diff = $this->diffService->calculateDiff($appData, $lastSyncTimestamp);
            
            // Reset summary per sicurezza
            $summary = [
                'persone' => 0,
                'eventi' => 0,
                'media' => 0,
                'note' => 0,
                'tags' => 0,
                'persona_legami' => 0,
            ];
            $conflictsCount = 0; // Inizializza fuori dalla closure
            
            DB::transaction(function () use ($appData, $diff, &$summary, &$conflictsCount, $mediaFiles) {
                // Applica modifiche: server → app (pull)
                foreach (['persone', 'eventi', 'media', 'note', 'tags', 'persona_legami'] as $table) {
                    if (!empty($diff[$table]['server_new'])) {
                        // Record nuovi sul server: aggiungi
                        $summary[$table] += count($diff[$table]['server_new']);
                    }
                    
                    if (!empty($diff[$table]['modified'])) {
                        // Record modificati: usa versione più recente
                        foreach ($diff[$table]['modified'] as $mod) {
                            if ($mod['type'] === 'server_newer') {
                                // Server più recente: aggiorna
                                $summary[$table]++;
                            }
                        }
                    }
                }

                // Applica modifiche: app → server (push)
                if (isset($appData['persone'])) {
                    $summary['persone'] += $this->syncTable('persone', Persona::class, $appData['persone'], true, []);
                }
                if (isset($appData['eventi'])) {
                    $summary['eventi'] += $this->syncTable('eventi', Evento::class, $appData['eventi'], true, []);
                }
                if (isset($appData['media'])) {
                    $summary['media'] += $this->syncTable('media', Media::class, $appData['media'], true, $mediaFiles);
                }
                if (isset($appData['note'])) {
                    $summary['note'] += $this->syncTable('note', Nota::class, $appData['note'], true, []);
                }
                if (isset($appData['tags'])) {
                    $summary['tags'] += $this->syncTable('tags', Tag::class, $appData['tags'], true, []);
                }
                if (isset($appData['persona_legami'])) {
                    $summary['persona_legami'] += $this->syncTable('persona_legami', PersonaLegame::class, $appData['persona_legami'], true, []);
                }

                // Gestisci conflitti
                foreach (['persone', 'eventi', 'media', 'note', 'tags', 'persona_legami'] as $table) {
                    if (!empty($diff[$table]['conflicts'])) {
                        foreach ($diff[$table]['conflicts'] as $conflict) {
                            // Verifica che i campi esistano prima di usarli
                            if (!isset($conflict['id']) || !isset($conflict['server_data']) || !isset($conflict['app_data'])) {
                                continue; // Salta conflitti malformati
                            }
                            
                            SyncConflict::create([
                                'table_name' => $table,
                                'record_id' => $conflict['id'],
                                'server_data' => $conflict['server_data'],
                                'app_data' => $conflict['app_data'],
                                'server_updated_at' => isset($conflict['server_updated_at']) 
                                    ? Carbon::parse($conflict['server_updated_at']) 
                                    : now(),
                                'app_updated_at' => isset($conflict['app_updated_at']) 
                                    ? Carbon::parse($conflict['app_updated_at']) 
                                    : now(),
                                'resolution' => 'pending',
                            ]);
                            $conflictsCount++;
                        }
                    }
                }
            });

            $totalSynced = array_sum($summary);
            
            $syncLog->update([
                'status' => 'completed',
                'summary' => $summary,
                'records_synced' => $totalSynced,
                'conflicts_found' => $conflictsCount,
                'completed_at' => now(),
            ]);

            return [
                'success' => true,
                'sync_log_id' => $syncLog->id,
                'summary' => $summary,
                'records_synced' => $totalSynced,
                'conflicts_found' => $conflictsCount,
            ];
        } catch (\Exception $e) {
            Log::error('Sync merge failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            $syncLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
                'completed_at' => now(),
            ]);

            throw $e;
        }
    }

    /**
     * Sincronizza una tabella (upsert)
     */
    private function syncTable(string $tableName, string $modelClass, array $records, bool $mergeMode = false, array $mediaFiles = []): int
    {
        $count = 0;
        
        foreach ($records as $record) {
            // Rimuovi last_synced_at PRIMA di qualsiasi altra operazione
            // Questo evita problemi con formati di data non compatibili dall'app
            if (isset($record['last_synced_at'])) {
                unset($record['last_synced_at']);
            }
            
            // Rimuovi campi non fillable e id (gestito separatamente)
            $fillable = (new $modelClass)->getFillable();
            $id = $record['id'] ?? null;
            
            if (!$id) {
                continue; // Salta record senza ID
            }
            
            $data = array_intersect_key($record, array_flip($fillable));
            
            // TEMPORANEAMENTE DISABILITATO: last_synced_at causa problemi con SQLite
            // Aggiungi last_synced_at se presente nei fillable (sempre con now() per consistenza)
            // Non usare mai il valore dall'app, sempre generare uno nuovo
            // Converti in stringa per compatibilità con SQLite
            // if (in_array('last_synced_at', $fillable)) {
            //     $data['last_synced_at'] = now()->format('Y-m-d H:i:s');
            // }
            
            if ($mergeMode) {
                // In merge mode: usa versione più recente basata su updated_at
                $existing = $modelClass::find($id);
                if ($existing) {
                    // Converte Carbon a timestamp per confronto
                    $existingUpdated = $existing->updated_at 
                        ? ($existing->updated_at instanceof \Carbon\Carbon 
                            ? $existing->updated_at->timestamp 
                            : (is_string($existing->updated_at) 
                                ? strtotime($existing->updated_at) 
                                : 0)) 
                        : 0;
                    $newUpdated = isset($record['updated_at']) 
                        ? (is_string($record['updated_at']) 
                            ? strtotime($record['updated_at']) 
                            : ($record['updated_at'] instanceof \Carbon\Carbon
                                ? $record['updated_at']->timestamp
                                : (is_numeric($record['updated_at']) 
                                    ? (int)$record['updated_at'] 
                                    : 0))) 
                        : 0;
                    
                    if ($newUpdated > $existingUpdated) {
                        $existing->update($data);
                        $count++;
                        
                        // Se è un Media, verifica che il file esista e caricalo se necessario
                        if ($tableName === 'media' && $existing instanceof Media && isset($data['percorso'])) {
                            $this->handleMediaFile($existing, $data['percorso'], $mediaFiles);
                        }
                    }
                } else {
                    $data['id'] = $id; // Aggiungi ID per create
                    $created = $modelClass::create($data);
                    $count++;
                    
                    // Se è un Media, verifica che il file esista e caricalo se necessario
                    if ($tableName === 'media' && $created instanceof Media && isset($data['percorso'])) {
                        if ($this->handleMediaFile($created, $data['percorso'], $mediaFiles)) {
                            $filesUploaded++;
                        }
                    }
                }
            } else {
                // Push mode: sovrascrivi sempre
                $updated = $modelClass::updateOrCreate(['id' => $id], $data);
                $count++;
                
                // Se è un Media, verifica che il file esista e caricalo se necessario
                if ($tableName === 'media' && $updated instanceof Media && isset($data['percorso'])) {
                    if ($this->handleMediaFile($updated, $data['percorso'], $mediaFiles)) {
                        $filesUploaded++;
                    }
                }
            }
        }
        
        return $count;
    }
    
    /**
     * Gestisce il file media: verifica esistenza e carica se necessario
     * Restituisce true se il file è stato caricato, false altrimenti
     */
    private function handleMediaFile(Media $media, string $percorso, array $mediaFiles): bool
    {
        // Verifica se il file esiste già nel filesystem
        if (Storage::disk('public')->exists($percorso)) {
            return false; // File già presente, nessuna azione necessaria
        }

        // Cerca il file nei file caricati durante la sincronizzazione
        $fileName = basename($percorso);
        
        // Cerca il file per media_id (chiave come "media_id" o "media_files[media_id]")
        $uploadedFile = null;
        foreach ($mediaFiles as $key => $file) {
            // La chiave può essere "media_id" o "media_files[media_id]" dal multipart
            $keyStr = is_string($key) ? $key : (string)$key;
            if (strpos($keyStr, (string)$media->id) !== false || $keyStr === (string)$media->id) {
                $uploadedFile = $file;
                break;
            }
            // Fallback: cerca per nome file
            if ($file->getClientOriginalName() === $fileName || $file->getClientOriginalName() === $media->nome_file) {
                $uploadedFile = $file;
                break;
            }
        }

        if ($uploadedFile) {
            // Salva il file nel percorso specificato
            try {
                $directory = dirname($percorso);
                Storage::disk('public')->makeDirectory($directory);
                
                $savedPath = Storage::disk('public')->putFileAs(
                    $directory,
                    $uploadedFile,
                    $fileName
                );

                // Aggiorna dimensione e mime_type se necessario
                $media->update([
                    'dimensione' => $uploadedFile->getSize(),
                    'mime_type' => $uploadedFile->getMimeType(),
                ]);

                Log::info("Media file uploaded during sync", [
                    'media_id' => $media->id,
                    'percorso' => $savedPath,
                    'persona_id' => $media->persona_id,
                ]);
                
                return true; // File caricato con successo
            } catch (\Exception $e) {
                Log::error("Failed to upload media file during sync", [
                    'media_id' => $media->id,
                    'percorso' => $percorso,
                    'error' => $e->getMessage(),
                ]);
                return false;
            }
        } else {
            // File non trovato nei file caricati
            Log::warning("Media file missing during sync", [
                'media_id' => $media->id,
                'percorso' => $percorso,
                'persona_id' => $media->persona_id,
                'message' => 'Il file immagine non esiste nel filesystem e non è stato fornito durante la sincronizzazione.',
            ]);
            return false;
        }
    }

    /**
     * Ottiene dati di una tabella per il pull
     */
    private function getTableData(string $tableName, string $modelClass, ?\DateTime $lastSyncTimestamp): array
    {
        $query = $modelClass::query();
        
        if ($lastSyncTimestamp) {
            $query->where(function ($q) use ($lastSyncTimestamp) {
                $q->where('updated_at', '>', $lastSyncTimestamp)
                  ->orWhereNull('last_synced_at')
                  ->orWhere('last_synced_at', '<', $lastSyncTimestamp);
            });
        }

        $results = $query->get();
        
        // Converti in array e aggiungi last_synced_at se non presente
        return $results->map(function ($record) {
            $data = $record->toArray();
            if (!isset($data['last_synced_at'])) {
                $data['last_synced_at'] = null;
            }
            return $data;
        })->toArray();
    }
}

