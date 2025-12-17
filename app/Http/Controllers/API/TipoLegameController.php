<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTipoLegameRequest;
use App\Http\Requests\UpdateTipoLegameRequest;
use App\Http\Resources\TipoLegameResource;
use App\Models\TipoLegame;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class TipoLegameController extends Controller
{
    /**
     * Lista tutti i tipi di legame
     */
    public function index(): AnonymousResourceCollection
    {
        $tipiLegame = TipoLegame::orderBy('nome')->get();
        return TipoLegameResource::collection($tipiLegame);
    }

    /**
     * Mostra dettagli tipo di legame
     */
    public function show(int $id): TipoLegameResource|JsonResponse
    {
        $tipoLegame = TipoLegame::find($id);

        if (!$tipoLegame) {
            return response()->json(['message' => 'Tipo di legame non trovato'], 404);
        }

        return new TipoLegameResource($tipoLegame);
    }

    /**
     * Crea nuovo tipo di legame
     */
    public function store(StoreTipoLegameRequest $request): TipoLegameResource
    {
        $tipoLegame = TipoLegame::create($request->validated());
        return new TipoLegameResource($tipoLegame);
    }

    /**
     * Modifica tipo di legame
     */
    public function update(UpdateTipoLegameRequest $request, int $id): TipoLegameResource|JsonResponse
    {
        $tipoLegame = TipoLegame::find($id);

        if (!$tipoLegame) {
            return response()->json(['message' => 'Tipo di legame non trovato'], 404);
        }

        $tipoLegame->update($request->validated());
        return new TipoLegameResource($tipoLegame->fresh());
    }

    /**
     * Elimina tipo di legame
     */
    public function destroy(int $id): JsonResponse
    {
        $tipoLegame = TipoLegame::find($id);

        if (!$tipoLegame) {
            return response()->json(['message' => 'Tipo di legame non trovato'], 404);
        }

        // Verifica se è usato in qualche relazione
        if ($tipoLegame->personaLegami()->count() > 0) {
            return response()->json([
                'message' => 'Impossibile eliminare: questo tipo di legame è utilizzato in alcune relazioni',
            ], 422);
        }

        $tipoLegame->delete();
        return response()->json(['message' => 'Tipo di legame eliminato con successo']);
    }
}

