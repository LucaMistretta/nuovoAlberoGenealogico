<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Tag extends Model
{
    protected $table = 'tags';

    protected $fillable = [
        'nome',
        'colore',
        'descrizione',
        'last_synced_at',
    ];

    // last_synced_at non ha cast per evitare problemi con SQLite

    public function persone(): BelongsToMany
    {
        return $this->belongsToMany(Persona::class, 'persona_tags');
    }
}


