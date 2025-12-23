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
            $table->date('data_separazione')->nullable()->after('tipo_evento_legame_id');
            $table->string('luogo_separazione')->nullable()->after('data_separazione');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('persona_legami', function (Blueprint $table) {
            $table->dropColumn(['data_separazione', 'luogo_separazione']);
        });
    }
};
