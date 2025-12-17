<?php

declare(strict_types=1);

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Lang;

class TranslationController extends Controller
{
    public function index(string $locale): JsonResponse
    {
        // Valida la locale
        $allowedLocales = ['it', 'en', 'fr', 'de', 'es', 'pt'];
        if (!in_array($locale, $allowedLocales)) {
            $locale = 'it';
        }

        // Imposta la locale temporaneamente
        $previousLocale = app()->getLocale();
        app()->setLocale($locale);

        // Carica le traduzioni dal file messages.php
        $translations = Lang::get('messages');

        // Ripristina la locale precedente
        app()->setLocale($previousLocale);

        return response()->json($translations);
    }
}

