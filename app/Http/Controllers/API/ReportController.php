<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Persona;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * Statistiche generali
     */
    public function statisticheGenerali(): JsonResponse
    {
        $totalePersone = Persona::count();
        $viventi = Persona::whereNull('deceduto_il')->count();
        $deceduti = Persona::whereNotNull('deceduto_il')->count();
        
        // Calcola generazioni (approssimativo)
        $generazioni = $this->calcolaGenerazioni();
        
        // Persone con genitori
        $conGenitori = DB::table('persona_legami as pl')
            ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
            ->whereIn('tl.nome', ['padre', 'madre'])
            ->distinct('pl.persona_collegata_id')
            ->count('pl.persona_collegata_id');
        
        // Persone con figli
        $conFigli = DB::table('persona_legami as pl')
            ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
            ->whereIn('tl.nome', ['padre', 'madre', 'figlio'])
            ->distinct('pl.persona_id')
            ->count('pl.persona_id');
        
        return response()->json([
            'success' => true,
            'data' => [
                'totale_persone' => $totalePersone,
                'viventi' => $viventi,
                'deceduti' => $deceduti,
                'generazioni' => $generazioni,
                'con_genitori' => $conGenitori,
                'con_figli' => $conFigli,
            ],
        ]);
    }

    /**
     * Distribuzione età
     */
    public function distribuzioneEta(): JsonResponse
    {
        $persone = Persona::whereNotNull('nato_il')->get();
        
        $distribuzione = [
            '0-20' => 0,
            '21-40' => 0,
            '41-60' => 0,
            '61-80' => 0,
            '81-100' => 0,
            '100+' => 0,
        ];
        
        foreach ($persone as $persona) {
            $eta = $this->calcolaEta($persona);
            if ($eta === null) continue;
            
            if ($eta <= 20) {
                $distribuzione['0-20']++;
            } elseif ($eta <= 40) {
                $distribuzione['21-40']++;
            } elseif ($eta <= 60) {
                $distribuzione['41-60']++;
            } elseif ($eta <= 80) {
                $distribuzione['61-80']++;
            } elseif ($eta <= 100) {
                $distribuzione['81-100']++;
            } else {
                $distribuzione['100+']++;
            }
        }
        
        return response()->json([
            'success' => true,
            'data' => $distribuzione,
        ]);
    }

    /**
     * Luoghi di nascita più frequenti
     */
    public function luoghiNascita(): JsonResponse
    {
        $luoghi = Persona::whereNotNull('nato_a')
            ->where('nato_a', '!=', '')
            ->select('nato_a', DB::raw('count(*) as totale'))
            ->groupBy('nato_a')
            ->orderBy('totale', 'desc')
            ->limit(10)
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => $luoghi,
        ]);
    }

    /**
     * Calcola età di una persona
     */
    private function calcolaEta(Persona $persona): ?int
    {
        if (!$persona->nato_il) {
            return null;
        }
        
        $dataFine = $persona->deceduto_il ?? now();
        return $persona->nato_il->diffInYears($dataFine);
    }

    /**
     * Calcola numero approssimativo di generazioni
     */
    private function calcolaGenerazioni(): int
    {
        // Trova la persona più vecchia senza genitori
        $radice = Persona::whereDoesntHave('personaLegamiCollegati', function ($query) {
            $query->whereHas('tipoLegame', function ($q) {
                $q->whereIn('nome', ['padre', 'madre']);
            });
        })->first();
        
        if (!$radice) {
            return 1;
        }
        
        return $this->calcolaProfondita($radice, 1);
    }

    /**
     * Calcola profondità dell'albero ricorsivamente
     */
    private function calcolaProfondita(Persona $persona, int $livello): int
    {
        $figli = $persona->figli();
        if ($figli->isEmpty()) {
            return $livello;
        }
        
        $maxProfondita = $livello;
        foreach ($figli as $figlio) {
            $profondita = $this->calcolaProfondita($figlio, $livello + 1);
            if ($profondita > $maxProfondita) {
                $maxProfondita = $profondita;
            }
        }
        
        return $maxProfondita;
    }
}

