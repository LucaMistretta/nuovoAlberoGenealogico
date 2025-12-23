<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('persona_legami', function (Blueprint $table) {
            $table->date('data_legame')->nullable()->after('tipo_legame_id');
            $table->string('luogo_legame')->nullable()->after('data_legame');
            $table->foreignId('tipo_evento_legame_id')->nullable()->after('luogo_legame')
                ->constrained('tipi_evento_legame')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('persona_legami', function (Blueprint $table) {
            $table->dropForeign(['tipo_evento_legame_id']);
            $table->dropColumn(['data_legame', 'luogo_legame', 'tipo_evento_legame_id']);
        });
    }
};
