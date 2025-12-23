<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Evento extends Model
{
    protected $table = 'eventi';

    protected $fillable = [
        'persona_id',
        'tipo_evento',
        'titolo',
        'descrizione',
        'data_evento',
        'luogo',
        'note',
    ];

    protected $casts = [
        'data_evento' => 'date',
    ];

    public function persona(): BelongsTo
    {
        return $this->belongsTo(Persona::class);
    }
}


