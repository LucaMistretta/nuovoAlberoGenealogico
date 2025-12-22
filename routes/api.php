<?php

use App\Http\Controllers\API\PersonaController;
use App\Http\Controllers\API\TipoLegameController;
use App\Http\Controllers\API\MediaController;
use App\Http\Controllers\API\EventoController;
use App\Http\Controllers\API\NotaController;
use App\Http\Controllers\API\TagController;
use App\Http\Controllers\API\ExportController;
use App\Http\Controllers\API\ImportController;
use App\Http\Controllers\API\ReportController;
use App\Http\Controllers\API\DataQualityController;
use App\Http\Controllers\API\UserController;
use App\Http\Controllers\API\AuditLogController;
use App\Http\Controllers\API\GeocodingController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Route pubbliche
Route::post('/auth/login', [AuthController::class, 'login']);
Route::get('/translations/{locale}', [\App\Http\Controllers\API\TranslationController::class, 'index']);

// Route pubbliche per lettura (GET) di media, eventi e note
Route::get('/persone/{personaId}/media', [MediaController::class, 'index']);
Route::get('/persone/{personaId}/eventi', [EventoController::class, 'index']);
Route::get('/persone/{personaId}/note', [NotaController::class, 'index']);

// Route protette
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'user']);

    // Route persone
    Route::get('/persone', [PersonaController::class, 'index']);
    Route::get('/persone/search', [PersonaController::class, 'advancedSearch']);
    Route::get('/persone/tree', [PersonaController::class, 'getAllForTree']);
    Route::get('/persone/{id}/tree', [PersonaController::class, 'getTreeFromPerson']);
    Route::get('/persone/{id}', [PersonaController::class, 'show']);
    Route::post('/persone', [PersonaController::class, 'store']);
    Route::put('/persone/{id}', [PersonaController::class, 'update']);
    Route::delete('/persone/{id}', [PersonaController::class, 'destroy']);
    Route::get('/persone/{id}/family', [PersonaController::class, 'getFamily']);

    // Route media (scrittura protetta)
    Route::post('/persone/{personaId}/media', [MediaController::class, 'store']);
    Route::delete('/persone/{personaId}/media/{mediaId}', [MediaController::class, 'destroy']);

    // Route eventi (scrittura protetta)
    Route::post('/persone/{personaId}/eventi', [EventoController::class, 'store']);
    Route::put('/persone/{personaId}/eventi/{eventoId}', [EventoController::class, 'update']);
    Route::delete('/persone/{personaId}/eventi/{eventoId}', [EventoController::class, 'destroy']);

    // Route note (scrittura protetta)
    Route::post('/persone/{personaId}/note', [NotaController::class, 'store']);
    Route::put('/persone/{personaId}/note/{notaId}', [NotaController::class, 'update']);
    Route::delete('/persone/{personaId}/note/{notaId}', [NotaController::class, 'destroy']);

    // Route tags
    Route::get('/tags', [TagController::class, 'index']);
    Route::post('/tags', [TagController::class, 'store']);
    Route::put('/tags/{id}', [TagController::class, 'update']);
    Route::delete('/tags/{id}', [TagController::class, 'destroy']);
    Route::post('/persone/{personaId}/tags', [TagController::class, 'attachToPersona']);
    Route::delete('/persone/{personaId}/tags/{tagId}', [TagController::class, 'detachFromPersona']);

    // Route export
    Route::get('/export/gedcom', [ExportController::class, 'exportGedcom']);
    Route::get('/export/gedcom/{personaId}', [ExportController::class, 'exportGedcomFromPersona']);
    Route::get('/export/csv', [ExportController::class, 'exportCsv']);

    // Route import
    Route::post('/import/gedcom', [ImportController::class, 'importGedcom']);

    // Route report
    Route::get('/report/statistiche', [ReportController::class, 'statisticheGenerali']);
    Route::get('/report/distribuzione-eta', [ReportController::class, 'distribuzioneEta']);
    Route::get('/report/luoghi-nascita', [ReportController::class, 'luoghiNascita']);
    
    // Route geocoding
    Route::post('/geocoding/geocode', [GeocodingController::class, 'geocode']);
    Route::post('/geocoding/batch', [GeocodingController::class, 'geocodeBatch']);

    // Route data quality
    Route::get('/data-quality/check', [DataQualityController::class, 'check']);

    // Route utenti (solo admin)
    Route::middleware(['auth:sanctum', \App\Http\Middleware\CheckPermission::class . ':manage_users'])->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::post('/users', [UserController::class, 'store']);
        Route::put('/users/{id}', [UserController::class, 'update']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);
    });

    // Route audit log (solo admin)
    Route::middleware(['auth:sanctum', \App\Http\Middleware\CheckPermission::class . ':manage_users'])->group(function () {
        Route::get('/audit-logs', [AuditLogController::class, 'index']);
        Route::get('/audit-logs/{id}', [AuditLogController::class, 'show']);
    });

    // Route tipi_legame
    Route::get('/tipi-legame', [TipoLegameController::class, 'index']);
    Route::get('/tipi-legame/{id}', [TipoLegameController::class, 'show']);
    Route::post('/tipi-legame', [TipoLegameController::class, 'store']);
    Route::put('/tipi-legame/{id}', [TipoLegameController::class, 'update']);
    Route::delete('/tipi-legame/{id}', [TipoLegameController::class, 'destroy']);
});

