<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Persona;
use Illuminate\Support\Collection;

class DataValidationService
{
    /**
     * Valida tutte le date per coerenza
     */
    public function validateDates(): Collection
    {
        $problemi = collect();
        $persone = Persona::all();

        foreach ($persone as $persona) {
            // Controlla che la data di morte sia dopo la data di nascita
            if ($persona->nato_il && $persona->deceduto_il) {
                if ($persona->deceduto_il < $persona->nato_il) {
                    $problemi->push([
                        'tipo' => 'date_incoerenti',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => 'La data di morte è precedente alla data di nascita',
                        'severita' => 'alta',
                    ]);
                }
            }

            // Controlla che la persona non sia troppo vecchia (più di 150 anni)
            if ($persona->nato_il) {
                $dataFine = $persona->deceduto_il ?? now();
                $eta = $persona->nato_il->diffInYears($dataFine);
                if ($eta > 150) {
                    $problemi->push([
                        'tipo' => 'eta_improbabile',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => "Età improbabile: {$eta} anni",
                        'severita' => 'media',
                    ]);
                }
            }
        }

        return $problemi;
    }

    /**
     * Trova possibili duplicati
     */
    public function findDuplicates(): Collection
    {
        $problemi = collect();
        $persone = Persona::all();

        foreach ($persone as $persona) {
            $duplicati = Persona::where('id', '!=', $persona->id)
                ->where('nome', $persona->nome)
                ->where('cognome', $persona->cognome)
                ->where('nato_il', $persona->nato_il)
                ->get();

            if ($duplicati->isNotEmpty()) {
                $problemi->push([
                    'tipo' => 'duplicato',
                    'persona_id' => $persona->id,
                    'persona_nome' => $persona->nome_completo,
                    'messaggio' => 'Possibile duplicato trovato',
                    'severita' => 'media',
                    'duplicati' => $duplicati->pluck('id')->toArray(),
                ]);
            }
        }

        return $problemi;
    }

    /**
     * Valida le relazioni familiari
     */
    public function checkRelationships(): Collection
    {
        $problemi = collect();
        $persone = Persona::all();

        foreach ($persone as $persona) {
            $padre = $persona->padreRel();
            $madre = $persona->madreRel();

            // Controlla che il padre non sia più giovane del figlio
            if ($padre && $persona->nato_il && $padre->nato_il) {
                if ($padre->nato_il > $persona->nato_il) {
                    $problemi->push([
                        'tipo' => 'relazione_impossibile',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => 'Il padre è più giovane del figlio',
                        'severita' => 'alta',
                    ]);
                }
            }

            // Controlla che la madre non sia più giovane del figlio
            if ($madre && $persona->nato_il && $madre->nato_il) {
                if ($madre->nato_il > $persona->nato_il) {
                    $problemi->push([
                        'tipo' => 'relazione_impossibile',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => 'La madre è più giovane del figlio',
                        'severita' => 'alta',
                    ]);
                }
            }

            // Controlla che il padre e la madre non siano troppo giovani (minimo 13 anni)
            if ($padre && $persona->nato_il && $padre->nato_il) {
                $etaPadre = $padre->nato_il->diffInYears($persona->nato_il);
                if ($etaPadre < 13) {
                    $problemi->push([
                        'tipo' => 'eta_genitore_improbabile',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => "Il padre aveva solo {$etaPadre} anni alla nascita del figlio",
                        'severita' => 'media',
                    ]);
                }
            }

            if ($madre && $persona->nato_il && $madre->nato_il) {
                $etaMadre = $madre->nato_il->diffInYears($persona->nato_il);
                if ($etaMadre < 13) {
                    $problemi->push([
                        'tipo' => 'eta_genitore_improbabile',
                        'persona_id' => $persona->id,
                        'persona_nome' => $persona->nome_completo,
                        'messaggio' => "La madre aveva solo {$etaMadre} anni alla nascita del figlio",
                        'severita' => 'media',
                    ]);
                }
            }
        }

        return $problemi;
    }

    /**
     * Esegue tutti i controlli di validazione
     */
    public function runAllChecks(): array
    {
        return [
            'date' => $this->validateDates(),
            'duplicati' => $this->findDuplicates(),
            'relazioni' => $this->checkRelationships(),
        ];
    }
}

