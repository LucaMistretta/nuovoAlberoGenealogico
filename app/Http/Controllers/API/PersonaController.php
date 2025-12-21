<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePersonaRequest;
use App\Http\Requests\UpdatePersonaRequest;
use App\Http\Resources\PersonaResource;
use App\Models\Persona;
use App\Models\PersonaLegame;
use App\Models\TipoLegame;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PersonaController extends Controller
{
    /**
     * Lista tutte le persone
     */
    public function index(): AnonymousResourceCollection|JsonResponse
    {
        $query = Persona::valide();
        
        // Se c'è un parametro di ricerca, filtra i risultati
        if (request()->has('search') && request()->get('search')) {
            $searchTerm = trim(request()->get('search'));
            if (!empty($searchTerm)) {
                $query->where(function ($q) use ($searchTerm) {
                    $q->whereRaw('LOWER(nome) LIKE ?', ['%' . strtolower($searchTerm) . '%'])
                      ->orWhereRaw('LOWER(cognome) LIKE ?', ['%' . strtolower($searchTerm) . '%'])
                      ->orWhere('id', 'LIKE', "%{$searchTerm}%");
                });
            }
        }
        
        // Gestione ordinamento
        $sortBy = request()->get('sort_by', 'id'); // Default: id
        $sortDir = request()->get('sort_dir', 'asc'); // Default: asc
        
        // Validazione colonna di ordinamento
        $allowedSortColumns = ['id', 'nome', 'cognome', 'nato_il', 'nato_a'];
        if (!in_array($sortBy, $allowedSortColumns)) {
            $sortBy = 'id';
        }
        
        // Validazione direzione ordinamento
        if (!in_array(strtolower($sortDir), ['asc', 'desc'])) {
            $sortDir = 'asc';
        }
        
        // Applica ordinamento
        $query->orderBy($sortBy, $sortDir);
        
        // Se c'è il parametro all=true, restituisce tutte le persone senza paginazione
        if (request()->has('all') && request()->get('all') === 'true') {
            // Non caricare relazioni per la lista completa (troppo pesante)
            $persone = $query->get();
            return PersonaResource::collection($persone);
        }
        
        // Lista paginata
        $persone = $query->paginate(15);

        return PersonaResource::collection($persone);
    }

    /**
     * Ricerca avanzata con filtri multipli
     */
    public function advancedSearch(Request $request): JsonResponse
    {
        $query = Persona::query();

        // Filtro per nome
        if ($request->has('nome') && $request->nome) {
            $query->where('nome', 'like', '%' . $request->nome . '%');
        }

        // Filtro per cognome
        if ($request->has('cognome') && $request->cognome) {
            $query->where('cognome', 'like', '%' . $request->cognome . '%');
        }

        // Filtro per data di nascita (da)
        if ($request->has('nato_il_da') && $request->nato_il_da) {
            $query->where('nato_il', '>=', $request->nato_il_da);
        }

        // Filtro per data di nascita (a)
        if ($request->has('nato_il_a') && $request->nato_il_a) {
            $query->where('nato_il', '<=', $request->nato_il_a);
        }

        // Filtro per luogo di nascita
        if ($request->has('nato_a') && $request->nato_a) {
            $query->where('nato_a', 'like', '%' . $request->nato_a . '%');
        }

        // Filtro per data di morte (da)
        if ($request->has('deceduto_il_da') && $request->deceduto_il_da) {
            $query->where('deceduto_il', '>=', $request->deceduto_il_da);
        }

        // Filtro per data di morte (a)
        if ($request->has('deceduto_il_a') && $request->deceduto_il_a) {
            $query->where('deceduto_il', '<=', $request->deceduto_il_a);
        }

        // Filtro per luogo di morte
        if ($request->has('deceduto_a') && $request->deceduto_a) {
            $query->where('deceduto_a', 'like', '%' . $request->deceduto_a . '%');
        }

        // Filtro per vivente/deceduto
        if ($request->has('stato_vita')) {
            if ($request->stato_vita === 'vivente') {
                $query->whereNull('deceduto_il');
            } elseif ($request->stato_vita === 'deceduto') {
                $query->whereNotNull('deceduto_il');
            }
        }

        // Ordinamento
        $sortBy = $request->get('sort_by', 'cognome');
        $sortDir = $request->get('sort_dir', 'asc');
        $allowedSortColumns = ['id', 'nome', 'cognome', 'nato_il', 'nato_a'];
        if (in_array($sortBy, $allowedSortColumns)) {
            $query->orderBy($sortBy, $sortDir);
        } else {
            $query->orderBy('cognome')->orderBy('nome');
        }

        $persone = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => PersonaResource::collection($persone),
            'meta' => [
                'current_page' => $persone->currentPage(),
                'last_page' => $persone->lastPage(),
                'per_page' => $persone->perPage(),
                'total' => $persone->total(),
            ],
        ]);
    }

    /**
     * Mostra dettagli persona con relazioni
     */
    public function show(int $id): PersonaResource|JsonResponse
    {
        $persona = Persona::with('tags')->find($id);

        if (!$persona) {
            return response()->json(['message' => 'Persona non trovata'], 404);
        }

        return PersonaResource::withRelations($persona);
    }

    /**
     * Crea nuova persona
     */
    public function store(StorePersonaRequest $request): PersonaResource
    {
        $data = $request->validated();
        
        DB::beginTransaction();
        try {
            // Rimuovi relazioni e genitori dai dati prima di creare la persona
            $relazioni = $data['relazioni'] ?? [];
            $genitori = $data['genitori'] ?? [];
            unset($data['relazioni'], $data['genitori']);
            
            $persona = Persona::create($data);
            
            // Gestisci genitori (relazioni inverse)
            if (!empty($genitori)) {
                $this->syncGenitori($persona, $genitori);
            }
            
            // Gestisci relazioni se presenti (consorti, figli)
            if (!empty($relazioni)) {
                $this->syncRelazioni($persona, $relazioni);
            }
            
            DB::commit();
            return PersonaResource::withRelations($persona->fresh());
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Errore nella creazione: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Modifica persona
     */
    public function update(UpdatePersonaRequest $request, int $id): PersonaResource|JsonResponse
    {
        $persona = Persona::find($id);

        if (!$persona) {
            return response()->json(['message' => 'Persona non trovata'], 404);
        }

        $data = $request->validated();
        
        DB::beginTransaction();
        try {
            // Rimuovi relazioni e genitori dai dati prima di aggiornare
            $relazioni = $data['relazioni'] ?? null;
            $genitori = $data['genitori'] ?? null;
            unset($data['relazioni'], $data['genitori']);
            
            $persona->update($data);
            
            // Gestisci genitori se presenti
            if ($genitori !== null) {
                $this->syncGenitori($persona, $genitori);
            }
            
            // Gestisci relazioni se presenti
            if ($relazioni !== null) {
                $this->syncRelazioni($persona, $relazioni);
            }
            
            DB::commit();
            return PersonaResource::withRelations($persona->fresh());
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Errore nell\'aggiornamento: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Elimina persona
     */
    public function destroy(int $id): JsonResponse
    {
        $persona = Persona::find($id);

        if (!$persona) {
            return response()->json(['message' => 'Persona non trovata'], 404);
        }

        $persona->delete();

        return response()->json(['message' => 'Persona eliminata con successo']);
    }

    /**
     * Ottiene famiglia completa (genitori, consorte, figli)
     */
    public function getFamily(int $id): JsonResponse
    {
        $persona = Persona::find($id);

        if (!$persona) {
            return response()->json(['message' => 'Persona non trovata'], 404);
        }

        return response()->json([
            'persona' => PersonaResource::withRelations($persona),
            'padre' => $persona->padreRel() ? PersonaResource::withRelations($persona->padreRel()) : null,
            'madre' => $persona->madreRel() ? PersonaResource::withRelations($persona->madreRel()) : null,
            'consorti' => PersonaResource::collection($persona->consorti()),
            'figli' => PersonaResource::collection($persona->figli()),
        ]);
    }

    /**
     * Ottiene tutte le persone con relazioni per l'albero genealogico completo
     */
    public function getAllForTree(): JsonResponse
    {
        // Carica tutte le persone senza relazioni (più veloce)
        // Ordina per cognome e poi nome
        $persone = Persona::valide()
            ->orderBy('cognome')
            ->orderBy('nome')
            ->get();

        // Trova la persona radice usando una query ottimizzata
        $radiceId = DB::table('persona_legami as pl')
            ->join('tipi_di_legame as tl', 'pl.tipo_legame_id', '=', 'tl.id')
            ->whereIn('tl.nome', ['padre', 'madre'])
            ->select('pl.persona_collegata_id')
            ->groupBy('pl.persona_collegata_id')
            ->get()
            ->pluck('persona_collegata_id')
            ->toArray();

        $radice = $persone->first(function ($persona) use ($radiceId) {
            return !in_array($persona->id, $radiceId);
        });

        return response()->json([
            'persone' => PersonaResource::collection($persone),
            'radice' => $radice ? PersonaResource::withRelations($radice) : null,
        ]);
    }

    /**
     * Ottiene l'albero genealogico partendo da una persona specifica
     */
    public function getTreeFromPerson(int $id): JsonResponse
    {
        try {
            $persona = Persona::find($id);

            if (!$persona) {
                return response()->json(['message' => 'Persona non trovata'], 404);
            }

            // Costruisce l'albero ricorsivamente partendo dalla persona
            // Passa un array di cache per evitare query duplicate
            $cache = [];
            $albero = $this->costruisciAlbero($persona, 0, $cache);

            return response()->json($albero);
        } catch (\Exception $e) {
            \Log::error('Errore in getTreeFromPerson per persona ' . $id . ': ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'message' => 'Errore nel caricamento dell\'albero genealogico',
                'error' => config('app.debug') ? $e->getMessage() : 'Errore interno del server'
            ], 500);
        }
    }

    /**
     * Costruisce l'albero genealogico ricorsivamente
     * Ottimizzato con caching per evitare query duplicate
     */
    private function costruisciAlbero(Persona $persona, int $livello, array &$cache = []): array
    {
        // Usa cache per evitare di ricaricare la stessa persona
        $cacheKey = $persona->id;
        if (isset($cache[$cacheKey])) {
            $persona = $cache[$cacheKey];
        } else {
            $cache[$cacheKey] = $persona;
        }

        $nodo = [
            'id' => $persona->id,
            'nome' => $persona->nome,
            'cognome' => $persona->cognome,
            'nome_completo' => $persona->nome_completo,
            'nato_il' => $persona->nato_il ? ($persona->nato_il instanceof \DateTime ? $persona->nato_il->format('Y-m-d') : (string)$persona->nato_il) : null,
            'nato_a' => $persona->nato_a,
            'deceduto_il' => $persona->deceduto_il ? ($persona->deceduto_il instanceof \DateTime ? $persona->deceduto_il->format('Y-m-d') : (string)$persona->deceduto_il) : null,
            'deceduto_a' => $persona->deceduto_a,
            'livello' => $livello,
            'figli' => [],
        ];

        try {
            // Ottieni i figli della persona usando metodo ottimizzato
            $figli = $persona->figliOttimizzati();

            foreach ($figli as $figlio) {
                // Evita ricorsione infinita controllando se il figlio è già nella cache
                if (!isset($cache[$figlio->id])) {
                    $nodo['figli'][] = $this->costruisciAlbero($figlio, $livello + 1, $cache);
                }
            }
        } catch (\Exception $e) {
            // In caso di errore, logga e continua senza figli
            \Log::error('Errore nel caricamento figli per persona ' . $persona->id . ': ' . $e->getMessage());
        }

        return $nodo;
    }

    /**
     * Sincronizza i genitori di una persona (relazioni inverse)
     */
    private function syncGenitori(Persona $persona, array $genitori): void
    {
        // Rimuovi le relazioni esistenti dove questa persona è figlio
        $tipoPadre = TipoLegame::where('nome', 'padre')->first();
        $tipoMadre = TipoLegame::where('nome', 'madre')->first();
        
        if ($tipoPadre) {
            PersonaLegame::where('persona_collegata_id', $persona->id)
                ->where('tipo_legame_id', $tipoPadre->id)
                ->delete();
        }
        
        if ($tipoMadre) {
            PersonaLegame::where('persona_collegata_id', $persona->id)
                ->where('tipo_legame_id', $tipoMadre->id)
                ->delete();
        }
        
        // Crea relazione con il padre se specificato
        if (!empty($genitori['padre_id']) && $tipoPadre) {
            $padreId = (int)$genitori['padre_id'];
            if ($padreId !== $persona->id) {
                PersonaLegame::firstOrCreate([
                    'persona_id' => $padreId,
                    'persona_collegata_id' => $persona->id,
                    'tipo_legame_id' => $tipoPadre->id,
                ]);
            }
        }
        
        // Crea relazione con la madre se specificata
        if (!empty($genitori['madre_id']) && $tipoMadre) {
            $madreId = (int)$genitori['madre_id'];
            if ($madreId !== $persona->id) {
                PersonaLegame::firstOrCreate([
                    'persona_id' => $madreId,
                    'persona_collegata_id' => $persona->id,
                    'tipo_legame_id' => $tipoMadre->id,
                ]);
            }
        }
    }

    /**
     * Sincronizza le relazioni di una persona
     */
    private function syncRelazioni(Persona $persona, array $relazioni): void
    {
        // Rimuovi tutte le relazioni esistenti dove questa persona è la persona principale
        $persona->personaLegami()->delete();
        
        // Rimuovi anche le relazioni inverse per i consorti (dove questa persona è collegata come coniuge)
        $tipoConiuge = TipoLegame::where('nome', 'coniuge')->first();
        if ($tipoConiuge) {
            PersonaLegame::where('persona_collegata_id', $persona->id)
                ->where('tipo_legame_id', $tipoConiuge->id)
                ->delete();
        }
        
        foreach ($relazioni as $relazione) {
            if (!isset($relazione['persona_collegata_id']) || !isset($relazione['tipo_legame_id'])) {
                continue;
            }
            
            // Verifica che il tipo_legame esista
            $tipoLegame = TipoLegame::find($relazione['tipo_legame_id']);
            if (!$tipoLegame) {
                continue;
            }
            
            // Verifica che la persona collegata esista
            $personaCollegata = Persona::find($relazione['persona_collegata_id']);
            if (!$personaCollegata) {
                continue;
            }
            
            // Evita auto-riferimenti
            if ($persona->id === $relazione['persona_collegata_id']) {
                continue;
            }
            
            // Crea il legame diretto
            PersonaLegame::create([
                'persona_id' => $persona->id,
                'persona_collegata_id' => $relazione['persona_collegata_id'],
                'tipo_legame_id' => $relazione['tipo_legame_id'],
            ]);
            
            // Per i consorti, crea anche la relazione inversa
            if ($tipoLegame->nome === 'coniuge') {
                // Verifica che non esista già la relazione inversa
                $exists = PersonaLegame::where('persona_id', $relazione['persona_collegata_id'])
                    ->where('persona_collegata_id', $persona->id)
                    ->where('tipo_legame_id', $relazione['tipo_legame_id'])
                    ->exists();
                
                if (!$exists) {
                    PersonaLegame::create([
                        'persona_id' => $relazione['persona_collegata_id'],
                        'persona_collegata_id' => $persona->id,
                        'tipo_legame_id' => $relazione['tipo_legame_id'],
                    ]);
                }
            }
        }
    }
}

