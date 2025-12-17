<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\TipoLegame;
use Illuminate\Database\Seeder;

class TipiDiLegameSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tipi = [
            [
                'nome' => 'padre',
                'descrizione' => 'Relazione padre-figlio',
            ],
            [
                'nome' => 'madre',
                'descrizione' => 'Relazione madre-figlio',
            ],
            [
                'nome' => 'coniuge',
                'descrizione' => 'Relazione coniugale',
            ],
            [
                'nome' => 'figlio',
                'descrizione' => 'Relazione figlio-genitore',
            ],
        ];

        foreach ($tipi as $tipo) {
            TipoLegame::firstOrCreate(
                ['nome' => $tipo['nome']],
                $tipo
            );
        }
    }
}

