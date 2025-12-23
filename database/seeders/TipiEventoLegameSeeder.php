<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TipiEventoLegameSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tipiEventoLegame = [
            ['nome' => 'matrimonio', 'descrizione' => 'Matrimonio'],
            ['nome' => 'unione_civile', 'descrizione' => 'Unione Civile'],
            ['nome' => 'convivenza_di_fatto', 'descrizione' => 'Convivenza di Fatto'],
            ['nome' => 'altro', 'descrizione' => 'Altro'],
        ];

        foreach ($tipiEventoLegame as $tipo) {
            DB::table('tipi_evento_legame')->insertOrIgnore([
                'nome' => $tipo['nome'],
                'descrizione' => $tipo['descrizione'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}
