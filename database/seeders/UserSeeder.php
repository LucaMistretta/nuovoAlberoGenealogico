<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Crea un utente superadmin di default se non esiste
        $admin = User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Administrator',
                'password' => Hash::make('password'),
                'role' => 'superadmin',
            ]
        );
        
        // Aggiorna il ruolo se l'utente esisteva già
        if ($admin->wasRecentlyCreated === false) {
            $admin->update(['role' => 'superadmin']);
        }

        // Crea un utente normale di default se non esiste
        User::firstOrCreate(
            ['email' => 'user@example.com'],
            [
                'name' => 'User',
                'password' => Hash::make('password'),
                'role' => 'user',
            ]
        );
    }
}

