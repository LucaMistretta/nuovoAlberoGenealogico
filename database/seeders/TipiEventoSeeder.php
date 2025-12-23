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
            ['nome' => 'primo_giorno_asilo', 'descrizione' => 'Primo Giorno di Asilo'],
            ['nome' => 'primo_giorno_scuola', 'descrizione' => 'Primo Giorno di Scuola'],
            ['nome' => 'licenza_elementare', 'descrizione' => 'Licenza Elementare'],
            ['nome' => 'licenza_media', 'descrizione' => 'Licenza Media'],
            ['nome' => 'diploma_superiore', 'descrizione' => 'Diploma Superiore'],
            ['nome' => 'laurea', 'descrizione' => 'Laurea'],
            ['nome' => 'matrimonio', 'descrizione' => 'Matrimonio'],
            ['nome' => 'divorzio', 'descrizione' => 'Divorzio'],
            ['nome' => 'lavoro', 'descrizione' => 'Inizio Lavoro'],
            ['nome' => 'cambio_lavoro', 'descrizione' => 'Cambio Lavoro'],
            ['nome' => 'militare', 'descrizione' => 'Servizio Militare'],
            ['nome' => 'guerra', 'descrizione' => 'Guerra'],
            ['nome' => 'trasloco', 'descrizione' => 'Trasloco'],
            ['nome' => 'emigrazione', 'descrizione' => 'Emigrazione'],
            ['nome' => 'immigrazione', 'descrizione' => 'Immigrazione'],
            ['nome' => 'malattia', 'descrizione' => 'Malattia Importante'],
            ['nome' => 'guarigione', 'descrizione' => 'Guarigione'],
            ['nome' => 'pensione', 'descrizione' => 'Pensione'],
            ['nome' => 'morte', 'descrizione' => 'Morte'],
            ['nome' => 'sepoltura', 'descrizione' => 'Sepoltura'],
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


