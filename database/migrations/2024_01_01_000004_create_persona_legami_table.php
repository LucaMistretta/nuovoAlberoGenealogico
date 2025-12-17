<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('persona_legami', function (Blueprint $table) {
            $table->id();
            $table->foreignId('persona_id')->constrained('persone')->onDelete('cascade');
            $table->foreignId('persona_collegata_id')->constrained('persone')->onDelete('cascade');
            $table->foreignId('tipo_legame_id')->constrained('tipi_di_legame')->onDelete('cascade');
            $table->timestamps();

            // Unique constraint per evitare duplicati
            $table->unique(['persona_id', 'persona_collegata_id', 'tipo_legame_id'], 'unique_legame');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('persona_legami');
    }
};

