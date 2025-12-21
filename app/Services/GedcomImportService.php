<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Persona;
use App\Models\TipoLegame;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GedcomImportService
{
    /**
     * Importa un file GEDCOM
     */
    public function import(string $gedcomContent): array
    {
        $righe = explode("\n", $gedcomContent);
        $persone = [];
        $famiglie = [];
        $individuoCorrente = null;
        $livelloCorrente = 0;
        $stack = [];

        foreach ($righe as $riga) {
            $riga = trim($riga);
            if (empty($riga)) continue;

            // Parsa la riga GEDCOM (formato: livello ID TAG valore)
            if (preg_match('/^(\d+)\s+(@\w+@)?\s*(\w+)\s*(.*)$/', $riga, $matches)) {
                $livello = (int)$matches[1];
                $id = $matches[2] ?? null;
                $tag = $matches[3];
                $valore = trim($matches[4] ?? '');

                // Gestisci stack per gestire livelli annidati
                while (count($stack) > 0 && $stack[count($stack) - 1]['livello'] >= $livello) {
                    if (isset($stack[count($stack) - 1]['tipo']) && $stack[count($stack) - 1]['tipo'] === 'INDI' && isset($individuoCorrente)) {
                        $persone[$individuoCorrente['id']] = $individuoCorrente;
                    }
                    array_pop($stack);
                }

                if ($tag === 'INDI' && $id) {
                    $individuoCorrente = [
                        'id' => $id,
                        'nome' => '',
                        'cognome' => '',
                        'nato_il' => null,
                        'nato_a' => null,
                        'deceduto_il' => null,
                        'deceduto_a' => null,
                    ];
                    $stack[] = ['livello' => $livello, 'tipo' => 'INDI', 'dati' => &$individuoCorrente];
                } elseif ($tag === 'NAME' && isset($individuoCorrente)) {
                    // Parsa nome GEDCOM formato: Nome /Cognome/
                    if (preg_match('/^(.+?)\s+\/(.+?)\//', $valore, $nameMatches)) {
                        $individuoCorrente['nome'] = trim($nameMatches[1]);
                        $individuoCorrente['cognome'] = trim($nameMatches[2]);
                    } else {
                        $individuoCorrente['nome'] = $valore;
                    }
                } elseif ($tag === 'BIRT' && isset($individuoCorrente)) {
                    $stack[] = ['livello' => $livello, 'tipo' => 'BIRT', 'dati' => []];
                } elseif ($tag === 'DEAT' && isset($individuoCorrente)) {
                    $stack[] = ['livello' => $livello, 'tipo' => 'DEAT', 'dati' => []];
                } elseif ($tag === 'DATE' && count($stack) > 0 && isset($individuoCorrente)) {
                    $ultimo = &$stack[count($stack) - 1];
                    if ($ultimo['tipo'] === 'BIRT') {
                        $individuoCorrente['nato_il'] = $this->parseGedcomDate($valore);
                    } elseif ($ultimo['tipo'] === 'DEAT') {
                        $individuoCorrente['deceduto_il'] = $this->parseGedcomDate($valore);
                    }
                } elseif ($tag === 'PLAC' && count($stack) > 0 && isset($individuoCorrente)) {
                    $ultimo = &$stack[count($stack) - 1];
                    if ($ultimo['tipo'] === 'BIRT') {
                        $individuoCorrente['nato_a'] = $valore;
                    } elseif ($ultimo['tipo'] === 'DEAT') {
                        $individuoCorrente['deceduto_a'] = $valore;
                    }
                } elseif ($tag === 'FAM' && $id) {
                    // Gestione famiglie (per relazioni)
                    $famiglie[$id] = [];
                }
            }
        }

        // Aggiungi l'ultimo individuo se presente
        if (isset($individuoCorrente)) {
            $persone[$individuoCorrente['id']] = $individuoCorrente;
        }

        // Importa le persone nel database
        $importate = 0;
        $errori = [];

        DB::beginTransaction();
        try {
            foreach ($persone as $personaGedcom) {
                try {
                    Persona::create([
                        'nome' => $personaGedcom['nome'] ?? '',
                        'cognome' => $personaGedcom['cognome'] ?? '',
                        'nato_il' => $personaGedcom['nato_il'] ?? null,
                        'nato_a' => $personaGedcom['nato_a'] ?? null,
                        'deceduto_il' => $personaGedcom['deceduto_il'] ?? null,
                        'deceduto_a' => $personaGedcom['deceduto_a'] ?? null,
                    ]);
                    $importate++;
                } catch (\Exception $e) {
                    $errori[] = "Errore nell'importazione di {$personaGedcom['nome']} {$personaGedcom['cognome']}: " . $e->getMessage();
                    Log::error('Errore importazione GEDCOM', ['persona' => $personaGedcom, 'errore' => $e->getMessage()]);
                }
            }
            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return [
            'importate' => $importate,
            'errori' => $errori,
        ];
    }

    /**
     * Converte una data GEDCOM in formato YYYY-MM-DD
     */
    private function parseGedcomDate(string $gedcomDate): ?string
    {
        // GEDCOM usa formato: DD MMM YYYY (es: 15 JAN 1990)
        try {
            $date = \Carbon\Carbon::parse($gedcomDate);
            return $date->format('Y-m-d');
        } catch (\Exception $e) {
            Log::warning('Errore nel parsing data GEDCOM', ['data' => $gedcomDate]);
            return null;
        }
    }
}

