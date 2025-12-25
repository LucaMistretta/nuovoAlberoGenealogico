<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Nota extends Model
{
    protected $table = 'note';

    protected $fillable = [
        'persona_id',
        'user_id',
        'contenuto',
        'last_synced_at',
    ];

    // last_synced_at non ha cast per evitare problemi con SQLite

    public function persona(): BelongsTo
    {
        return $this->belongsTo(Persona::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}


