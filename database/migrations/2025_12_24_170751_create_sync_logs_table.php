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
        Schema::create('sync_logs', function (Blueprint $table) {
            $table->id();
            $table->string('sync_type'); // 'push', 'pull', 'merge'
            $table->string('sync_mode'); // 'http', 'adb'
            $table->string('device_id')->nullable(); // ID dispositivo per ADB
            $table->integer('user_id')->nullable(); // Utente che ha eseguito la sync
            $table->json('summary')->nullable(); // Riepilogo: {persone: X, eventi: Y, ...}
            $table->integer('records_synced')->default(0);
            $table->integer('conflicts_found')->default(0);
            $table->enum('status', ['pending', 'in_progress', 'completed', 'failed'])->default('pending');
            $table->text('error_message')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index('sync_type');
            $table->index('status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sync_logs');
    }
};
