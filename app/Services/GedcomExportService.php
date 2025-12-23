<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Persona;
use Illuminate\Support\Facades\DB;

class GedcomExportService
{
    /**
     * Genera un file GEDCOM per tutte le persone
     */
    public function exportAll(): string
    {
        // Carica tutte le persone senza eager loading delle relazioni custom
        // perché padreRel, madreRel, consorti e figli non sono relazioni Eloquent standard
        $persone = Persona::all();
        
        $gedcom = "0 HEAD\n";
        $gedcom .= "1 SOUR Nuovo Albero Genealogico\n";
        $gedcom .= "1 GEDC\n";
        $gedcom .= "2 VERS 5.5.1\n";
        $gedcom .= "2 FORM LINEAGE-LINKED\n";
        $gedcom .= "1 CHAR UTF-8\n";
        $gedcom .= "0 @F1@ FAM\n";
        
        foreach ($persone as $persona) {
            $gedcom .= $this->exportPersona($persona);
        }
        
        $gedcom .= "0 TRLR\n";
        
        return $gedcom;
    }

    /**
     * Genera un file GEDCOM per una persona specifica e la sua famiglia
     */
    public function exportFromPersona(int $personaId): string
    {
        // Carica la persona senza eager loading delle relazioni custom
        $persona = Persona::findOrFail($personaId);
        
        $gedcom = "0 HEAD\n";
        $gedcom .= "1 SOUR Nuovo Albero Genealogico\n";
        $gedcom .= "1 GEDC\n";
        $gedcom .= "2 VERS 5.5.1\n";
        $gedcom .= "2 FORM LINEAGE-LINKED\n";
        $gedcom .= "1 CHAR UTF-8\n";
        
        $exported = [];
        $gedcom .= $this->exportPersonaRecursive($persona, $exported);
        
        $gedcom .= "0 TRLR\n";
        
        return $gedcom;
    }

    /**
     * Esporta una persona in formato GEDCOM
     */
    private function exportPersona(Persona $persona): string
    {
        $gedcom = "0 @I{$persona->id}@ INDI\n";
        
        // Gestisci nomi vuoti o null
        $nome = $persona->nome ?? '';
        $cognome = $persona->cognome ?? '';
        $gedcom .= "1 NAME {$nome} /{$cognome}/\n";
        
        if ($persona->nato_il || $persona->nato_a) {
            $gedcom .= "1 BIRT\n";
            if ($persona->nato_il) {
                $gedcom .= "2 DATE " . $persona->nato_il->format('d M Y') . "\n";
            }
            if ($persona->nato_a) {
                $gedcom .= "2 PLAC {$persona->nato_a}\n";
            }
        }
        
        if ($persona->deceduto_il || $persona->deceduto_a) {
            $gedcom .= "1 DEAT\n";
            if ($persona->deceduto_il) {
                $gedcom .= "2 DATE " . $persona->deceduto_il->format('d M Y') . "\n";
            }
            if ($persona->deceduto_a) {
                $gedcom .= "2 PLAC {$persona->deceduto_a}\n";
            }
        }
        
        // Famiglia come figlio
        $padre = $persona->padreRel();
        $madre = $persona->madreRel();
        if ($padre || $madre) {
            $famId = "F{$persona->id}";
            $gedcom .= "1 FAMC @{$famId}@\n";
        }
        
        // Famiglie come coniuge/genitore
        $consorti = $persona->consorti();
        foreach ($consorti as $index => $consorte) {
            if ($consorte) {
                $famId = "F{$persona->id}_{$index}";
                $gedcom .= "1 FAMS @{$famId}@\n";
            }
        }
        
        return $gedcom;
    }

    /**
     * Esporta una persona ricorsivamente con la sua famiglia
     */
    private function exportPersonaRecursive(Persona $persona, array &$exported): string
    {
        if (isset($exported[$persona->id])) {
            return '';
        }
        
        $exported[$persona->id] = true;
        $gedcom = $this->exportPersona($persona);
        
        // Esporta genitori
        if ($persona->padreRel()) {
            $gedcom .= $this->exportPersonaRecursive($persona->padreRel(), $exported);
        }
        if ($persona->madreRel()) {
            $gedcom .= $this->exportPersonaRecursive($persona->madreRel(), $exported);
        }
        
        // Esporta consorti
        foreach ($persona->consorti() as $consorte) {
            $gedcom .= $this->exportPersonaRecursive($consorte, $exported);
        }
        
        // Esporta figli
        foreach ($persona->figli() as $figlio) {
            $gedcom .= $this->exportPersonaRecursive($figlio, $exported);
        }
        
        return $gedcom;
    }
}


