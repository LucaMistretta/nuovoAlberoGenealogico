<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('eventi', function (Blueprint $table) {
            $table->id();
            $table->foreignId('persona_id')->constrained('persone')->onDelete('cascade');
            $table->string('tipo_evento'); // matrimonio, battesimo, morte, ecc.
            $table->string('titolo');
            $table->text('descrizione')->nullable();
            $table->date('data_evento')->nullable();
            $table->string('luogo')->nullable();
            $table->text('note')->nullable();
            $table->timestamps();

            $table->index('persona_id');
            $table->index('tipo_evento');
            $table->index('data_evento');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('eventi');
    }
};

