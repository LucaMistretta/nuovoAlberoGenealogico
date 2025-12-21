<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\GedcomImportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ImportController extends Controller
{
    public function __construct(
        private GedcomImportService $gedcomImportService
    ) {}

    /**
     * Importa un file GEDCOM
     */
    public function importGedcom(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|mimes:ged,txt|max:10240', // Max 10MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $file = $request->file('file');
        $contenuto = file_get_contents($file->getRealPath());

        try {
            $risultato = $this->gedcomImportService->import($contenuto);

            return response()->json([
                'success' => true,
                'data' => $risultato,
                'message' => "Importate {$risultato['importate']} persone",
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nell\'importazione: ' . $e->getMessage(),
            ], 500);
        }
    }
}

