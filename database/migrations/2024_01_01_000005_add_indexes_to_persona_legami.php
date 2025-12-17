<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('persona_legami', function (Blueprint $table) {
            // Aggiungi indici per migliorare le performance delle query
            $table->index('persona_id');
            $table->index('persona_collegata_id');
            $table->index('tipo_legame_id');
            $table->index(['persona_id', 'tipo_legame_id']);
            $table->index(['persona_collegata_id', 'tipo_legame_id']);
        });
    }

    public function down(): void
    {
        Schema::table('persona_legami', function (Blueprint $table) {
            $table->dropIndex(['persona_id']);
            $table->dropIndex(['persona_collegata_id']);
            $table->dropIndex(['tipo_legame_id']);
            $table->dropIndex(['persona_id', 'tipo_legame_id']);
            $table->dropIndex(['persona_collegata_id', 'tipo_legame_id']);
        });
    }
};

