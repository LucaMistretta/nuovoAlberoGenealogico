<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Tag;
use App\Models\Persona;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TagController extends Controller
{
    public function index(): JsonResponse
    {
        $tags = Tag::orderBy('nome')->get();

        return response()->json([
            'success' => true,
            'data' => $tags,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nome' => 'required|string|max:255|unique:tags,nome',
            'colore' => 'nullable|string|max:7',
            'descrizione' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $tag = Tag::create($request->only(['nome', 'colore', 'descrizione']));

        return response()->json([
            'success' => true,
            'data' => $tag,
            'message' => 'Tag creato con successo',
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $tag = Tag::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nome' => 'required|string|max:255|unique:tags,nome,' . $id,
            'colore' => 'nullable|string|max:7',
            'descrizione' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $tag->update($request->only(['nome', 'colore', 'descrizione']));

        return response()->json([
            'success' => true,
            'data' => $tag,
            'message' => 'Tag aggiornato con successo',
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        $tag = Tag::findOrFail($id);
        $tag->delete();

        return response()->json([
            'success' => true,
            'message' => 'Tag eliminato con successo',
        ]);
    }

    public function attachToPersona(Request $request, int $personaId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);

        $validator = Validator::make($request->all(), [
            'tag_id' => 'required|exists:tags,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $persona->tags()->syncWithoutDetaching([$request->input('tag_id')]);

        return response()->json([
            'success' => true,
            'message' => 'Tag associato con successo',
        ]);
    }

    public function detachFromPersona(int $personaId, int $tagId): JsonResponse
    {
        $persona = Persona::findOrFail($personaId);
        $persona->tags()->detach($tagId);

        return response()->json([
            'success' => true,
            'message' => 'Tag rimosso con successo',
        ]);
    }
}

