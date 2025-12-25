<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Persona;
use App\Models\Evento;
use App\Models\Media;
use App\Models\Nota;
use App\Models\Tag;
use App\Models\PersonaLegame;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DiffService
{
    /**
     * Calcola le differenze tra database server e app
     * 
     * @param array $appData Dati dall'app: {persone: [...], eventi: [...], ...}
     * @param \DateTime|null $lastSyncTimestamp Timestamp ultima sincronizzazione
     * @return array Differenze organizzate per tipo
     */
    public function calculateDiff(array $appData, ?\DateTime $lastSyncTimestamp = null): array
    {
        $diff = [
            'persone' => $this->diffTable('persone', $appData['persone'] ?? [], $lastSyncTimestamp),
            'eventi' => $this->diffTable('eventi', $appData['eventi'] ?? [], $lastSyncTimestamp),
            'media' => $this->diffTable('media', $appData['media'] ?? [], $lastSyncTimestamp),
            'note' => $this->diffTable('note', $appData['note'] ?? [], $lastSyncTimestamp),
            'tags' => $this->diffTable('tags', $appData['tags'] ?? [], $lastSyncTimestamp),
            'persona_legami' => $this->diffTable('persona_legami', $appData['persona_legami'] ?? [], $lastSyncTimestamp),
        ];

        // Calcola statistiche
        $diff['summary'] = [
            'server_new' => array_sum(array_column($diff, 'server_new_count')),
            'app_new' => array_sum(array_column($diff, 'app_new_count')),
            'modified' => array_sum(array_column($diff, 'modified_count')),
            'conflicts' => array_sum(array_column($diff, 'conflicts_count')),
        ];

        return $diff;
    }

    /**
     * Calcola differenze per una singola tabella
     */
    private function diffTable(string $tableName, array $appRecords, ?\DateTime $lastSyncTimestamp): array
    {
        $serverRecords = $this->getServerRecords($tableName, $lastSyncTimestamp);
        $appRecordsById = collect($appRecords)->keyBy('id')->toArray();

        $serverNew = [];
        $appNew = [];
        $modified = [];
        $conflicts = [];

        // Trova record nuovi sul server
        foreach ($serverRecords as $serverRecord) {
            $id = $serverRecord['id'];
            if (!isset($appRecordsById[$id])) {
                $serverNew[] = $serverRecord;
            } else {
                $appRecord = $appRecordsById[$id];
                // Verifica se modificato
                $serverUpdated = $serverRecord['updated_at'] ?? null;
                $appUpdated = $appRecord['updated_at'] ?? null;
                
                if ($serverUpdated && $appUpdated) {
                    $serverTime = strtotime($serverUpdated);
                    $appTime = strtotime($appUpdated);
                    
                    // Se modificato su entrambi i lati dopo ultima sync = conflitto
                    if ($lastSyncTimestamp) {
                        $lastSyncTime = $lastSyncTimestamp->getTimestamp();
                        if ($serverTime > $lastSyncTime && $appTime > $lastSyncTime) {
                            $conflicts[] = [
                                'id' => $id,
                                'server_data' => $serverRecord,
                                'app_data' => $appRecord,
                                'server_updated_at' => $serverUpdated,
                                'app_updated_at' => $appUpdated,
                            ];
                        } elseif ($serverTime > $appTime) {
                            $modified[] = [
                                'id' => $id,
                                'type' => 'server_newer',
                                'server_data' => $serverRecord,
                                'app_data' => $appRecord,
                            ];
                        } else {
                            $modified[] = [
                                'id' => $id,
                                'type' => 'app_newer',
                                'server_data' => $serverRecord,
                                'app_data' => $appRecord,
                            ];
                        }
                    } else {
                        // Prima sincronizzazione: usa timestamp più recente
                        if ($serverTime > $appTime) {
                            $modified[] = [
                                'id' => $id,
                                'type' => 'server_newer',
                                'server_data' => $serverRecord,
                                'app_data' => $appRecord,
                            ];
                        } else {
                            $modified[] = [
                                'id' => $id,
                                'type' => 'app_newer',
                                'server_data' => $serverRecord,
                                'app_data' => $appRecord,
                            ];
                        }
                    }
                }
            }
        }

        // Trova record nuovi sull'app
        foreach ($appRecords as $appRecord) {
            $id = $appRecord['id'];
            $found = false;
            foreach ($serverRecords as $serverRecord) {
                if ($serverRecord['id'] == $id) {
                    $found = true;
                    break;
                }
            }
            if (!$found) {
                $appNew[] = $appRecord;
            }
        }

        return [
            'server_new' => $serverNew,
            'app_new' => $appNew,
            'modified' => $modified,
            'conflicts' => $conflicts,
            'server_new_count' => count($serverNew),
            'app_new_count' => count($appNew),
            'modified_count' => count($modified),
            'conflicts_count' => count($conflicts),
        ];
    }

    /**
     * Ottiene i record dal database server
     */
    private function getServerRecords(string $tableName, ?\DateTime $lastSyncTimestamp): array
    {
        $query = DB::table($tableName);
        
        if ($lastSyncTimestamp) {
            $query->where(function ($q) use ($lastSyncTimestamp) {
                $q->where('updated_at', '>', $lastSyncTimestamp)
                  ->orWhereNull('last_synced_at')
                  ->orWhere('last_synced_at', '<', $lastSyncTimestamp);
            });
        }

        return $query->get()->map(function ($record) {
            return (array) $record;
        })->toArray();
    }
}

