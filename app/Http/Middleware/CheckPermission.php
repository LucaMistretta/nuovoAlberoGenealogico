<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermission
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Non autenticato'], 401);
        }

        // Admin ha tutti i permessi
        if ($user->role === 'admin') {
            return $next($request);
        }

        // Controlla permessi specifici (esempio semplificato)
        $permissions = [
            'view_persone' => ['user', 'admin'],
            'edit_persone' => ['admin'],
            'delete_persone' => ['admin'],
            'manage_users' => ['admin'],
        ];

        if (!isset($permissions[$permission]) || !in_array($user->role, $permissions[$permission])) {
            return response()->json(['message' => 'Non autorizzato'], 403);
        }

        return $next($request);
    }
}

