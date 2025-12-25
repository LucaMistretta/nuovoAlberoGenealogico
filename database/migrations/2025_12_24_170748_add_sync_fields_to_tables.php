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
        // Aggiungi last_synced_at alle tabelle principali
        Schema::table('persone', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });

        Schema::table('eventi', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });

        Schema::table('media', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });

        Schema::table('note', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });

        Schema::table('tags', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });

        Schema::table('persona_legami', function (Blueprint $table) {
            $table->timestamp('last_synced_at')->nullable()->after('updated_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('persone', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });

        Schema::table('eventi', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });

        Schema::table('media', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });

        Schema::table('note', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });

        Schema::table('tags', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });

        Schema::table('persona_legami', function (Blueprint $table) {
            $table->dropColumn('last_synced_at');
        });
    }
};
