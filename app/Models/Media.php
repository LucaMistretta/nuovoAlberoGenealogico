<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Media extends Model
{
    protected $table = 'media';

    protected $fillable = [
        'persona_id',
        'tipo',
        'nome_file',
        'percorso',
        'dimensione',
        'mime_type',
        'descrizione',
        'data_caricamento',
    ];

    protected $casts = [
        'data_caricamento' => 'datetime',
        'dimensione' => 'integer',
    ];

    public function persona(): BelongsTo
    {
        return $this->belongsTo(Persona::class);
    }

    public function getUrlAttribute(): string
    {
        return asset('storage/' . $this->percorso);
    }

    public function isImage(): bool
    {
        return $this->tipo === 'foto' || str_starts_with($this->mime_type ?? '', 'image/');
    }
}


