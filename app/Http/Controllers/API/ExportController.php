<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\GedcomExportService;
use App\Models\Persona;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Response as ResponseFacade;

class ExportController extends Controller
{
    public function __construct(
        private GedcomExportService $gedcomExportService
    ) {}

    /**
     * Esporta tutto l'albero in formato GEDCOM
     */
    public function exportGedcom(): Response
    {
        $gedcom = $this->gedcomExportService->exportAll();
        
        return ResponseFacade::make($gedcom, 200, [
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="albero_genealogico.ged"',
        ]);
    }

    /**
     * Esporta una persona e la sua famiglia in formato GEDCOM
     */
    public function exportGedcomFromPersona(int $personaId): Response
    {
        $persona = Persona::findOrFail($personaId);
        $gedcom = $this->gedcomExportService->exportFromPersona($personaId);
        
        $nomeFile = str_replace(' ', '_', $persona->nome_completo) . '_albero.ged';
        
        return ResponseFacade::make($gedcom, 200, [
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $nomeFile . '"',
        ]);
    }

    /**
     * Esporta tutte le persone in formato CSV
     */
    public function exportCsv(): Response
    {
        $persone = Persona::orderBy('cognome')->orderBy('nome')->get();
        
        $csv = "ID,Nome,Cognome,Nome Completo,Nato il,Nato a,Deceduto il,Deceduto a\n";
        
        foreach ($persone as $persona) {
            $csv .= sprintf(
                "%d,%s,%s,%s,%s,%s,%s,%s\n",
                $persona->id,
                $this->escapeCsv($persona->nome ?? ''),
                $this->escapeCsv($persona->cognome ?? ''),
                $this->escapeCsv($persona->nome_completo ?? ''),
                $persona->nato_il ? $persona->nato_il->format('Y-m-d') : '',
                $this->escapeCsv($persona->nato_a ?? ''),
                $persona->deceduto_il ? $persona->deceduto_il->format('Y-m-d') : '',
                $this->escapeCsv($persona->deceduto_a ?? '')
            );
        }
        
        return ResponseFacade::make($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="persone.csv"',
        ]);
    }

    /**
     * Escape valori CSV
     */
    private function escapeCsv(string $value): string
    {
        if (strpos($value, ',') !== false || strpos($value, '"') !== false || strpos($value, "\n") !== false) {
            return '"' . str_replace('"', '""', $value) . '"';
        }
        return $value;
    }
}

