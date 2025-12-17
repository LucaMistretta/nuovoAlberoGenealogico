<?php

declare(strict_types=1);

namespace App\Console\Commands;

use Illuminate\Console\Command;

class NormalizzaCsvCommand extends Command
{
    protected $signature = 'csv:normalizza-indici 
                            {--csv-path= : Percorso del file CSV (default: database/LISTA.csv)}
                            {--output= : Percorso del file di output (default: sovrascrive il file originale)}';

    protected $description = 'Normalizza gli indici del CSV dal formato scientifico a interi consecutivi';

    public function handle(): int
    {
        $csvPath = $this->option('csv-path') ?: database_path('LISTA.csv');
        $outputPath = $this->option('output') ?: $csvPath;

        if (!file_exists($csvPath)) {
            $this->error("File CSV non trovato: {$csvPath}");
            return Command::FAILURE;
        }

        $this->info("Lettura file CSV: {$csvPath}");

        try {
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

            // Normalizza gli header
            $headers = array_map('trim', $headers);
            $headers = array_map('strtolower', $headers);

            $rows = [];
            $indiceMap = []; // Mappa vecchio indice -> nuovo indice

            // Leggi tutte le righe
            while (($row = fgetcsv($handle)) !== false) {
                if (count($row) !== count($headers)) {
                    continue;
                }

                $data = array_combine($headers, $row);
                
                // Converti l'indice dal formato scientifico a intero
                $vecchioIndice = $this->convertiIndice($data['indice'] ?? null);
                
                if ($vecchioIndice === null || $vecchioIndice === 0) {
                    continue; // Salta righe senza indice valido
                }

                // Filtra righe con nomi non validi
                $nome = trim($data['nome'] ?? '');
                if (empty($nome) || 
                    strcasecmp($nome, 'Nuovo Nome') === 0 || 
                    strcasecmp($nome, 'Nuovo') === 0 ||
                    preg_match('/^nuovo\s+nome/i', $nome)) {
                    $this->warn("Riga con indice {$vecchioIndice} saltata: nome non valido '{$nome}'");
                    continue; // Salta righe con nomi non validi
                }

                $rows[] = [
                    'vecchio_indice' => $vecchioIndice,
                    'data' => $data
                ];
            }

            fclose($handle);

            // Ordina per indice vecchio
            usort($rows, function($a, $b) {
                return $a['vecchio_indice'] <=> $b['vecchio_indice'];
            });

            // Crea mappa vecchio indice -> nuovo indice (consecutivo da 2)
            // Solo per le righe valide (quelle non filtrate)
            $nuovoIndice = 2;
            foreach ($rows as $row) {
                $indiceMap[$row['vecchio_indice']] = $nuovoIndice;
                $nuovoIndice++;
            }
            
            $this->info("Righe valide dopo filtro: " . count($rows));

            $this->info("Trovate " . count($rows) . " righe da normalizzare");
            $this->info("Nuovi indici da {$indiceMap[min(array_keys($indiceMap))]} a " . max($indiceMap));

            // Scrivi il nuovo CSV
            $outputHandle = fopen($outputPath, 'w');
            if ($outputHandle === false) {
                throw new \Exception("Impossibile creare il file di output");
            }

            // Scrivi l'header
            fputcsv($outputHandle, $headers);

            // Scrivi le righe normalizzate
            $bar = $this->output->createProgressBar(count($rows));
            $bar->start();

            foreach ($rows as $row) {
                $data = $row['data'];
                $nuovoIndice = $indiceMap[$row['vecchio_indice']];

                // Aggiorna l'indice
                $data['indice'] = (string)$nuovoIndice;

                // Aggiorna tutti i riferimenti (padre, madre, consorte, figlio_1-6)
                $campiRiferimento = ['padre', 'madre', 'consorte', 'figlio_1', 'figlio_2', 'figlio_3', 'figlio_4', 'figlio_5', 'figlio_6'];
                
                foreach ($campiRiferimento as $campo) {
                    if (isset($data[$campo])) {
                        $vecchioRiferimento = $this->convertiIndice($data[$campo]);
                        if ($vecchioRiferimento !== null && $vecchioRiferimento !== 0 && isset($indiceMap[$vecchioRiferimento])) {
                            $data[$campo] = (string)$indiceMap[$vecchioRiferimento];
                        } else {
                            $data[$campo] = '0';
                        }
                    }
                }

                // Converti tutti i numeri in formato scientifico a interi normali
                foreach ($data as $key => $value) {
                    if (is_numeric($value) && (stripos($value, 'e+') !== false || stripos($value, 'e-') !== false)) {
                        $valoreConvertito = (int)(float)$value;
                        $data[$key] = $valoreConvertito === 0 ? '0' : (string)$valoreConvertito;
                    } elseif (is_numeric($value) && (float)$value == 0) {
                        $data[$key] = '0';
                    }
                }

                // Ricostruisci la riga nell'ordine originale degli header
                $rigaOrdinata = [];
                foreach ($headers as $header) {
                    $rigaOrdinata[] = $data[$header] ?? '';
                }

                fputcsv($outputHandle, $rigaOrdinata);
                $bar->advance();
            }

            $bar->finish();
            fclose($outputHandle);

            $this->newLine(2);
            $this->info("✅ File CSV normalizzato salvato in: {$outputPath}");
            $this->info("   Indici normalizzati da 2 a " . max($indiceMap));

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error("Errore: " . $e->getMessage());
            $this->error($e->getTraceAsString());
            return Command::FAILURE;
        }
    }

    /**
     * Converte un indice dal formato scientifico a intero
     */
    private function convertiIndice(?string $indice): ?int
    {
        if (empty($indice) || $indice === '0' || $indice === '0.0000000000000000e+00') {
            return 0;
        }

        // Gestisci formato scientifico
        if (stripos($indice, 'e+') !== false || stripos($indice, 'e-') !== false) {
            $valore = (float) $indice;
            return (int) $valore;
        }

        // Gestisci formato normale
        if (is_numeric($indice)) {
            return (int) $indice;
        }

        return null;
    }
}

