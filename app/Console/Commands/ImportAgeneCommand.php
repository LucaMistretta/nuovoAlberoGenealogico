<?php

declare(strict_types=1);

namespace App\Console\Commands;

use Database\Seeders\ImportAgeneSeeder;
use Illuminate\Console\Command;

class ImportAgeneCommand extends Command
{
    protected $signature = 'db:import-agene';
    protected $description = 'Importa dati dal vecchio database agene.sqlite';

    public function handle(): int
    {
        $this->info('Avvio importazione dati...');
        
        $seeder = new ImportAgeneSeeder();
        $seeder->setCommand($this);
        $seeder->run();

        return Command::SUCCESS;
    }
}

