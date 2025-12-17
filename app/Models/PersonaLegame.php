<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PersonaLegame extends Model
{
    protected $table = 'persona_legami';

    protected $fillable = [
        'persona_id',
        'persona_collegata_id',
        'tipo_legame_id',
    ];

    public function persona(): BelongsTo
    {
        return $this->belongsTo(Persona::class, 'persona_id');
    }

    public function personaCollegata(): BelongsTo
    {
        return $this->belongsTo(Persona::class, 'persona_collegata_id');
    }

    public function tipoLegame(): BelongsTo
    {
        return $this->belongsTo(TipoLegame::class, 'tipo_legame_id');
    }
}

