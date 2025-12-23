<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\TipoEventoLegame;
use Illuminate\Http\JsonResponse;

class TipoEventoLegameController extends Controller
{
    /**
     * Lista tutti i tipi di evento legame
     */
    public function index(): JsonResponse
    {
        $tipiEventoLegame = TipoEventoLegame::orderBy('nome')->get();
        return response()->json($tipiEventoLegame);
    }
}
