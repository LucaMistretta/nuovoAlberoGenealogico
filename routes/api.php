<?php

use App\Http\Controllers\API\PersonaController;
use App\Http\Controllers\API\TipoLegameController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Route pubbliche
Route::post('/auth/login', [AuthController::class, 'login']);
Route::get('/translations/{locale}', [\App\Http\Controllers\API\TranslationController::class, 'index']);

// Route protette
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'user']);

    // Route persone
    Route::get('/persone', [PersonaController::class, 'index']);
    Route::get('/persone/tree', [PersonaController::class, 'getAllForTree']);
    Route::get('/persone/{id}/tree', [PersonaController::class, 'getTreeFromPerson']);
    Route::get('/persone/{id}', [PersonaController::class, 'show']);
    Route::post('/persone', [PersonaController::class, 'store']);
    Route::put('/persone/{id}', [PersonaController::class, 'update']);
    Route::delete('/persone/{id}', [PersonaController::class, 'destroy']);
    Route::get('/persone/{id}/family', [PersonaController::class, 'getFamily']);

    // Route tipi_legame
    Route::get('/tipi-legame', [TipoLegameController::class, 'index']);
    Route::get('/tipi-legame/{id}', [TipoLegameController::class, 'show']);
    Route::post('/tipi-legame', [TipoLegameController::class, 'store']);
    Route::put('/tipi-legame/{id}', [TipoLegameController::class, 'update']);
    Route::delete('/tipi-legame/{id}', [TipoLegameController::class, 'destroy']);
});

