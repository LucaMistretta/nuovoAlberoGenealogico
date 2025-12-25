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
        Schema::create('sync_conflicts', function (Blueprint $table) {
            $table->id();
            $table->string('table_name'); // 'persone', 'eventi', 'media', etc.
            $table->integer('record_id'); // ID del record in conflitto
            $table->json('server_data'); // Dati sul server
            $table->json('app_data'); // Dati dall'app
            $table->timestamp('server_updated_at'); // Quando modificato sul server
            $table->timestamp('app_updated_at'); // Quando modificato sull'app
            $table->enum('resolution', ['pending', 'server_wins', 'app_wins', 'merged'])->default('pending');
            $table->json('resolved_data')->nullable(); // Dati dopo risoluzione
            $table->integer('resolved_by')->nullable(); // User ID che ha risolto
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['table_name', 'record_id']);
            $table->index('resolution');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sync_conflicts');
    }
};
