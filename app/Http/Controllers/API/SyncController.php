<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\SyncService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class SyncController extends Controller
{
    protected SyncService $syncService;

    public function __construct(SyncService $syncService)
    {
        $this->syncService = $syncService;
    }

    /**
     * POST /api/sync/diff
     * Calcola e restituisce le differenze tra server e app
     */
    public function diff(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'app_data' => 'required|array',
            'last_sync_timestamp' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $appData = $request->input('app_data');
        $lastSyncTimestamp = $request->input('last_sync_timestamp') 
            ? new \DateTime($request->input('last_sync_timestamp'))
            : null;

        try {
            $diff = $this->syncService->getDiff($appData, $lastSyncTimestamp);

            return response()->json([
                'success' => true,
                'diff' => $diff,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nel calcolo delle differenze: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/sync/push-from-app
     * Riceve dati dall'app e li applica al server (App → Server)
     */
    public function pushFromApp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'app_data' => 'required|array',
            'sync_mode' => 'nullable|string|in:http,adb',
            'device_id' => 'nullable|string',
            'media_files' => 'nullable|array',
            'media_files.*' => 'file|max:20480', // Max 20MB per file
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $appData = $request->input('app_data');
        $syncMode = $request->input('sync_mode', 'http');
        $deviceId = $request->input('device_id');
        $mediaFiles = $request->file('media_files', []);

        try {
            $result = $this->syncService->pushFromApp($appData, $syncMode, $deviceId, $mediaFiles);

            return response()->json([
                'success' => true,
                'message' => 'Sincronizzazione push completata con successo',
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore durante la sincronizzazione push: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/sync/pull-to-app
     * Invia dati dal server all'app (Server → App)
     */
    public function pullToApp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'last_sync_timestamp' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $lastSyncTimestamp = $request->input('last_sync_timestamp')
            ? new \DateTime($request->input('last_sync_timestamp'))
            : null;

        try {
            $result = $this->syncService->pullToApp($lastSyncTimestamp);

            return response()->json([
                'success' => true,
                'message' => 'Dati pronti per il pull',
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore durante il pull: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/sync/merge
     * Merge completo bidirezionale
     */
    public function merge(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'app_data' => 'required|array',
            'last_sync_timestamp' => 'nullable|date',
            'media_files' => 'nullable|array',
            'media_files.*' => 'file|max:20480', // Max 20MB per file
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $appData = $request->input('app_data');
        $lastSyncTimestamp = $request->input('last_sync_timestamp')
            ? new \DateTime($request->input('last_sync_timestamp'))
            : null;
        $mediaFiles = $request->file('media_files', []);

        try {
            $result = $this->syncService->merge($appData, $lastSyncTimestamp, $mediaFiles);

            $message = 'Merge completato con successo';
            $filesUploaded = $result['files_uploaded'] ?? 0;
            if ($filesUploaded > 0) {
                $message .= ". Caricati $filesUploaded file immagine.";
            }

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore durante il merge: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/sync/status
     * Restituisce lo stato della sincronizzazione
     */
    public function status(): JsonResponse
    {
        try {
            $lastSync = \App\Models\SyncLog::where('status', 'completed')
                ->orderBy('completed_at', 'desc')
                ->first();

            $pendingConflicts = \App\Models\SyncConflict::where('resolution', 'pending')
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'last_sync' => $lastSync ? [
                        'id' => $lastSync->id,
                        'sync_type' => $lastSync->sync_type,
                        'sync_mode' => $lastSync->sync_mode,
                        'completed_at' => $lastSync->completed_at?->toIso8601String(),
                        'records_synced' => $lastSync->records_synced,
                        'conflicts_found' => $lastSync->conflicts_found,
                    ] : null,
                    'pending_conflicts' => $pendingConflicts,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nel recupero dello stato: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/sync/resolve-conflict
     * Risolve un conflitto manualmente
     */
    public function resolveConflict(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'conflict_id' => 'required|integer|exists:sync_conflicts,id',
            'resolution' => 'required|string|in:server_wins,app_wins,merged',
            'resolved_data' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $conflict = \App\Models\SyncConflict::findOrFail($request->input('conflict_id'));
            
            $conflict->update([
                'resolution' => $request->input('resolution'),
                'resolved_data' => $request->input('resolved_data'),
                'resolved_by' => auth()->id(),
                'resolved_at' => now(),
            ]);

            // Applica la risoluzione al database
            $this->applyConflictResolution($conflict);

            return response()->json([
                'success' => true,
                'message' => 'Conflitto risolto con successo',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nella risoluzione del conflitto: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Applica la risoluzione di un conflitto al database
     */
    private function applyConflictResolution(\App\Models\SyncConflict $conflict): void
    {
        $modelClass = $this->getModelClass($conflict->table_name);
        
        if (!$modelClass) {
            throw new \Exception("Tabella {$conflict->table_name} non supportata");
        }

        $data = match ($conflict->resolution) {
            'server_wins' => $conflict->server_data,
            'app_wins' => $conflict->app_data,
            'merged' => $conflict->resolved_data ?? $conflict->server_data,
            default => throw new \Exception("Risoluzione non valida: {$conflict->resolution}"),
        };

        // Rimuovi campi non fillable
        $fillable = (new $modelClass)->getFillable();
        $data = array_intersect_key($data, array_flip($fillable));
        $data['last_synced_at'] = now();

        $modelClass::updateOrCreate(['id' => $conflict->record_id], $data);
    }

    /**
     * Ottiene la classe modello per una tabella
     */
    private function getModelClass(string $tableName): ?string
    {
        return match ($tableName) {
            'persone' => \App\Models\Persona::class,
            'eventi' => \App\Models\Evento::class,
            'media' => \App\Models\Media::class,
            'note' => \App\Models\Nota::class,
            'tags' => \App\Models\Tag::class,
            'persona_legami' => \App\Models\PersonaLegame::class,
            default => null,
        };
    }
    
    /**
     * POST /api/sync/upload-media
     * Carica un file immagine durante la sincronizzazione
     */
    public function uploadMedia(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'media_id' => 'required|integer|exists:media,id',
            'file' => 'required|file|max:20480', // Max 20MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $media = \App\Models\Media::findOrFail($request->input('media_id'));
            $file = $request->file('file');
            
            // Salva il file nel percorso specificato nel database
            $path = $file->storeAs(
                dirname($media->percorso),
                basename($media->percorso),
                'public'
            );
            
            // Aggiorna dimensione e mime_type se necessario
            $media->update([
                'dimensione' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'File immagine caricato con successo',
                'data' => $media->fresh(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore durante il caricamento del file: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * GET /api/sync/download-media/{mediaId}
     * Scarica un file immagine durante la sincronizzazione
     */
    public function downloadMedia(int $mediaId): \Symfony\Component\HttpFoundation\BinaryFileResponse|\Illuminate\Http\JsonResponse
    {
        try {
            $media = \App\Models\Media::findOrFail($mediaId);
            
            if (!\Illuminate\Support\Facades\Storage::disk('public')->exists($media->percorso)) {
                return response()->json([
                    'success' => false,
                    'message' => 'File non trovato nel filesystem',
                ], 404);
            }
            
            $path = \Illuminate\Support\Facades\Storage::disk('public')->path($media->percorso);
            
            return response()->download($path, $media->nome_file, [
                'Content-Type' => $media->mime_type ?? 'application/octet-stream',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore durante il download del file: ' . $e->getMessage(),
            ], 500);
        }
    }
}
