<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Persona;
use App\Models\PersonaLegame;
use App\Models\TipoLegame;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ImportAgeneSeeder extends Seeder
{
    public function run(): void
    {
        // Percorso del vecchio database
        $oldDbPath = 'C:\Users\LUCA\Desktop\WEBAPP\PHP\alberoGenealogico\database\agene.sqlite';
        
        if (!file_exists($oldDbPath)) {
            $this->command->error("Database SQLite non trovato: {$oldDbPath}");
            $this->command->info("Verifica che il file esista nel percorso specificato");
            return;
        }

        $this->command->info("Importazione dati da: {$oldDbPath}");

        // Connetti al vecchio database
        $oldDb = new \PDO('sqlite:' . $oldDbPath);
        $oldDb->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);

        // Leggi tutte le persone dal vecchio database
        $stmt = $oldDb->query('SELECT * FROM persone ORDER BY indice');
        $oldPersone = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $this->command->info("Trovate " . count($oldPersone) . " persone da importare");

        // Mappa per tracciare indice vecchio -> id nuovo
        $indiceToIdMap = [];

        DB::beginTransaction();
        try {
            // Prima passata: crea tutte le persone senza relazioni
            $bar = $this->command->getOutput()->createProgressBar(count($oldPersone));
            $bar->start();

            foreach ($oldPersone as $oldPersona) {
                // Estrai nome e cognome dal campo nome (se contiene spazio)
                $nomeCompleto = $oldPersona['nome'] ?? '';
                $nome = $nomeCompleto;
                $cognome = null;
                
                if ($nomeCompleto && strpos($nomeCompleto, ' ') !== false) {
                    $parts = explode(' ', $nomeCompleto, 2);
                    $nome = $parts[0];
                    $cognome = $parts[1] ?? null;
                }

                // Converti date
                $natoIl = $this->parseDate($oldPersona['nato_il'] ?? null);
                $decedutoIl = $this->parseDate($oldPersona['deceduto_il'] ?? null);

                $persona = Persona::create([
                    'nome' => $nome ?: null,
                    'cognome' => $cognome,
                    'nato_a' => $oldPersona['nato_a'] ?? null,
                    'nato_il' => $natoIl,
                    'deceduto_a' => $oldPersona['deceduto_a'] ?? null,
                    'deceduto_il' => $decedutoIl,
                ]);

                // Salva mappatura indice vecchio -> id nuovo
                $indiceToIdMap[$oldPersona['indice']] = $persona->id;

                $bar->advance();
            }

            $bar->finish();
            $this->command->newLine();
            $this->command->info("Persone create. Ora importo le relazioni...");

            // Seconda passata: crea le relazioni
            $bar = $this->command->getOutput()->createProgressBar(count($oldPersone));
            $bar->start();

            // Ottieni i tipi di legame
            $tipoPadre = TipoLegame::where('nome', 'padre')->first();
            $tipoMadre = TipoLegame::where('nome', 'madre')->first();
            $tipoConiuge = TipoLegame::where('nome', 'coniuge')->first();
            $tipoFiglio = TipoLegame::where('nome', 'figlio')->first();

            foreach ($oldPersone as $oldPersona) {
                $personaId = $indiceToIdMap[$oldPersona['indice']] ?? null;
                if (!$personaId) {
                    continue;
                }

                // Padre
                if (!empty($oldPersona['padre']) && isset($indiceToIdMap[$oldPersona['padre']])) {
                    $padreId = $indiceToIdMap[$oldPersona['padre']];
                    PersonaLegame::firstOrCreate([
                        'persona_id' => $padreId,
                        'persona_collegata_id' => $personaId,
                        'tipo_legame_id' => $tipoPadre->id,
                    ]);
                }

                // Madre
                if (!empty($oldPersona['madre']) && isset($indiceToIdMap[$oldPersona['madre']])) {
                    $madreId = $indiceToIdMap[$oldPersona['madre']];
                    PersonaLegame::firstOrCreate([
                        'persona_id' => $madreId,
                        'persona_collegata_id' => $personaId,
                        'tipo_legame_id' => $tipoMadre->id,
                    ]);
                }

                // Consorte
                if (!empty($oldPersona['consorte']) && isset($indiceToIdMap[$oldPersona['consorte']])) {
                    $consorteId = $indiceToIdMap[$oldPersona['consorte']];
                    PersonaLegame::firstOrCreate([
                        'persona_id' => $personaId,
                        'persona_collegata_id' => $consorteId,
                        'tipo_legame_id' => $tipoConiuge->id,
                    ]);
                }

                // Figli
                for ($i = 1; $i <= 6; $i++) {
                    $figlioKey = "figlio_{$i}";
                    if (!empty($oldPersona[$figlioKey]) && isset($indiceToIdMap[$oldPersona[$figlioKey]])) {
                        $figlioId = $indiceToIdMap[$oldPersona[$figlioKey]];
                        PersonaLegame::firstOrCreate([
                            'persona_id' => $personaId,
                            'persona_collegata_id' => $figlioId,
                            'tipo_legame_id' => $tipoFiglio->id,
                        ]);
                    }
                }

                $bar->advance();
            }

            $bar->finish();
            $this->command->newLine();

            DB::commit();
            $this->command->info('Importazione completata con successo!');
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error('Errore durante l\'importazione: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Converte una stringa data in formato date o null
     */
    private function parseDate(?string $date): ?string
    {
        if (empty($date)) {
            return null;
        }

        // Prova vari formati
        $formats = ['Y-m-d', 'd/m/Y', 'd-m-Y', 'Y/m/d'];
        
        foreach ($formats as $format) {
            $parsed = \DateTime::createFromFormat($format, $date);
            if ($parsed !== false) {
                return $parsed->format('Y-m-d');
            }
        }

        // Se non riesce a parsare, restituisci null
        return null;
    }
}

