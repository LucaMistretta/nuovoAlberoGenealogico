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
    ];

    public function persone(): BelongsToMany
    {
        return $this->belongsToMany(Persona::class, 'persona_tags');
    }
}

