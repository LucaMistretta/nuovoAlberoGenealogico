<?php

declare(strict_types=1);

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

class BackupDatabase extends Command
{
    protected $signature = 'db:backup {--path=storage/backups}';
    protected $description = 'Crea un backup del database';

    public function handle(): int
    {
        $path = $this->option('path');
        $dbPath = database_path('agene.sqlite');
        
        if (!File::exists($dbPath)) {
            $this->error('Database non trovato: ' . $dbPath);
            return 1;
        }

        $backupDir = storage_path($path);
        if (!File::isDirectory($backupDir)) {
            File::makeDirectory($backupDir, 0755, true);
        }

        $filename = 'backup_' . date('Y-m-d_His') . '.sqlite';
        $backupPath = $backupDir . '/' . $filename;

        File::copy($dbPath, $backupPath);

        $this->info("Backup creato: {$backupPath}");

        // Mantieni solo gli ultimi 10 backup
        $backups = File::files($backupDir);
        usort($backups, fn($a, $b) => File::lastModified($b) - File::lastModified($a));
        
        foreach (array_slice($backups, 10) as $oldBackup) {
            File::delete($oldBackup);
            $this->info("Rimosso vecchio backup: " . $oldBackup->getFilename());
        }

        return 0;
    }
}


