<?php

use Illuminate\Support\Facades\Route;

// Route per il login (necessaria per il middleware Authenticate)
Route::get('/login', function () {
    return view('app');
})->name('login');

// Route catch-all per la SPA Vue.js
Route::get('/{any}', function () {
    return view('app');
})->where('any', '.*');

