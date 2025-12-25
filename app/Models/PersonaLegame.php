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
        'data_legame',
        'luogo_legame',
        'tipo_evento_legame_id',
        'data_separazione',
        'luogo_separazione',
        'last_synced_at',
    ];

    protected $casts = [
        'data_legame' => 'date',
        'data_separazione' => 'date',
        // last_synced_at non ha cast per evitare problemi con SQLite
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

    public function tipoEventoLegame(): BelongsTo
    {
        return $this->belongsTo(TipoEventoLegame::class, 'tipo_evento_legame_id');
    }
}

