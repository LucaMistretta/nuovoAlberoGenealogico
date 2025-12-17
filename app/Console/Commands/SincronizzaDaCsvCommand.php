<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\Persona;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class SincronizzaDaCsvCommand extends Command
{
    protected $signature = 'persone:sincronizza-csv 
                            {--csv-path= : Percorso del file CSV (default: database/LISTA.csv)}
                            {--dry-run : Mostra solo cosa verrebbe aggiornato senza modificare il database}
                            {--force : Aggiorna anche i campi già presenti}
                            {--match-by= : Metodo di matching: indice, nome, entrambi (default: entrambi)}
                            {--show-missing : Mostra dettagli sulle righe non trovate}';

    protected $description = 'Sincronizza i dati mancanti dal file CSV al database SQLite';

    private array $csvData = [];
    private int $aggiornate = 0;
    private int $nonTrovate = 0;
    private int $errori = 0;
    private array $righeNonTrovate = [];

    public function handle(): int
    {
        $csvPath = $this->option('csv-path') ?: database_path('LISTA.csv');

        if (!file_exists($csvPath)) {
            $this->error("File CSV non trovato: {$csvPath}");
            $this->info("Usa --csv-path per specificare un percorso diverso");
            return Command::FAILURE;
        }

        $this->info("Lettura file CSV: {$csvPath}");

        try {
            // Leggi il CSV
            $this->leggiCsv($csvPath);
            $this->info("Trovate " . count($this->csvData) . " righe nel CSV");

            $dryRun = $this->option('dry-run');
            $force = $this->option('force');
            $matchBy = $this->option('match-by') ?: 'entrambi';

            if ($dryRun) {
                $this->warn("Modalità DRY-RUN: nessuna modifica verrà applicata");
            }

            if ($force) {
                $this->warn("Modalità FORCE: aggiornerà anche i campi già presenti");
            }

            $this->info("Metodo di matching: {$matchBy}");

            // Ottieni tutte le persone dal database
            $persone = Persona::all();
            $this->info("Trovate " . $persone->count() . " persone nel database");

            $bar = $this->output->createProgressBar(count($this->csvData));
            $bar->start();

            DB::beginTransaction();

            foreach ($this->csvData as $csvRow) {
                try {
                    $persona = $this->trovaPersona($csvRow, $persone, $matchBy);

                    if ($persona) {
                        $aggiornata = $this->aggiornaPersona($persona, $csvRow, $force, $dryRun);
                        if ($aggiornata) {
                            $this->aggiornate++;
                        }
                    } else {
                        $this->nonTrovate++;
                        if ($this->option('show-missing')) {
                            $this->righeNonTrovate[] = [
                                'indice' => $csvRow['indice'] ?? 'N/A',
                                'nome' => $csvRow['nome'] ?? 'N/A'
                            ];
                        }
                    }
                } catch (\Exception $e) {
                    $this->errori++;
                    if (!$dryRun) {
                        $this->newLine();
                        $this->error("Errore per riga CSV indice {$csvRow['indice']}: " . $e->getMessage());
                    }
                }

                $bar->advance();
            }

            $bar->finish();
            $this->newLine(2);

            if ($dryRun) {
                DB::rollBack();
                $this->info("DRY-RUN completato. Nessuna modifica applicata.");
            } else {
                DB::commit();
                $this->info("✅ Aggiornate {$this->aggiornate} persone");
            }

            if ($this->nonTrovate > 0) {
                $this->warn("⚠️  {$this->nonTrovate} righe CSV non hanno trovato corrispondenza nel database");
                
                if ($this->option('show-missing') && !empty($this->righeNonTrovate)) {
                    $this->newLine();
                    $this->info("Prime 20 righe non trovate:");
                    foreach (array_slice($this->righeNonTrovate, 0, 20) as $riga) {
                        $this->line("  Indice {$riga['indice']}: {$riga['nome']}");
                    }
                    if (count($this->righeNonTrovate) > 20) {
                        $this->line("  ... e altre " . (count($this->righeNonTrovate) - 20) . " righe");
                    }
                }
            }

            if ($this->errori > 0) {
                $this->error("❌ {$this->errori} errori durante l'elaborazione");
            }

            return Command::SUCCESS;

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error("Errore: " . $e->getMessage());
            $this->error($e->getTraceAsString());
            return Command::FAILURE;
        }
    }

    /**
     * Legge il file CSV e popola l'array csvData
     */
    private function leggiCsv(string $csvPath): void
    {
        $handle = fopen($csvPath, 'r');
        if ($handle === false) {
            throw new \Exception("Impossibile aprire il file CSV");
        }

        // Leggi l'header
        $headers = fgetcsv($handle);
        if ($headers === false) {
            fclose($handle);
            throw new \Exception("File CSV vuoto o formato non valido");
        }

        // Normalizza gli header (rimuovi spazi, converti in minuscolo)
        $headers = array_map('trim', $headers);
        $headers = array_map('strtolower', $headers);

        $this->csvData = [];

        while (($row = fgetcsv($handle)) !== false) {
            if (count($row) !== count($headers)) {
                continue; // Salta righe con numero di colonne diverso
            }

            $data = array_combine($headers, $row);
            
            // Pulisci i dati (rimuovi spazi, gestisci valori vuoti)
            foreach ($data as $key => $value) {
                $data[$key] = trim($value);
                if ($data[$key] === '' || $data[$key] === '0.0000000000000000e+00') {
                    $data[$key] = null;
                }
            }

            // Salta righe senza indice o nome
            if (empty($data['indice']) || empty($data['nome'])) {
                continue;
            }

            $this->csvData[] = $data;
        }

        fclose($handle);
    }

    /**
     * Trova la persona corrispondente nel database
     */
    private function trovaPersona(array $csvRow, $persone, string $matchBy): ?Persona
    {
        $indice = $this->normalizzaIndice($csvRow['indice'] ?? null);
        $nomeCompleto = trim($csvRow['nome'] ?? '');

        if (empty($nomeCompleto)) {
            return null;
        }

        // Estrai nome e cognome dal CSV (formato: "COGNOME NOME")
        $parts = explode(' ', $nomeCompleto, 2);
        $cognomeCsv = trim($parts[0] ?? '');
        $nomeCsv = trim($parts[1] ?? '');

        foreach ($persone as $persona) {
            $trovata = false;

            // Match per indice (se disponibile)
            if ($matchBy === 'indice' || $matchBy === 'entrambi') {
                // Qui potresti avere un campo indice nel database, altrimenti usa l'ID
                // Per ora usiamo solo il matching per nome
            }

            // Match per nome e cognome
            if ($matchBy === 'nome' || $matchBy === 'entrambi') {
                if ($persona->cognome && $persona->nome) {
                    // Normalizza i nomi rimuovendo spazi extra e convertendo in minuscolo
                    $cognomePersonaNorm = strtolower(trim($persona->cognome));
                    $nomePersonaNorm = strtolower(trim($persona->nome));
                    $cognomeCsvNorm = strtolower(trim($cognomeCsv));
                    $nomeCsvNorm = strtolower(trim($nomeCsv));
                    
                    // Confronto case-insensitive esatto (CSV: "COGNOME NOME", DB: "COGNOME NOME")
                    if ($cognomePersonaNorm === $cognomeCsvNorm && $nomePersonaNorm === $nomeCsvNorm) {
                        $trovata = true;
                    }
                    // Confronto inverso (CSV: "COGNOME NOME", DB: "NOME COGNOME")
                    elseif ($nomePersonaNorm === $cognomeCsvNorm && $cognomePersonaNorm === $nomeCsvNorm) {
                        $trovata = true;
                    }
                    // Match solo sul cognome (gestisce casi come "ORLANDO CARMELA" vs "CARMELA ORLANDO")
                    elseif ($cognomePersonaNorm === $cognomeCsvNorm || $cognomePersonaNorm === $nomeCsvNorm) {
                        // Se il cognome corrisponde, controlla anche il nome
                        if ($nomePersonaNorm === $nomeCsvNorm || $nomePersonaNorm === $cognomeCsvNorm) {
                            $trovata = true;
                        }
                        // Match parziale sul nome (gestisce casi come "MISTRETTA VINCENZO sen." vs "VINCENZO MISTRETTA")
                        elseif (strpos($nomePersonaNorm, $nomeCsvNorm) !== false || 
                                strpos($nomeCsvNorm, $nomePersonaNorm) !== false ||
                                strpos($nomePersonaNorm, $cognomeCsvNorm) !== false ||
                                strpos($cognomeCsvNorm, $nomePersonaNorm) !== false) {
                            $trovata = true;
                        }
                    }
                    // Match solo sul nome (gestisce casi dove cognome e nome sono invertiti)
                    elseif ($nomePersonaNorm === $cognomeCsvNorm || $nomePersonaNorm === $nomeCsvNorm) {
                        if ($cognomePersonaNorm === $nomeCsvNorm || $cognomePersonaNorm === $cognomeCsvNorm) {
                            $trovata = true;
                        }
                    }
                } elseif ($persona->nome && !$persona->cognome) {
                    // Se nel DB c'è solo il nome, confronta con il nome completo del CSV
                    $nomePersonaLower = strtolower(trim($persona->nome));
                    $nomeCompletoLower = strtolower(trim($nomeCompleto));
                    
                    if ($nomePersonaLower === $nomeCompletoLower) {
                        $trovata = true;
                    }
                    // Match parziale
                    elseif (strpos($nomePersonaLower, $nomeCompletoLower) !== false ||
                            strpos($nomeCompletoLower, $nomePersonaLower) !== false) {
                        $trovata = true;
                    }
                    // Match con parte del nome completo CSV
                    elseif (strpos($nomePersonaLower, $cognomeCsvNorm) !== false ||
                            strpos($nomePersonaLower, $nomeCsvNorm) !== false) {
                        $trovata = true;
                    }
                } elseif ($persona->cognome && !$persona->nome) {
                    // Se nel DB c'è solo il cognome
                    $cognomePersonaLower = strtolower(trim($persona->cognome));
                    $nomeCompletoLower = strtolower(trim($nomeCompleto));
                    
                    if ($cognomePersonaLower === $cognomeCsvNorm || $cognomePersonaLower === $nomeCompletoLower) {
                        $trovata = true;
                    }
                }
            }

            if ($trovata) {
                return $persona;
            }
        }

        return null;
    }

    /**
     * Aggiorna la persona con i dati del CSV (solo campi mancanti)
     */
    private function aggiornaPersona(Persona $persona, array $csvRow, bool $force, bool $dryRun): bool
    {
        $modifiche = [];
        $aggiornata = false;

        // Data di nascita
        if (empty($persona->nato_il) || $force) {
            $natoIl = $this->parseDate($csvRow['nato_il'] ?? null);
            if ($natoIl && ($force || empty($persona->nato_il))) {
                $modifiche['nato_il'] = $natoIl;
                $aggiornata = true;
            }
        }

        // Luogo di nascita
        if (empty($persona->nato_a) || $force) {
            $natoA = $this->pulisciStringa($csvRow['nato_a'] ?? null);
            if ($natoA && ($force || empty($persona->nato_a))) {
                $modifiche['nato_a'] = $natoA;
                $aggiornata = true;
            }
        }

        // Data di decesso
        if (empty($persona->deceduto_il) || $force) {
            $decedutoIl = $this->parseDate($csvRow['deceduto_il'] ?? null);
            if ($decedutoIl && ($force || empty($persona->deceduto_il))) {
                $modifiche['deceduto_il'] = $decedutoIl;
                $aggiornata = true;
            }
        }

        // Luogo di decesso
        if (empty($persona->deceduto_a) || $force) {
            $decedutoA = $this->pulisciStringa($csvRow['deceduto_a'] ?? null);
            if ($decedutoA && ($force || empty($persona->deceduto_a))) {
                $modifiche['deceduto_a'] = $decedutoA;
                $aggiornata = true;
            }
        }

        // Aggiorna nome e cognome se mancanti
        if (empty($persona->nome) || empty($persona->cognome)) {
            $nomeCompleto = trim($csvRow['nome'] ?? '');
            if ($nomeCompleto) {
                $parts = explode(' ', $nomeCompleto, 2);
                $cognome = trim($parts[0] ?? '');
                $nome = trim($parts[1] ?? '');

                if (empty($persona->cognome) && $cognome) {
                    $modifiche['cognome'] = $cognome;
                    $aggiornata = true;
                }
                if (empty($persona->nome) && $nome) {
                    $modifiche['nome'] = $nome;
                    $aggiornata = true;
                }
            }
        }

        if ($aggiornata && !empty($modifiche)) {
            if ($dryRun) {
                $this->newLine();
                $this->line("  [DRY-RUN] ID {$persona->id}: {$persona->nome} {$persona->cognome}");
                foreach ($modifiche as $campo => $valore) {
                    $this->line("    {$campo}: {$valore}");
                }
            } else {
                foreach ($modifiche as $campo => $valore) {
                    $persona->$campo = $valore;
                }
                $persona->save();
            }
        }

        return $aggiornata;
    }

    /**
     * Normalizza l'indice (converte da formato scientifico a intero)
     */
    private function normalizzaIndice(?string $indice): ?int
    {
        if (empty($indice)) {
            return null;
        }

        // Gestisci formato scientifico (es. 2.0000000000000000e+00)
        if (stripos($indice, 'e+') !== false || stripos($indice, 'e-') !== false) {
            $valore = (float) $indice;
            return (int) $valore;
        }

        return (int) $indice;
    }

    /**
     * Pulisce una stringa rimuovendo caratteri problematici
     */
    private function pulisciStringa(?string $valore): ?string
    {
        if (empty($valore)) {
            return null;
        }

        $valore = trim($valore);
        
        // Rimuovi caratteri di controllo e normalizza spazi
        $valore = preg_replace('/\s+/', ' ', $valore);
        
        return $valore ?: null;
    }

    /**
     * Converte una stringa data in formato YYYY-MM-DD o null
     */
    private function parseDate(?string $date): ?string
    {
        if (empty($date)) {
            return null;
        }

        $date = trim($date);

        // Gestisci formato "MM/DD/YY HH:MM:SS" o "MM/DD/YY"
        if (preg_match('/^(\d{2})\/(\d{2})\/(\d{2})/', $date, $matches)) {
            $mese = $matches[1];
            $giorno = $matches[2];
            $anno = (int)$matches[3];
            
            // Per date storiche in un albero genealogico, assumiamo sempre 1900+ per anni a 2 cifre
            // Se l'anno è < 50, probabilmente è 1900+ (es. 02 = 1902, 25 = 1925)
            // Se l'anno è >= 50, è sicuramente 1900+ (es. 62 = 1962)
            // Solo per anni molto recenti (< 10) potremmo considerare 2000+
            if ($anno < 10) {
                // Anni 00-09: potrebbe essere 2000+ o 1900+, proviamo prima 2000+
                $annoCompleto = 2000 + $anno;
            } else {
                // Anni 10+: assumiamo sempre 1900+ per date storiche
                $annoCompleto = 1900 + $anno;
            }
            
            try {
                $dateObj = new \DateTime("{$annoCompleto}-{$mese}-{$giorno}");
                $annoRisultato = (int)$dateObj->format('Y');
                
                // Se la data risultante è nel futuro (oltre il 2024), probabilmente è un errore
                // Correggi assumendo che sia 1900+
                if ($annoRisultato > 2024 && $anno < 50) {
                    $annoCompleto = 1900 + $anno;
                    $dateObj = new \DateTime("{$annoCompleto}-{$mese}-{$giorno}");
                }
                
                return $dateObj->format('Y-m-d');
            } catch (\Exception $e) {
                // Ignora errori
            }
        }

        // Gestisci formato "DD/MM/YYYY" (formato italiano)
        if (preg_match('/^(\d{2})\/(\d{2})\/(\d{4})/', $date, $matches)) {
            $giorno = $matches[1];
            $mese = $matches[2];
            $annoCompleto = (int)$matches[3];
            
            try {
                $dateObj = new \DateTime("{$annoCompleto}-{$mese}-{$giorno}");
                return $dateObj->format('Y-m-d');
            } catch (\Exception $e) {
                // Ignora errori
            }
        }

        // Prova altri formati
        $formats = ['Y-m-d', 'd/m/Y', 'd-m-Y', 'Y/m/d', 'd.m.Y'];
        
        foreach ($formats as $format) {
            $parsed = \DateTime::createFromFormat($format, $date);
            if ($parsed !== false) {
                $annoRisultato = (int)$parsed->format('Y');
                // Se la data è nel futuro oltre il 2024, potrebbe essere un errore
                if ($annoRisultato > 2024) {
                    continue; // Prova il formato successivo
                }
                return $parsed->format('Y-m-d');
            }
        }

        // Prova anche con DateTime normale
        try {
            $dateObj = new \DateTime($date);
            $annoRisultato = (int)$dateObj->format('Y');
            // Se la data è nel futuro oltre il 2024, potrebbe essere un errore
            if ($annoRisultato > 2024) {
                return null;
            }
            return $dateObj->format('Y-m-d');
        } catch (\Exception $e) {
            // Ignora errori
        }

        return null;
    }
}

