<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TipoEventoLegame extends Model
{
    protected $table = 'tipi_evento_legame';

    protected $fillable = [
        'nome',
        'descrizione',
    ];

    public function personaLegami(): HasMany
    {
        return $this->hasMany(PersonaLegame::class, 'tipo_evento_legame_id');
    }
}
