<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PersonaResource extends JsonResource
{
    /**
     * Indica se caricare le relazioni complete (evita ricorsione infinita)
     */
    protected bool $withRelations = false;

    /**
     * Crea una nuova istanza della risorsa con relazioni
     */
    public static function withRelations($resource): static
    {
        $instance = static::make($resource);
        $instance->withRelations = true;
        return $instance;
    }

    public function toArray(Request $request): array
    {
        $data = [
            'id' => $this->id,
            'nome' => $this->nome,
            'cognome' => $this->cognome,
            'nome_completo' => $this->nome_completo,
            'nato_a' => $this->nato_a,
            'nato_il' => $this->nato_il?->format('Y-m-d'),
            'deceduto_a' => $this->deceduto_a,
            'deceduto_il' => $this->deceduto_il?->format('Y-m-d'),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];

        // Carica le relazioni solo se esplicitamente richiesto
        if ($this->withRelations) {
            $data['padre'] = $this->when(
                $this->padreRel(),
                fn() => new PersonaResource($this->padreRel())
            );
            $data['madre'] = $this->when(
                $this->madreRel(),
                fn() => new PersonaResource($this->madreRel())
            );
            $consorti = $this->consorti();
            $data['consorti'] = $this->when(
                $consorti->isNotEmpty(),
                fn() => PersonaResource::collection($consorti)
            );
            $figli = $this->figli();
            $data['figli'] = $this->when(
                $figli->isNotEmpty(),
                fn() => PersonaResource::collection($figli)
            );
            $genitori = $this->genitori();
            $data['genitori'] = $this->when(
                $genitori->isNotEmpty(),
                fn() => PersonaResource::collection($genitori)
            );
            $tags = $this->tags;
            $data['tags'] = $this->when(
                $tags->isNotEmpty(),
                fn() => $tags
            );
        } else {
            // Solo ID delle relazioni per evitare ricorsione e query pesanti
            // Usa eager loading se disponibile, altrimenti evita query costose
            try {
                $padre = $this->padreRel();
                $data['padre_id'] = $padre ? $padre->id : null;
            } catch (\Exception $e) {
                $data['padre_id'] = null;
            }
            
            try {
                $madre = $this->madreRel();
                $data['madre_id'] = $madre ? $madre->id : null;
            } catch (\Exception $e) {
                $data['madre_id'] = null;
            }
            
            // Non includere consorti nella lista per performance
            // Verranno caricati solo nella visualizzazione dettaglio
        }

        return $data;
    }
}

