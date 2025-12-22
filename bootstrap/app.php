<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

// Aumenta i limiti di upload PHP
ini_set('upload_max_filesize', '20M');
ini_set('post_max_size', '25M');
ini_set('memory_limit', '256M');
ini_set('max_execution_time', '300');

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(prepend: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ]);
        
        $middleware->alias([
            'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Gestisci errori di autenticazione per le API
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autenticato. Effettua il login per accedere a questa risorsa.',
                ], 401);
            }
            // Per le richieste web, reindirizza a /login
            return redirect()->route('login');
        });

        // Gestisci errori di upload troppo grandi
        $exceptions->render(function (\Illuminate\Http\Exceptions\PostTooLargeException $e, $request) {
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Il file è troppo grande. Dimensione massima consentita: ' . ini_get('post_max_size'),
                    'errors' => [
                        'file' => ['Il file supera la dimensione massima consentita (' . ini_get('post_max_size') . ')']
                    ],
                    'debug' => [
                        'post_max_size' => ini_get('post_max_size'),
                        'upload_max_filesize' => ini_get('upload_max_filesize'),
                        'memory_limit' => ini_get('memory_limit'),
                    ]
                ], 413);
            }
            return redirect()->back()->with('error', 'Il file è troppo grande.');
        });
    })->create();

