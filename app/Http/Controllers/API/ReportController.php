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
        try {
            $totalePersone = Persona::count();
            $viventi = Persona::whereNull('deceduto_il')->count();
            $deceduti = Persona::whereNotNull('deceduto_il')->count();
            
            // Calcola generazioni (approssimativo)
            $generazioni = $this->calcolaGenerazioni();
            
            // Persone con genitori (dove questa persona è collegata come figlio)
            $conGenitori = DB::table('persona_legami as pl')
                ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
                ->whereIn('tl.nome', ['padre', 'madre'])
                ->distinct('pl.persona_collegata_id')
                ->count('pl.persona_collegata_id');
            
            // Persone con figli (dove questa persona è genitore)
            $conFigli = DB::table('persona_legami as pl')
                ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
                ->whereIn('tl.nome', ['padre', 'madre', 'figlio'])
                ->where('pl.persona_id', '!=', DB::raw('pl.persona_collegata_id'))
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
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nel calcolo delle statistiche: ' . $e->getMessage(),
                'data' => [
                    'totale_persone' => 0,
                    'viventi' => 0,
                    'deceduti' => 0,
                    'generazioni' => 0,
                    'con_genitori' => 0,
                    'con_figli' => 0,
                ],
            ], 500);
        }
    }

    /**
     * Distribuzione età
     */
    public function distribuzioneEta(): JsonResponse
    {
        try {
            $persone = Persona::whereNotNull('nato_il')
                ->select('nato_il', 'deceduto_il')
                ->get();
            
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
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nel calcolo della distribuzione età: ' . $e->getMessage(),
                'data' => [
                    '0-20' => 0,
                    '21-40' => 0,
                    '41-60' => 0,
                    '61-80' => 0,
                    '81-100' => 0,
                    '100+' => 0,
                ],
            ], 500);
        }
    }

    /**
     * Luoghi di nascita più frequenti
     */
    public function luoghiNascita(): JsonResponse
    {
        try {
            $luoghi = Persona::whereNotNull('nato_a')
                ->where('nato_a', '!=', '')
                ->where('nato_a', '!=', '0')
                ->select('nato_a', DB::raw('count(*) as totale'))
                ->groupBy('nato_a')
                ->orderBy('totale', 'desc')
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => $luoghi,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Errore nel calcolo dei luoghi di nascita: ' . $e->getMessage(),
                'data' => [],
            ], 500);
        }
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
        return (int) $persona->nato_il->diffInYears($dataFine);
    }

    /**
     * Calcola numero approssimativo di generazioni (versione ottimizzata)
     */
    private function calcolaGenerazioni(): int
    {
        try {
            // Versione semplificata: conta quante persone hanno genitori diversi
            // e usa una query più semplice invece di ricorsione
            $personeConGenitori = DB::table('persona_legami as pl')
                ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
                ->whereIn('tl.nome', ['padre', 'madre'])
                ->distinct('pl.persona_collegata_id')
                ->count('pl.persona_collegata_id');
            
            // Se ci sono persone con genitori, ci sono almeno 2 generazioni
            // Altrimenti solo 1
            if ($personeConGenitori > 0) {
                // Stima approssimativa: ogni livello di genitori aggiunge una generazione
                // Per semplicità, assumiamo che ci siano almeno 2-3 generazioni se ci sono relazioni
                return max(2, min(5, (int)ceil($personeConGenitori / 10) + 1));
            }
            
            return 1;
        } catch (\Exception $e) {
            // In caso di errore, restituisci un valore di default
            return 1;
        }
    }
}

