<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TipiEventoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tipiEvento = [
            ['nome' => 'nascita', 'descrizione' => 'Nascita'],
            ['nome' => 'battesimo', 'descrizione' => 'Battesimo'],
            ['nome' => 'comunione', 'descrizione' => 'Prima Comunione'],
            ['nome' => 'cresima', 'descrizione' => 'Cresima'],
            ['nome' => 'matrimonio', 'descrizione' => 'Matrimonio'],
            ['nome' => 'divorzio', 'descrizione' => 'Divorzio'],
            ['nome' => 'morte', 'descrizione' => 'Morte'],
            ['nome' => 'sepoltura', 'descrizione' => 'Sepoltura'],
            ['nome' => 'laurea', 'descrizione' => 'Laurea'],
            ['nome' => 'lavoro', 'descrizione' => 'Inizio Lavoro'],
            ['nome' => 'pensione', 'descrizione' => 'Pensione'],
            ['nome' => 'altro', 'descrizione' => 'Altro'],
        ];

        foreach ($tipiEvento as $tipo) {
            DB::table('tipi_evento')->insertOrIgnore([
                'nome' => $tipo['nome'],
                'descrizione' => $tipo['descrizione'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}

