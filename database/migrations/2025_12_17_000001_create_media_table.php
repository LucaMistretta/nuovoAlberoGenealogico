<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('persona_id')->constrained('persone')->onDelete('cascade');
            $table->enum('tipo', ['foto', 'documento'])->default('foto');
            $table->string('nome_file');
            $table->string('percorso');
            $table->unsignedBigInteger('dimensione')->nullable();
            $table->string('mime_type')->nullable();
            $table->text('descrizione')->nullable();
            $table->dateTime('data_caricamento')->useCurrent();
            $table->timestamps();

            $table->index('persona_id');
            $table->index('tipo');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};

