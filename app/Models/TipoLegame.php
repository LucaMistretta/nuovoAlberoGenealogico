<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TipoLegame extends Model
{
    protected $table = 'tipi_di_legame';

    protected $fillable = [
        'nome',
        'descrizione',
    ];

    public function personaLegami(): HasMany
    {
        return $this->hasMany(PersonaLegame::class, 'tipo_legame_id');
    }
}

