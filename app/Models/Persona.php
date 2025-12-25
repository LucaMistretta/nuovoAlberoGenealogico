<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Log;
use App\Models\PersonaLegame;
use App\Models\TipoLegame;
use App\Models\Media;
use App\Models\Evento;
use App\Models\Nota;
use App\Models\Tag;
use App\Traits\Auditable;

class Persona extends Model
{
    use Auditable;
    protected $table = 'persone';

    protected $fillable = [
        'nome',
        'cognome',
        'nato_a',
        'nato_il',
        'deceduto_a',
        'deceduto_il',
        'last_synced_at',
    ];

    protected $casts = [
        'nato_il' => 'date',
        'deceduto_il' => 'date',
        // last_synced_at non ha cast per evitare problemi con SQLite
        // Viene gestito come stringa nel formato 'Y-m-d H:i:s'
    ];

    /**
     * Relazioni dove questa persona è la persona principale
     */
    public function personaLegami(): HasMany
    {
        return $this->hasMany(PersonaLegame::class, 'persona_id');
    }

    /**
     * Relazioni dove questa persona è la persona collegata
     */
    public function personaLegamiCollegati(): HasMany
    {
        return $this->hasMany(PersonaLegame::class, 'persona_collegata_id');
    }

    /**
     * Ottiene il padre (dove questa persona è figlio e tipo_legame = padre)
     */
    public function padreRel()
    {
        static $tipoPadreCache = null;
        if ($tipoPadreCache === null) {
            $tipoPadreCache = TipoLegame::where('nome', 'padre')->first()?->id;
        }

        if (!$tipoPadreCache) {
            return null;
        }

        $legame = PersonaLegame::where('persona_collegata_id', $this->id)
            ->where('tipo_legame_id', $tipoPadreCache)
            ->first();

        return $legame ? $legame->persona : null;
    }

    /**
     * Ottiene la madre (dove questa persona è figlio e tipo_legame = madre)
     */
    public function madreRel()
    {
        static $tipoMadreCache = null;
        if ($tipoMadreCache === null) {
            $tipoMadreCache = TipoLegame::where('nome', 'madre')->first()?->id;
        }

        if (!$tipoMadreCache) {
            return null;
        }

        $legame = PersonaLegame::where('persona_collegata_id', $this->id)
            ->where('tipo_legame_id', $tipoMadreCache)
            ->first();

        return $legame ? $legame->persona : null;
    }

    /**
     * Ottiene i consorti (dove questa persona è coniuge)
     */
    public function consorti(): Collection
    {
        $legami = $this->personaLegami()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'coniuge');
            })
            ->get();

        $consorti = [];
        foreach ($legami as $legame) {
            if ($legame->personaCollegata) {
                $consorti[] = $legame->personaCollegata;
            }
        }

        // Cerca anche dove questa persona è collegata come coniuge
        $legamiInversi = $this->personaLegamiCollegati()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'coniuge');
            })
            ->get();

        foreach ($legamiInversi as $legame) {
            if ($legame->persona) {
                $consorti[] = $legame->persona;
            }
        }

        // Rimuovi duplicati e restituisci come Eloquent Collection
        $uniqueConsorti = collect($consorti)->unique('id')->values()->all();
        return Persona::newCollection($uniqueConsorti);
    }

    /**
     * Ottiene i consorti con i dettagli del legame (data, luogo, tipo evento)
     */
    public function consortiConDettagli(): array
    {
        $legami = $this->personaLegami()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'coniuge');
            })
            ->with(['personaCollegata', 'tipoEventoLegame'])
            ->get();

        $consortiConDettagli = [];
        foreach ($legami as $legame) {
            if ($legame->personaCollegata) {
                $consortiConDettagli[] = [
                    'persona' => $legame->personaCollegata,
                    'data_legame' => $legame->data_legame?->format('Y-m-d'),
                    'luogo_legame' => $legame->luogo_legame,
                    'tipo_evento_legame' => $legame->tipoEventoLegame,
                    'data_separazione' => $legame->data_separazione?->format('Y-m-d'),
                    'luogo_separazione' => $legame->luogo_separazione,
                ];
            }
        }

        // Cerca anche dove questa persona è collegata come coniuge
        $legamiInversi = $this->personaLegamiCollegati()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'coniuge');
            })
            ->with(['persona', 'tipoEventoLegame'])
            ->get();

        foreach ($legamiInversi as $legame) {
            if ($legame->persona) {
                // Evita duplicati
                $exists = false;
                foreach ($consortiConDettagli as $consorte) {
                    if ($consorte['persona']->id === $legame->persona->id) {
                        $exists = true;
                        break;
                    }
                }
                if (!$exists) {
                    $consortiConDettagli[] = [
                        'persona' => $legame->persona,
                        'data_legame' => $legame->data_legame?->format('Y-m-d'),
                        'luogo_legame' => $legame->luogo_legame,
                        'tipo_evento_legame' => $legame->tipoEventoLegame,
                        'data_separazione' => $legame->data_separazione?->format('Y-m-d'),
                        'luogo_separazione' => $legame->luogo_separazione,
                    ];
                }
            }
        }

        return $consortiConDettagli;
    }

    /**
     * Ottiene i figli (dove questa persona è padre o madre, oppure tipo_legame = figlio)
     */
    public function figli(): Collection
    {
        // Cerca legami dove questa persona è padre o madre
        $legamiGenitore = $this->personaLegami()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'padre')->orWhere('nome', 'madre');
            })
            ->get();

        // Cerca anche legami di tipo "figlio"
        $legamiFiglio = $this->personaLegami()
            ->whereHas('tipoLegame', function ($query) {
                $query->where('nome', 'figlio');
            })
            ->get();

        $figli = [];
        
        // Aggiungi figli dai legami padre/madre
        foreach ($legamiGenitore as $legame) {
            if ($legame->personaCollegata) {
                $figli[] = $legame->personaCollegata;
            }
        }
        
        // Aggiungi figli dai legami tipo "figlio"
        foreach ($legamiFiglio as $legame) {
            if ($legame->personaCollegata) {
                $figli[] = $legame->personaCollegata;
            }
        }

        // Rimuovi duplicati e restituisci come Eloquent Collection
        $uniqueFigli = collect($figli)->unique('id')->values()->all();
        return Persona::newCollection($uniqueFigli);
    }

    /**
     * Versione ottimizzata di figli() che usa join invece di whereHas
     * Molto più veloce per grandi dataset
     */
    public function figliOttimizzati(): Collection
    {
        try {
            // Ottieni gli ID dei tipi di legame una volta sola
            static $tipiLegameCache = null;
            if ($tipiLegameCache === null) {
                $tipiLegameCache = TipoLegame::whereIn('nome', ['padre', 'madre', 'figlio'])
                    ->pluck('id', 'nome')
                    ->toArray();
            }

            $tipiId = array_values($tipiLegameCache);

            if (empty($tipiId)) {
                return new Collection([]);
            }

            // Query ottimizzata con join invece di whereHas
            $figliIds = PersonaLegame::where('persona_id', $this->id)
                ->whereIn('tipo_legame_id', $tipiId)
                ->pluck('persona_collegata_id')
                ->unique()
                ->filter()
                ->values()
                ->toArray();

            if (empty($figliIds)) {
                return Persona::newCollection([]);
            }

            // Carica tutti i figli in una singola query
            return Persona::whereIn('id', $figliIds)->get();
        } catch (\Exception $e) {
            // In caso di errore, restituisci collection vuota
            Log::error('Errore in figliOttimizzati per persona ' . $this->id . ': ' . $e->getMessage());
            return Persona::newCollection([]);
        }
    }

    /**
     * Ottiene i genitori (padre e madre)
     */
    public function genitori(): Collection
    {
        $genitori = [];

        $padre = $this->padreRel();
        if ($padre) {
            $genitori[] = $padre;
        }

        $madre = $this->madreRel();
        if ($madre) {
            $genitori[] = $madre;
        }

        // Restituisci come Eloquent Collection
        return Persona::newCollection($genitori);
    }

    /**
     * Scope per escludere record con id zero o null
     */
    public function scopeValide($query)
    {
        return $query->where('id', '>', 0);
    }

    /**
     * Accessor per nome completo
     */
    public function getNomeCompletoAttribute(): string
    {
        $parts = array_filter([$this->nome, $this->cognome]);
        return implode(' ', $parts) ?: '';
    }

    /**
     * Relazione con i media (foto e documenti)
     */
    public function media(): HasMany
    {
        return $this->hasMany(Media::class);
    }

    /**
     * Relazione con gli eventi
     */
    public function eventi(): HasMany
    {
        return $this->hasMany(Evento::class);
    }

    /**
     * Relazione con le note
     */
    public function note(): HasMany
    {
        return $this->hasMany(Nota::class);
    }

    /**
     * Relazione con i tag
     */
    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class, 'persona_tags');
    }
}

