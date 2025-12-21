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

        // Superadmin e Admin hanno tutti i permessi
        if ($user->role === 'superadmin' || $user->role === 'admin') {
            return $next($request);
        }

        // Controlla permessi specifici (esempio semplificato)
        $permissions = [
            'view_persone' => ['user', 'admin', 'superadmin'],
            'edit_persone' => ['admin', 'superadmin'],
            'delete_persone' => ['admin', 'superadmin'],
            'manage_users' => ['admin', 'superadmin'],
        ];

        if (!isset($permissions[$permission]) || !in_array($user->role, $permissions[$permission])) {
            return response()->json(['message' => 'Non autorizzato'], 403);
        }

        return $next($request);
    }
}

