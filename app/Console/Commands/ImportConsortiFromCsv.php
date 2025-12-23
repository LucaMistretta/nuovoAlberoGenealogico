<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\Persona;
use App\Models\PersonaLegame;
use App\Models\TipoLegame;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ImportConsortiFromCsv extends Command
{
    protected $signature = 'import:consorti-csv {--file=database/coniugi.csv} {--preview}';
    protected $description = 'Importa i consorti e i dati del matrimonio dal file CSV';

    private array $previewData = [];

    public function handle(): int
    {
        $filePath = $this->option('file');
        $preview = $this->option('preview');
        
        if (!file_exists($filePath)) {
            $this->error("File non trovato: {$filePath}");
            return 1;
        }

        // Ottieni il tipo di legame "coniuge"
        $tipoConiuge = TipoLegame::where('nome', 'coniuge')->first();
        if (!$tipoConiuge) {
            $this->error('Tipo di legame "coniuge" non trovato nel database');
            return 1;
        }

        // Ottieni il tipo evento legame "matrimonio" se disponibile
        $tipoEventoMatrimonio = \App\Models\TipoEventoLegame::where('nome', 'matrimonio')->first();
        $tipoEventoMatrimonioId = $tipoEventoMatrimonio ? $tipoEventoMatrimonio->id : null;

        $this->info("Analisi del file {$filePath}...");
        
        $handle = fopen($filePath, 'r');
        if (!$handle) {
            $this->error("Impossibile aprire il file: {$filePath}");
            return 1;
        }

        // Leggi l'header
        $header = fgetcsv($handle);
        if (!$header) {
            $this->error("Impossibile leggere l'header del file CSV");
            fclose($handle);
            return 1;
        }

        $rigaNum = 1;
        $previewData = [];

        // Prima passata: analisi e preview
        while (($row = fgetcsv($handle)) !== false) {
            $rigaNum++;
            
            // Crea un array associativo dalla riga
            $data = array_combine($header, $row);
            
            if (!$data) {
                continue;
            }

            $indice = isset($data['indice']) ? (int)trim($data['indice']) : 0;
            $nomeConsorteCsv = isset($data['nome_consorte']) ? trim($data['nome_consorte']) : '';
            $consorteIdCsv = isset($data['consorte']) ? (int)trim($data['consorte']) : 0;
            $coniugatoA = isset($data['coniugato_a']) ? trim($data['coniugato_a']) : '';
            $coniugatoIl = isset($data['coniugato_il']) ? trim($data['coniugato_il']) : '';

            // Salta se non c'è un consorte valido
            if ($indice <= 0 || empty($nomeConsorteCsv)) {
                continue;
            }

            // Trova la persona
            $persona = Persona::find($indice);
            if (!$persona) {
                $previewData[] = [
                    'riga' => $rigaNum,
                    'persona_id' => $indice,
                    'persona_nome' => 'NON TROVATA',
                    'consorte_nome_csv' => $nomeConsorteCsv,
                    'consorte_id' => null,
                    'consorte_nome_db' => null,
                    'data_legame' => $this->convertiData($coniugatoIl),
                    'luogo_legame' => !empty($coniugatoA) ? trim($coniugatoA) : null,
                    'esiste_legame' => false,
                    'errore' => "Persona con ID {$indice} non trovata",
                ];
                continue;
            }

            // Trova il consorte per nome, validando anche con l'ID del CSV se disponibile
            $consorte = $this->trovaConsortePerNome($nomeConsorteCsv, $consorteIdCsv);
            
            if (!$consorte) {
                $previewData[] = [
                    'riga' => $rigaNum,
                    'persona_id' => $indice,
                    'persona_nome' => $persona->nome . ' ' . $persona->cognome,
                    'consorte_nome_csv' => $nomeConsorteCsv,
                    'consorte_id' => null,
                    'consorte_nome_db' => null,
                    'data_legame' => $this->convertiData($coniugatoIl),
                    'luogo_legame' => !empty($coniugatoA) ? trim($coniugatoA) : null,
                    'esiste_legame' => false,
                    'errore' => "Consorte '{$nomeConsorteCsv}' non trovato nel database",
                ];
                continue;
            }

            // Verifica se esiste già il legame
            $legameEsistente = PersonaLegame::where('persona_id', $indice)
                ->where('persona_collegata_id', $consorte->id)
                ->where('tipo_legame_id', $tipoConiuge->id)
                ->first();

            $previewData[] = [
                'riga' => $rigaNum,
                'persona_id' => $indice,
                'persona_nome' => $persona->nome . ' ' . $persona->cognome,
                'consorte_nome_csv' => $nomeConsorteCsv,
                'consorte_id' => $consorte->id,
                'consorte_nome_db' => $consorte->nome . ' ' . $consorte->cognome,
                'data_legame' => $this->convertiData($coniugatoIl),
                'luogo_legame' => !empty($coniugatoA) ? trim($coniugatoA) : null,
                'esiste_legame' => $legameEsistente !== null,
            ];
        }

        fclose($handle);

        // Mostra preview
        $this->mostraPreview($previewData);

        // Se è solo preview, esci
        if ($preview) {
            return 0;
        }

        // Chiedi conferma
        if (!$this->confirm('Vuoi procedere con l\'importazione?', true)) {
            $this->info('Importazione annullata.');
            return 0;
        }

        // Seconda passata: importazione
        return $this->importaDati($filePath, $tipoConiuge->id, $tipoEventoMatrimonioId, $previewData);
    }

    /**
     * Trova il consorte nel database confrontando il nome
     * Valida anche con l'ID del CSV se disponibile (deve corrispondere o essere entro ±1)
     * 
     * @param string $nomeConsorteCsv Nome del consorte dal CSV
     * @param int|null $consorteIdCsv ID del consorte dal CSV (opzionale, per validazione)
     * @return Persona|null
     */
    private function trovaConsortePerNome(string $nomeConsorteCsv, ?int $consorteIdCsv = null): ?Persona
    {
        // Normalizza il nome: rimuovi spazi multipli e trim
        $nomeNormalizzato = preg_replace('/\s+/', ' ', trim($nomeConsorteCsv));
        
        if (empty($nomeNormalizzato)) {
            return null;
        }

        // Prova a dividere in parti (potrebbe essere "COGNOME NOME" o "NOME COGNOME")
        $parti = array_filter(array_map('trim', explode(' ', $nomeNormalizzato)));
        $parti = array_values($parti); // Re-indicizza l'array
        
        if (count($parti) < 1) {
            return null;
        }

        if (count($parti) === 1) {
            // Se c'è solo una parola, cerca per cognome esatto (più probabile)
            return Persona::whereRaw("UPPER(TRIM(cognome)) = ?", [strtoupper($parti[0])])
                ->first();
        }

        // Se ci sono più parti, prendi le prime due come cognome e nome
        // Nel CSV l'ordine è tipicamente "COGNOME NOME", nel DB è "NOME COGNOME"
        $primaParte = strtoupper(trim($parti[0]));
        $secondaParte = strtoupper(trim($parti[1]));

        // Prova prima con "COGNOME NOME" -> DB "NOME COGNOME" (ordine inverso)
        // Cerca cognome che corrisponde alla prima parte, nome che contiene la seconda parte
        // Se abbiamo un ID CSV, cerca tutte le corrispondenze e preferisce l'ID che è maggiore di 1
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) LIKE ?",
                [$primaParte, '%' . $secondaParte . '%']
            );
            // Preferisce sempre l'ID che è maggiore di 1 rispetto all'ID del CSV
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
            // Se non trova l'ID corretto, accetta qualsiasi corrispondenza per nome
            if (count($consorti) > 0) {
                return Persona::find($consorti[0]->id);
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) LIKE ? LIMIT 1",
                [$primaParte, '%' . $secondaParte . '%']
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova anche con match esatto del nome (senza spazi iniziali)
        // Se abbiamo un ID CSV, cerca tutte le corrispondenze e preferisce l'ID corretto
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) = ?",
                [$primaParte, $secondaParte]
            );
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) = ? LIMIT 1",
                [$primaParte, $secondaParte]
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova con match che inizia con (per gestire varianti come "VINCENZO sen." vs "VINCENZO")
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) LIKE ?",
                [$primaParte, $secondaParte . '%']
            );
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(cognome)) = ? AND UPPER(TRIM(nome)) LIKE ? LIMIT 1",
                [$primaParte, $secondaParte . '%']
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova con "NOME COGNOME" (ordine inverso) - nel CSV potrebbe essere già in ordine nome cognome
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) LIKE ? AND UPPER(TRIM(cognome)) = ?",
                ['%' . $primaParte . '%', $secondaParte]
            );
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) LIKE ? AND UPPER(TRIM(cognome)) = ? LIMIT 1",
                ['%' . $primaParte . '%', $secondaParte]
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova con "NOME COGNOME" - match esatto
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) = ? AND UPPER(TRIM(cognome)) = ?",
                [$primaParte, $secondaParte]
            );
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) = ? AND UPPER(TRIM(cognome)) = ? LIMIT 1",
                [$primaParte, $secondaParte]
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova con "NOME COGNOME" - match che inizia con
        if ($consorteIdCsv > 0) {
            $consorti = DB::select(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) LIKE ? AND UPPER(TRIM(cognome)) = ?",
                [$primaParte . '%', $secondaParte]
            );
            $idCorretto = $consorteIdCsv + 1;
            foreach ($consorti as $consorte) {
                if ($consorte->id === $idCorretto) {
                    return Persona::find($consorte->id);
                }
            }
        } else {
            $consorte = DB::selectOne(
                "SELECT * FROM persone WHERE UPPER(TRIM(nome)) LIKE ? AND UPPER(TRIM(cognome)) = ? LIMIT 1",
                [$primaParte . '%', $secondaParte]
            );
            if ($consorte) {
                return Persona::find($consorte->id);
            }
        }

        // Prova ricerca più flessibile: cerca il nome completo normalizzato
        $nomeCompletoNormalizzato = strtoupper($nomeNormalizzato);
        $consorte = DB::selectOne(
            "SELECT * FROM persone WHERE UPPER(TRIM(nome || ' ' || cognome)) LIKE ? OR UPPER(TRIM(cognome || ' ' || nome)) LIKE ? LIMIT 1",
            ["%{$nomeCompletoNormalizzato}%", "%{$nomeCompletoNormalizzato}%"]
        );

        if ($consorte) {
            $personaTrovata = Persona::find($consorte->id);
            
            // Valida con l'ID del CSV se disponibile
            if ($personaTrovata && $this->validaIdConsorteSeDisponibile($personaTrovata->id, $consorteIdCsv)) {
                return $personaTrovata;
            }
            // Se l'ID non corrisponde, continua a cercare
        }

        return null;
    }

    /**
     * Valida che l'ID trovato corrisponda all'ID del CSV
     * L'ID giusto è sempre quello che è maggiore di 1 rispetto all'ID del CSV
     * Se l'ID del CSV non è disponibile, restituisce sempre true
     * 
     * @param int $idTrovato ID trovato nel database
     * @param int|null $idCsv ID dal CSV (opzionale)
     * @return bool
     */
    private function validaIdConsorteSeDisponibile(int $idTrovato, ?int $idCsv): bool
    {
        // Se l'ID del CSV non è disponibile, accetta qualsiasi risultato
        if ($idCsv === null || $idCsv <= 0) {
            return true;
        }
        
        // L'ID giusto è sempre quello che è maggiore di 1 rispetto all'ID del CSV
        // Quindi se CSV ha ID 221, l'ID corretto è 222
        return $idTrovato === ($idCsv + 1);
    }

    /**
     * Mostra il preview delle importazioni
     */
    private function mostraPreview(array $previewData): void
    {
        $this->info("\n=== PREVIEW IMPORTAZIONE ===");
        $this->info("Totale righe da processare: " . count($previewData));
        
        $conErrori = array_filter($previewData, fn($d) => isset($d['errore']));
        $senzaErrori = array_filter($previewData, fn($d) => !isset($d['errore']));
        $daCreare = array_filter($senzaErrori, fn($d) => !$d['esiste_legame']);
        $daAggiornare = array_filter($senzaErrori, fn($d) => $d['esiste_legame']);

        $this->info("  - Da creare: " . count($daCreare));
        $this->info("  - Da aggiornare: " . count($daAggiornare));
        $this->info("  - Errori: " . count($conErrori));

        if (count($previewData) > 0) {
            $this->table(
                ['Riga', 'Persona ID', 'Persona', 'Consorte CSV', 'Consorte ID', 'Consorte DB', 'Data', 'Luogo', 'Azione'],
                array_map(function ($d) {
                    $azione = isset($d['errore']) ? 'ERRORE' : ($d['esiste_legame'] ? 'AGGIORNA' : 'CREA');
                    return [
                        $d['riga'],
                        $d['persona_id'],
                        $d['persona_nome'],
                        $d['consorte_nome_csv'],
                        $d['consorte_id'] ?? '-',
                        $d['consorte_nome_db'] ?? '-',
                        $d['data_legame'] ?? '-',
                        $d['luogo_legame'] ?? '-',
                        $azione,
                    ];
                }, array_slice($previewData, 0, 20))
            );

            if (count($previewData) > 20) {
                $this->info("\n... e altre " . (count($previewData) - 20) . " righe");
            }
        }
    }

    /**
     * Importa i dati nel database
     */
    private function importaDati(string $filePath, int $tipoConiugeId, ?int $tipoEventoMatrimonioId, array $previewData): int
    {
        $handle = fopen($filePath, 'r');
        if (!$handle) {
            $this->error("Impossibile aprire il file: {$filePath}");
            return 1;
        }

        // Leggi l'header
        $header = fgetcsv($handle);
        if (!$header) {
            fclose($handle);
            return 1;
        }

        $importati = 0;
        $aggiornati = 0;
        $errori = 0;
        $rigaNum = 1;

        DB::beginTransaction();
        try {
            while (($row = fgetcsv($handle)) !== false) {
                $rigaNum++;
                
                $data = array_combine($header, $row);
                if (!$data) {
                    continue;
                }

                $indice = isset($data['indice']) ? (int)trim($data['indice']) : 0;
                $nomeConsorteCsv = isset($data['nome_consorte']) ? trim($data['nome_consorte']) : '';
                $consorteIdCsv = isset($data['consorte']) ? (int)trim($data['consorte']) : 0;
                $coniugatoA = isset($data['coniugato_a']) ? trim($data['coniugato_a']) : '';
                $coniugatoIl = isset($data['coniugato_il']) ? trim($data['coniugato_il']) : '';

                if ($indice <= 0 || empty($nomeConsorteCsv)) {
                    continue;
                }

                // Trova la persona e il consorte
                $persona = Persona::find($indice);
                $consorte = $this->trovaConsortePerNome($nomeConsorteCsv, $consorteIdCsv);

                if (!$persona || !$consorte) {
                    $errori++;
                    continue;
                }

                // Salta se è un auto-riferimento
                if ($indice === $consorte->id) {
                    continue;
                }

                // Converti la data e il luogo
                $dataLegame = !empty($coniugatoIl) ? $this->convertiData($coniugatoIl) : null;
                $luogoLegame = !empty($coniugatoA) ? trim($coniugatoA) : null;

                // Se abbiamo un ID CSV, elimina TUTTE le relazioni esistenti con consorti che corrispondono a quell'ID o ID+1
                // Questo evita di mantenere relazioni errate
                if ($consorteIdCsv > 0) {
                    $idCorretto = $consorteIdCsv + 1;
                    
                    // Trova tutte le relazioni esistenti con ID che corrispondono al CSV o al CSV+1
                    $relazioniDaEliminare = PersonaLegame::where('persona_id', $indice)
                        ->where('tipo_legame_id', $tipoConiugeId)
                        ->whereIn('persona_collegata_id', [$consorteIdCsv, $idCorretto])
                        ->get();

                    foreach ($relazioniDaEliminare as $relazione) {
                        $consorteIdDaEliminare = $relazione->persona_collegata_id;
                        
                        // Elimina la relazione diretta
                        PersonaLegame::where('persona_id', $indice)
                            ->where('persona_collegata_id', $consorteIdDaEliminare)
                            ->where('tipo_legame_id', $tipoConiugeId)
                            ->delete();

                        // Elimina la relazione inversa
                        PersonaLegame::where('persona_id', $consorteIdDaEliminare)
                            ->where('persona_collegata_id', $indice)
                            ->where('tipo_legame_id', $tipoConiugeId)
                            ->delete();
                    }
                }

                // Elimina anche tutte le relazioni esistenti con il consorte trovato (per sicurezza)
                PersonaLegame::where('persona_id', $indice)
                    ->where('persona_collegata_id', $consorte->id)
                    ->where('tipo_legame_id', $tipoConiugeId)
                    ->delete();

                PersonaLegame::where('persona_id', $consorte->id)
                    ->where('persona_collegata_id', $indice)
                    ->where('tipo_legame_id', $tipoConiugeId)
                    ->delete();

                // Verifica che l'ID del consorte trovato corrisponda all'ID corretto (CSV+1) se abbiamo un ID CSV
                if ($consorteIdCsv > 0) {
                    $idCorretto = $consorteIdCsv + 1;
                    if ($consorte->id !== $idCorretto) {
                        // L'ID non corrisponde, salta questa relazione
                        $errori++;
                        continue;
                    }
                }

                // Crea nuovo legame (sempre nuovo perché abbiamo eliminato tutto prima)
                PersonaLegame::create([
                    'persona_id' => $indice,
                    'persona_collegata_id' => $consorte->id,
                    'tipo_legame_id' => $tipoConiugeId,
                    'data_legame' => $dataLegame,
                    'luogo_legame' => $luogoLegame,
                    'tipo_evento_legame_id' => $tipoEventoMatrimonioId,
                ]);

                // Crea anche la relazione inversa
                PersonaLegame::create([
                    'persona_id' => $consorte->id,
                    'persona_collegata_id' => $indice,
                    'tipo_legame_id' => $tipoConiugeId,
                    'data_legame' => $dataLegame,
                    'luogo_legame' => $luogoLegame,
                    'tipo_evento_legame_id' => $tipoEventoMatrimonioId,
                ]);

                $importati++;

                if (($importati + $aggiornati) % 10 == 0) {
                    $this->info("Processate " . ($importati + $aggiornati) . " relazioni...");
                }
            }

            DB::commit();
            $this->info("\n=== IMPORTAZIONE COMPLETATA ===");
            $this->info("Relazioni create: {$importati}");
            $this->info("Relazioni aggiornate: {$aggiornati}");
            if ($errori > 0) {
                $this->warn("Errori: {$errori}");
            }

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error("Errore durante l'importazione: " . $e->getMessage());
            $this->error("Stack trace: " . $e->getTraceAsString());
            fclose($handle);
            return 1;
        }

        fclose($handle);
        return 0;
    }

    /**
     * Converte la data dal formato CSV a YYYY-MM-DD
     * Gestisce formati come: MM/DD/YY, DD/MM/YYYY, DD/MM/YY
     */
    private function convertiData(string $dataCsv): ?string
    {
        // Rimuovi spazi e caratteri extra
        $dataCsv = trim($dataCsv);
        
        if (empty($dataCsv) || $dataCsv === '0' || $dataCsv === '') {
            return null;
        }

        // Rimuovi la parte dell'ora se presente (00:00:00)
        $dataCsv = preg_replace('/\s+\d{2}:\d{2}:\d{2}/', '', $dataCsv);

        // Se contiene "/", prova a parsare come MM/DD/YY o DD/MM/YY
        if (strpos($dataCsv, '/') !== false) {
            $parti = explode('/', $dataCsv);
            if (count($parti) === 3) {
                $parte1 = (int)trim($parti[0]);
                $parte2 = (int)trim($parti[1]);
                $parte3 = trim($parti[2]);
                
                // Determina se è MM/DD/YY o DD/MM/YY
                // Se la prima parte è > 12, è sicuramente DD/MM
                // Se la seconda parte è > 12, è sicuramente MM/DD
                if ($parte1 > 12) {
                    // Formato DD/MM/YY o DD/MM/YYYY
                    $giorno = $parte1;
                    $mese = $parte2;
                    $anno = (int)$parte3;
                } elseif ($parte2 > 12) {
                    // Formato MM/DD/YY o MM/DD/YYYY
                    $mese = $parte1;
                    $giorno = $parte2;
                    $anno = (int)$parte3;
                } else {
                    // Ambiguo: prova entrambi i formati
                    // Assumiamo MM/DD/YY come default (formato americano comune nei CSV)
                    $mese = $parte1;
                    $giorno = $parte2;
                    $anno = (int)$parte3;
                    
                    // Verifica se la data è valida
                    if (!checkdate($mese, $giorno, $anno < 100 ? 1900 + $anno : $anno)) {
                        // Prova DD/MM/YY
                        $giorno = $parte1;
                        $mese = $parte2;
                    }
                }
                
                // Gestisci anno a 2 cifre
                if ($anno < 100) {
                    // Per date storiche, assumiamo sempre 1900+ (i matrimoni nel 2000+ sono rari nei dati genealogici)
                    $anno = 1900 + $anno;
                }
                
                // Verifica che la data sia valida
                if (checkdate($mese, $giorno, $anno)) {
                    return sprintf('%04d-%02d-%02d', $anno, $mese, $giorno);
                }
            }
        }

        // Prova con DateTime
        try {
            $date = new \DateTime($dataCsv);
            return $date->format('Y-m-d');
        } catch (\Exception $e) {
            // Ignora
        }

        // Se nessun formato funziona, prova con strtotime
        $timestamp = strtotime($dataCsv);
        if ($timestamp !== false) {
            return date('Y-m-d', $timestamp);
        }

        return null;
    }
}
