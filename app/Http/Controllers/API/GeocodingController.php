<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\GeocodingCache;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeocodingController extends Controller
{
    /**
     * Geocodifica un luogo usando il cache o Nominatim
     */
    public function geocode(Request $request): JsonResponse
    {
        $request->validate([
            'luogo' => 'required|string|max:255',
        ]);
        
        $luogo = trim($request->input('luogo'));
        
        if (empty($luogo)) {
            return response()->json([
                'success' => false,
                'message' => 'Luogo non valido',
            ], 400);
        }
        
        // Cerca nel cache
        $cached = GeocodingCache::where('luogo', $luogo)->first();
        if ($cached) {
            return response()->json([
                'success' => true,
                'cached' => true,
                'data' => [
                    'lat' => (float) $cached->lat,
                    'lng' => (float) $cached->lng,
                    'display_name' => $cached->display_name,
                ],
            ]);
        }
        
        // Geocodifica con Nominatim
        try {
            $response = Http::withHeaders([
                'User-Agent' => 'NuovoAlberoGenealogico/1.0',
                'Accept-Language' => 'it,en',
            ])->timeout(10)->get('https://nominatim.openstreetmap.org/search', [
                'q' => $luogo,
                'format' => 'json',
                'limit' => 1,
                'addressdetails' => 1,
            ]);
            
            if (!$response->successful()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Errore nella richiesta a Nominatim',
                ], 500);
            }
            
            $data = $response->json();
            
            if (empty($data) || !isset($data[0])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nessun risultato trovato',
                ], 404);
            }
            
            $result = $data[0];
            $lat = (float) $result['lat'];
            $lng = (float) $result['lon'];
            $displayName = $result['display_name'] ?? $luogo;
            
            // Salva nel cache
            GeocodingCache::create([
                'luogo' => $luogo,
                'lat' => $lat,
                'lng' => $lng,
                'display_name' => $displayName,
            ]);
            
            return response()->json([
                'success' => true,
                'cached' => false,
                'data' => [
                    'lat' => $lat,
                    'lng' => $lng,
                    'display_name' => $displayName,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Errore nella geocodifica', [
                'luogo' => $luogo,
                'error' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Errore nella geocodifica: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Geocodifica multipli luoghi in batch
     */
    public function geocodeBatch(Request $request): JsonResponse
    {
        $request->validate([
            'luoghi' => 'required|array',
            'luoghi.*' => 'string|max:255',
        ]);
        
        $luoghi = $request->input('luoghi');
        $results = [];
        
        foreach ($luoghi as $luogo) {
            $luogo = trim($luogo);
            if (empty($luogo)) {
                continue;
            }
            
            // Cerca nel cache
            $cached = GeocodingCache::where('luogo', $luogo)->first();
            if ($cached) {
                $results[$luogo] = [
                    'success' => true,
                    'cached' => true,
                    'lat' => (float) $cached->lat,
                    'lng' => (float) $cached->lng,
                    'display_name' => $cached->display_name,
                ];
            } else {
                // Per ora restituiamo null, la geocodifica verrà fatta lato client
                // per rispettare il rate limit di Nominatim
                $results[$luogo] = [
                    'success' => false,
                    'cached' => false,
                    'message' => 'Non in cache, richiede geocodifica',
                ];
            }
        }
        
        return response()->json([
            'success' => true,
            'data' => $results,
        ]);
    }
}
