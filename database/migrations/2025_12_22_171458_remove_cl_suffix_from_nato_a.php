<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Rimuove il suffisso "CL" dalla fine del campo nato_a
     */
    public function up(): void
    {
        // Per SQLite: rimuove "CL" solo dalla fine della stringa
        // Prima rimuove gli spazi finali, poi rimuove "CL" se presente alla fine
        DB::statement("
            UPDATE persone 
            SET nato_a = CASE 
                WHEN TRIM(nato_a) LIKE '%CL' THEN 
                    TRIM(SUBSTR(TRIM(nato_a), 1, LENGTH(TRIM(nato_a)) - 2))
                ELSE 
                    TRIM(nato_a)
            END
            WHERE nato_a IS NOT NULL 
            AND nato_a != '' 
            AND TRIM(nato_a) LIKE '%CL'
        ");
        
        // Rimuove anche eventuali spazi multipli rimasti
        DB::statement("
            UPDATE persone 
            SET nato_a = TRIM(nato_a)
            WHERE nato_a IS NOT NULL AND nato_a != ''
        ");
    }

    /**
     * Reverse the migrations.
     * Nota: Non è possibile ripristinare automaticamente il suffisso "CL"
     */
    public function down(): void
    {
        // Non è possibile ripristinare automaticamente il suffisso "CL"
        // perché non sappiamo quali record lo avevano
    }
};
