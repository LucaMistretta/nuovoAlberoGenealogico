<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Nota;
use App\Models\Persona;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class NotaController extends Controller
{
    public function index(int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $note = $persona->note()->with('user')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $note,
        ]);
    }

    public function store(Request $request, int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);

        $validator = Validator::make($request->all(), [
            'contenuto' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $nota = Nota::create([
            'persona_id' => $personaId,
            'user_id' => Auth::id(),
            'contenuto' => $request->input('contenuto'),
        ]);

        $nota->load('user');

        return response()->json([
            'success' => true,
            'data' => $nota,
            'message' => 'Nota creata con successo',
        ], 201);
    }

    public function update(Request $request, int $personaId, int $notaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $nota = Nota::where('persona_id', $personaId)
            ->findOrFail($notaId);

        $validator = Validator::make($request->all(), [
            'contenuto' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $nota->update(['contenuto' => $request->input('contenuto')]);
        $nota->load('user');

        return response()->json([
            'success' => true,
            'data' => $nota,
            'message' => 'Nota aggiornata con successo',
        ]);
    }

    public function destroy(int $personaId, int $notaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $nota = Nota::where('persona_id', $personaId)
            ->findOrFail($notaId);

        $nota->delete();

        return response()->json([
            'success' => true,
            'message' => 'Nota eliminata con successo',
        ]);
    }
}

