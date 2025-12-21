<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Media;
use App\Models\Persona;
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

        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:10240', // Max 10MB
            'tipo' => 'required|in:foto,documento',
            'descrizione' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $file = $request->file('file');
        $tipo = $request->input('tipo');
        $descrizione = $request->input('descrizione');

        // Genera nome file univoco
        $nomeFile = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $percorso = 'media/persona_' . $personaId . '/' . $nomeFile;

        // Salva il file nel disco pubblico
        $path = $file->storeAs('media/persona_' . $personaId, $nomeFile, 'public');

        // Crea record nel database
        $media = Media::create([
            'persona_id' => $personaId,
            'tipo' => $tipo,
            'nome_file' => $file->getClientOriginalName(),
            'percorso' => $percorso,
            'dimensione' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'descrizione' => $descrizione,
            'data_caricamento' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $media,
            'message' => 'Media caricato con successo',
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

