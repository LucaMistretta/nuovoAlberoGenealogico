<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Media;
use App\Models\Persona;
use App\Services\ImageCompressionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class MediaController extends Controller
{
    /**
     * Ottiene tutti i media di una persona
     */
    public function index(int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $media = $persona->media()->orderBy('data_caricamento', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $media,
        ]);
    }

    /**
     * Carica un nuovo media per una persona
     */
    public function store(Request $request, int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);

        // Debug: log dei dati ricevuti
        \Log::info('Media upload request', [
            'persona_id' => $personaId,
            'has_file' => $request->hasFile('file'),
            'file_size' => $request->hasFile('file') ? $request->file('file')->getSize() : null,
            'tipo' => $request->input('tipo'),
            'all_data' => $request->all(),
        ]);

        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:20480', // Max 20MB (in KB)
            'tipo' => 'required|in:foto,documento',
            'descrizione' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            \Log::error('Media upload validation failed', [
                'errors' => $validator->errors()->toArray(),
                'request_data' => $request->all(),
            ]);
            
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
                'debug' => [
                    'has_file' => $request->hasFile('file'),
                    'file_size' => $request->hasFile('file') ? $request->file('file')->getSize() : null,
                    'post_max_size' => ini_get('post_max_size'),
                    'upload_max_filesize' => ini_get('upload_max_filesize'),
                ],
            ], 422);
        }

        $file = $request->file('file');
        $tipo = $request->input('tipo');
        $descrizione = $request->input('descrizione');

        // Comprimi l'immagine se è una foto per risparmiare spazio disco
        $fileToSave = $file;
        if ($tipo === 'foto' && str_starts_with($file->getMimeType(), 'image/')) {
            $compressionService = new ImageCompressionService();
            $compressedPath = $compressionService->compressImage(
                $file,
                maxSizeBytes: 1024 * 1024, // Target 1MB per risparmiare spazio
                maxWidth: 1920,
                maxHeight: 1920,
                alwaysCompress: true // Comprimi sempre per risparmiare spazio
            );
            
            if ($compressedPath && $compressedPath !== $file->getRealPath()) {
                // Crea un nuovo UploadedFile dal file compresso
                $fileToSave = new \Illuminate\Http\UploadedFile(
                    $compressedPath,
                    $file->getClientOriginalName(),
                    $file->getMimeType(),
                    null,
                    true // test mode
                );
            }
        }

        // Genera nome file univoco
        $nomeFile = time() . '_' . uniqid() . '.' . $fileToSave->getClientOriginalExtension();
        $percorso = 'media/persona_' . $personaId . '/' . $nomeFile;

        // Salva il file (compresso se applicabile) nel disco pubblico
        $path = $fileToSave->storeAs('media/persona_' . $personaId, $nomeFile, 'public');
        
        // Pulisci file temporaneo compresso se esiste
        if (isset($compressedPath) && $compressedPath !== $file->getRealPath() && file_exists($compressedPath)) {
            @unlink($compressedPath);
        }

        // Ottieni la dimensione finale del file salvato
        $finalSize = Storage::disk('public')->size($percorso);

        // Crea record nel database
        $media = Media::create([
            'persona_id' => $personaId,
            'tipo' => $tipo,
            'nome_file' => $file->getClientOriginalName(),
            'percorso' => $percorso,
            'dimensione' => $finalSize,
            'mime_type' => $file->getMimeType(),
            'descrizione' => $descrizione,
            'data_caricamento' => now(),
        ]);

        $message = 'Media caricato con successo';

        return response()->json([
            'success' => true,
            'data' => $media,
            'message' => $message,
        ], 201);
    }

    /**
     * Elimina un media
     */
    public function destroy(int $personaId, int $mediaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $media = Media::where('persona_id', $personaId)
            ->findOrFail($mediaId);

        // Elimina il file fisico
        if (Storage::disk('public')->exists($media->percorso)) {
            Storage::disk('public')->delete($media->percorso);
        }

        // Elimina il record
        $media->delete();

        return response()->json([
            'success' => true,
            'message' => 'Media eliminato con successo',
        ]);
    }
}

