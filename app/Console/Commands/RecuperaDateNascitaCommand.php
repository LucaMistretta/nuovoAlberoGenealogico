<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\Persona;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RecuperaDateNascitaCommand extends Command
{
    protected $signature = 'persone:recupera-date-nascita 
                            {--db-path= : Percorso del vecchio database SQLite}
                            {--dry-run : Mostra solo cosa verrebbe aggiornato senza modificare il database}
                            {--force : Aggiorna anche le date già presenti}';

    protected $description = 'Recupera le date di nascita mancanti dal vecchio database agene.sqlite';

    public function handle(): int
    {
        $oldDbPath = $this->option('db-path') 
            ?: 'C:\Users\LUCA\Desktop\WEBAPP\PHP\alberoGenealogico\database\agene.sqlite';

        if (!file_exists($oldDbPath)) {
            $this->error("Database SQLite non trovato: {$oldDbPath}");
            $this->info("Usa --db-path per specificare un percorso diverso");
            return Command::FAILURE;
        }

        $this->info("Connessione al vecchio database: {$oldDbPath}");

        try {
            $oldDb = new \PDO('sqlite:' . $oldDbPath);
            $oldDb->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);

            // Leggi tutte le persone dal vecchio database
            $stmt = $oldDb->query('SELECT * FROM persone ORDER BY indice');
            $oldPersone = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            $this->info("Trovate " . count($oldPersone) . " persone nel vecchio database");

            // Trova persone senza data di nascita nel nuovo database
            $query = Persona::whereNull('nato_il');
            
            if (!$this->option('force')) {
                $this->info("Cercando solo persone senza data di nascita...");
            } else {
                $this->warn("Modalità FORCE: aggiornerà anche le date già presenti");
                $query = Persona::query();
            }

            $personeSenzaData = $query->get();
            $this->info("Trovate " . $personeSenzaData->count() . " persone da aggiornare");

            if ($personeSenzaData->isEmpty()) {
                $this->info("Nessuna persona da aggiornare!");
                return Command::SUCCESS;
            }

            $dryRun = $this->option('dry-run');
            if ($dryRun) {
                $this->warn("Modalità DRY-RUN: nessuna modifica verrà applicata");
            }

            $aggiornate = 0;
            $nonTrovate = 0;
            $errori = 0;

            $bar = $this->output->createProgressBar($personeSenzaData->count());
            $bar->start();

            DB::beginTransaction();

            foreach ($personeSenzaData as $persona) {
                try {
                    // Cerca corrispondenza nel vecchio database
                    $oldPersona = $this->trovaCorrispondenza($persona, $oldPersone);

                    if ($oldPersona && !empty($oldPersona['nato_il'])) {
                        $natoIl = $this->parseDate($oldPersona['nato_il']);
                        
                        if ($natoIl) {
                            // Se è dry-run, mostra solo cosa verrebbe fatto
                            if ($dryRun) {
                                $this->newLine();
                                $this->line("  [DRY-RUN] ID {$persona->id}: {$persona->nome} {$persona->cognome}");
                                $this->line("    Data trovata: {$oldPersona['nato_il']} -> {$natoIl}");
                                if (!empty($oldPersona['nato_a'])) {
                                    $this->line("    Luogo: {$oldPersona['nato_a']}");
                                }
                            } else {
                                // Aggiorna solo se non ha già una data o se è force
                                if (!$persona->nato_il || $this->option('force')) {
                                    $persona->nato_il = $natoIl;
                                    
                                    // Aggiorna anche il luogo se mancante
                                    if (empty($persona->nato_a) && !empty($oldPersona['nato_a'])) {
                                        $persona->nato_a = $oldPersona['nato_a'];
                                    }
                                    
                                    $persona->save();
                                    $aggiornate++;
                                }
                            }
                        } else {
                            $errori++;
                        }
                    } else {
                        $nonTrovate++;
                    }
                } catch (\Exception $e) {
                    $errori++;
                    if (!$dryRun) {
                        $this->newLine();
                        $this->error("Errore per persona ID {$persona->id}: " . $e->getMessage());
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
                $this->info("✅ Aggiornate {$aggiornate} persone");
            }

            if ($nonTrovate > 0) {
                $this->warn("⚠️  {$nonTrovate} persone non trovate nel vecchio database");
            }

            if ($errori > 0) {
                $this->error("❌ {$errori} errori durante l'elaborazione");
            }

            return Command::SUCCESS;

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error("Errore: " . $e->getMessage());
            return Command::FAILURE;
        }
    }

    /**
     * Trova corrispondenza tra persona nuova e vecchia basandosi su nome e cognome
     */
    private function trovaCorrispondenza(Persona $persona, array $oldPersone): ?array
    {
        foreach ($oldPersone as $oldPersona) {
            $oldNomeCompleto = trim($oldPersona['nome'] ?? '');
            
            // Se la persona nuova ha nome e cognome separati
            if ($persona->nome && $persona->cognome) {
                $nomeCompleto = trim($persona->nome . ' ' . $persona->cognome);
                
                // Match esatto
                if (strcasecmp($nomeCompleto, $oldNomeCompleto) === 0) {
                    return $oldPersona;
                }
                
                // Match parziale (nome o cognome)
                $oldParts = explode(' ', $oldNomeCompleto, 2);
                if (count($oldParts) >= 2) {
                    $oldNome = trim($oldParts[0]);
                    $oldCognome = trim($oldParts[1]);
                    
                    if (strcasecmp($persona->nome, $oldNome) === 0 && 
                        strcasecmp($persona->cognome, $oldCognome) === 0) {
                        return $oldPersona;
                    }
                }
            } 
            // Se la persona nuova ha solo nome
            elseif ($persona->nome && !$persona->cognome) {
                // Match sul nome completo o solo sul nome
                if (strcasecmp($persona->nome, $oldNomeCompleto) === 0) {
                    return $oldPersona;
                }
                
                $oldParts = explode(' ', $oldNomeCompleto, 2);
                if (count($oldParts) > 0 && strcasecmp($persona->nome, trim($oldParts[0])) === 0) {
                    return $oldPersona;
                }
            }
        }

        return null;
    }

    /**
     * Converte una stringa data in formato YYYY-MM-DD o null
     */
    private function parseDate(?string $date): ?string
    {
        if (empty($date)) {
            return null;
        }

        // Prova vari formati
        $formats = ['Y-m-d', 'd/m/Y', 'd-m-Y', 'Y/m/d', 'd.m.Y'];
        
        foreach ($formats as $format) {
            $parsed = \DateTime::createFromFormat($format, $date);
            if ($parsed !== false) {
                return $parsed->format('Y-m-d');
            }
        }

        // Prova anche con DateTime normale
        try {
            $dateObj = new \DateTime($date);
            return $dateObj->format('Y-m-d');
        } catch (\Exception $e) {
            // Ignora errori
        }

        return null;
    }
}

