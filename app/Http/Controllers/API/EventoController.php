<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Evento;
use App\Models\Persona;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EventoController extends Controller
{
    /**
     * Ottiene tutti gli eventi di una persona
     */
    public function index(int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $eventi = $persona->eventi()->orderBy('data_evento', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $eventi,
        ]);
    }

    /**
     * Crea un nuovo evento
     */
    public function store(Request $request, int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);

        $validator = Validator::make($request->all(), [
            'tipo_evento' => 'required|string|max:255',
            'titolo' => 'required|string|max:255',
            'descrizione' => 'nullable|string',
            'data_evento' => 'nullable|date',
            'luogo' => 'nullable|string|max:255',
            'note' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $evento = Evento::create([
            'persona_id' => $personaId,
            'tipo_evento' => $request->input('tipo_evento'),
            'titolo' => $request->input('titolo'),
            'descrizione' => $request->input('descrizione'),
            'data_evento' => $request->input('data_evento'),
            'luogo' => $request->input('luogo'),
            'note' => $request->input('note'),
        ]);

        return response()->json([
            'success' => true,
            'data' => $evento,
            'message' => 'Evento creato con successo',
        ], 201);
    }

    /**
     * Aggiorna un evento
     */
    public function update(Request $request, int $personaId, int $eventoId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $evento = Evento::where('persona_id', $personaId)
            ->findOrFail($eventoId);

        $validator = Validator::make($request->all(), [
            'tipo_evento' => 'required|string|max:255',
            'titolo' => 'required|string|max:255',
            'descrizione' => 'nullable|string',
            'data_evento' => 'nullable|date',
            'luogo' => 'nullable|string|max:255',
            'note' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $evento->update($request->only([
            'tipo_evento',
            'titolo',
            'descrizione',
            'data_evento',
            'luogo',
            'note',
        ]));

        return response()->json([
            'success' => true,
            'data' => $evento,
            'message' => 'Evento aggiornato con successo',
        ]);
    }

    /**
     * Elimina un evento
     */
    public function destroy(int $personaId, int $eventoId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $evento = Evento::where('persona_id', $personaId)
            ->findOrFail($eventoId);

        $evento->delete();

        return response()->json([
            'success' => true,
            'message' => 'Evento eliminato con successo',
        ]);
    }
}


