<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\DataValidationService;
use Illuminate\Http\JsonResponse;

class DataQualityController extends Controller
{
    public function __construct(
        private DataValidationService $validationService
    ) {}

    /**
     * Esegue tutti i controlli di qualità dati
     */
    public function check(): JsonResponse
    {
        $risultati = $this->validationService->runAllChecks();

        $totaleProblemi = $risultati['date']->count() + 
                         $risultati['duplicati']->count() + 
                         $risultati['relazioni']->count();

        return response()->json([
            'success' => true,
            'data' => [
                'problemi_date' => $risultati['date'],
                'problemi_duplicati' => $risultati['duplicati'],
                'problemi_relazioni' => $risultati['relazioni'],
                'totale_problemi' => $totaleProblemi,
            ],
        ]);
    }
}

